#!/usr/bin/env perl

# Daniel "Trizen" Șuteu
# https://github.com/trizen
#
# Smallest strong pseudoprime to base 2 with exactly n distinct prime factors
# (OEIS A180065).
#
# This version keeps the original mathematical search, but uses compact prime
# tables, class-specific lower bounds, congruence-aware cofactor bounds, a small
# conservative residue-CSP filter, and bounded best-first ordering near the
# bottom of the search tree.
#
# Requires Math::Prime::Util >= 0.74 and Math::GMPz.

use v5.36;
use strict;
use warnings;
no warnings 'recursion';

use Getopt::Long qw(GetOptions);
use Time::HiRes  qw(time);

use Math::GMPz        qw(:mpz);
use Math::Prime::Util qw(:all);

sub strong_fermat_psp_base2_smallest ($k, %opt) {

    die "n must be an integer >= 2\n" if !defined($k) || "$k" !~ /\A\d+\z/ || $k < 2;
    $k = 0 + $k;

    my $force_bits     = $opt{force_bits}  // 64;
    my $force_count    = $opt{force_count} // 16;
    my $force_ratio    = $opt{force_ratio} // 0.75;
    my $verbose        = $opt{verbose}     // 0;
    my $use_csp        = $opt{csp}         // 0;
    my $use_best_first = $opt{best_first}  // 0;

    die "force_bits must be a non-negative integer\n"  if $force_bits  !~ /\A\d+\z/;
    die "force_count must be a non-negative integer\n" if $force_count !~ /\A\d+\z/;
    die "force_ratio must be a non-negative number\n"  if $force_ratio !~ /\A\d+(?:\.\d+)?\z/;

    my $force_ok = ($force_bits > 0 && $force_count > 0) ? 1 : 0;

    my $TWO  = Rmpz_init_set_ui(2);
    my $NULL = $Math::GMPz::NULL;

    my $B         = Rmpz_init();
    my $best      = Rmpz_init();
    my $have_best = 0;
    my $gen       = 0;

    # Compact per-class tables. Elements are unsigned 32-bit values while the
    # table fits below 2^32, then upgraded to unsigned 64-bit values. A p/order
    # pair therefore costs 8 or 16 bytes instead of two Perl scalar arrays.
    my (@CP, @CZ, @WIDX, @WIEF);
    my $have          = 2;
    my $record_bytes  = 4;
    my $pack_format   = 'L<';
    my $unpack_format = 'L<';
    my $prime_chunk   = 1_000_000;    # numeric interval width, not prime count

    my ($ce, $cr) = (0, 1);

    my ($visited_nodes, $tail_nodes, $tail_primes, $forced_nodes, $factorizations, $terminal_hits, $csp_prunes, $best_first_nodes) = (0) x 8;

    # GMP scratch values. Search recursion uses depth-indexed state arrays;
    # these scratch objects are only used between recursive calls.
    my ($T, $T2, $T3, $F, $Q, $N1, $N, $R, $C1, $C2) = map { Rmpz_init() } 1 .. 10;
    my ($L2, $M2, $H, $LO, $M2M1, $TT, $NN, $S) = map { Rmpz_init() } 1 .. 8;

    # Scratch for local best-first child lower bounds.
    my ($CHM, $CHL, $CHQ, $CHF, $CHT, $CHB) = map { Rmpz_init() } 1 .. 6;

    my sub record ($n) {
        Rmpz_set($best, $n);
        Rmpz_sub_ui($B, $n, 1);
        $have_best = 1;
        ++$gen;
    }

    my sub upgrade_prime_tables {
        return if $record_bytes == 8;

        for my $t (0 .. $#CP) {
            my $oldp = $CP[$t] // '';
            my $oldz = $CZ[$t] // '';
            my $n    = int(length($oldp) / 4);
            my ($newp, $newz) = ('', '');

            # Convert in bounded batches. This avoids unpacking an entire large
            # class into Perl scalars during a 32 -> 64 bit table upgrade.
            for (my $off = 0 ; $off < $n ; $off += 100_000) {
                my $take = $n - $off;
                $take = 100_000 if $take > 100_000;
                my @p = unpack('L<*', substr($oldp, $off * 4, $take * 4));
                my @z = unpack('L<*', substr($oldz, $off * 4, $take * 4));
                $newp .= pack('Q<*', @p);
                $newz .= pack('Q<*', @z);
            }

            $CP[$t] = $newp;
            $CZ[$t] = $newz;
        }

        $record_bytes  = 8;
        $pack_format   = 'Q<';
        $unpack_format = 'Q<';
    }

    my sub p_at ($t, $i) {
        return unpack($unpack_format, substr($CP[$t], $i * $record_bytes, $record_bytes));
    }

    my sub z_at ($t, $i) {
        return unpack($unpack_format, substr($CZ[$t], $i * $record_bytes, $record_bytes));
    }

    my sub class_count ($t) {
        return defined($CP[$t]) ? int(length($CP[$t]) / $record_bytes) : 0;
    }

    my sub z_is_prime ($z) {

        # Pass a native integer or decimal string to Math::Prime::Util rather
        # than relying on implicit Math::GMPz object conversion.
        my $zs = Rmpz_fits_ulong_p($z) ? Rmpz_get_ui($z) : Rmpz_get_str($z, 10);
        return is_prime($zs);
    }

    # v_2(ord_p(2)) == t for a native odd prime p.
    my sub class_ok_ui ($p) {
        my $tv = valuation($p - 1, 2);
        return 0 if $tv <= $ce;
        my $x = powmod(2, ($p - 1) >> ($tv - $ce), $p);
        return $cr == 1 ? ($x == 1) : ($x == $p - 1);
    }

    # Same test for an mpz prime.
    my sub class_ok_z ($z) {
        Rmpz_sub_ui($C1, $z, 1);
        my $tv = Rmpz_scan1($C1, 0);
        return 0 if $tv <= $ce;
        Rmpz_fdiv_q_2exp($C1, $C1, $tv - $ce);
        Rmpz_powm($C2, $TWO, $C1, $z);
        return (Rmpz_cmp_ui($C2, 1) == 0) if $cr == 1;
        Rmpz_add_ui($C2, $C2, 1);
        return (Rmpz_cmp($C2, $z) == 0);
    }

    # Largest e >= 1 with 2^z == 1 (mod p^e). Called only for primes that can
    # possibly occur squared under the current search bound.
    my sub wieferich_exp ($p, $z) {

        if ($p < 4294967296) {
            return 1 if powmod(2, $z, $p * $p) != 1;
        }

        my $pe = Rmpz_init_set_ui($p);
        my $zz = Rmpz_init_set_ui($z);
        my $r  = Rmpz_init();
        my $e  = 1;

        while (1) {
            Rmpz_mul_ui($pe, $pe, $p);
            Rmpz_powm($r, $TWO, $zz, $pe);
            last if Rmpz_cmp_ui($r, 1) != 0;
            ++$e;
        }

        return $e;
    }

    # Extend the packed prime/order tables. The temporary result of primes()
    # never spans more than $prime_chunk integers.
    my sub extend_primes ($limit) {
        return if $limit <= $have;

        for (my $lo = $have + 1 ; $lo <= $limit ; $lo += $prime_chunk) {
            my $hi = $lo + $prime_chunk - 1;
            $hi = $limit if $hi > $limit;
            upgrade_prime_tables() if $hi > 0xffffffff && $record_bytes == 4;

            my $list = primes($lo, $hi);
            my (%newp, %newz);

            foreach my $p (@$list) {
                my $z = znorder(2, $p);
                my $t = valuation($z, 2);
                $newp{$t} .= pack($pack_format, $p);
                $newz{$t} .= pack($pack_format, $z);
            }

            foreach my $t (keys %newp) {
                $CP[$t] .= $newp{$t};
                $CZ[$t] .= $newz{$t};
            }
        }

        $have = $limit;
    }

    # Test each stored prime for the Wieferich property at most once. This is
    # intentionally separate from extend_primes(): a prime larger than the
    # current relevant bound cannot occur squared in a candidate.
    my sub extend_wieferich ($limit) {
        for my $t (0 .. $#CP) {
            my $i = $WIDX[$t] // 0;
            my $n = class_count($t);

            while ($i < $n) {
                my $p = p_at($t, $i);
                last if $p > $limit;
                my $z = z_at($t, $i);
                my $e = wieferich_exp($p, $z);
                push @WIEF, [$p, $e, $z, $t] if $e > 1;
                ++$i;
            }

            $WIDX[$t] = $i;
        }
    }

    # Check whether p is excluded by a fixed prime-power base or its order L0.
    my sub forbidden_base_prime ($p, $mbase, $L0, $m_nontrivial) {
        return 0 if !$m_nontrivial;
        return 1 if Rmpz_divisible_ui_p($mbase, $p);
        return 1 if Rmpz_divisible_ui_p($L0,    $p);
        return 0;
    }

    # Obtain the first c eligible primes of this class and their prefix products.
    # This is stronger than using the first c unrestricted odd primes.
    my sub class_prefix ($t, $mbase, $L0, $c) {
        my @prefix       = (Rmpz_init_set($mbase));
        my $idx          = 0;
        my $found        = 0;
        my $m_nontrivial = Rmpz_cmp_ui($mbase, 1) > 0 ? 1 : 0;

        while ($found < $c) {
            my $count = class_count($t);

            while ($idx < $count && $found < $c) {
                my $p = p_at($t, $idx++);
                next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);

                my $ord = z_at($t, $idx - 1);
                next if $m_nontrivial && Rmpz_gcd_ui($NULL, $mbase, $ord) != 1;

                my $z = Rmpz_init();
                Rmpz_mul_ui($z, $prefix[-1], $p);
                return if Rmpz_cmp($z, $B) > 0;
                push @prefix, $z;
                ++$found;
            }

            last if $found >= $c;

            my $next = $have < 10_000 ? 10_000 : $have * 2;
            extend_primes($next);
        }

        return if $found < $c;
        return \@prefix;
    }

    # Maximum prime needed in a non-terminal position, using the class-specific
    # prefix products. The caller completes the global Wieferich scan afterwards.
    my sub sieve_for ($prefix, $c) {
        my $limit = Rmpz_init_set_ui(3);

        for my $depth (0 .. $c - 2) {
            Rmpz_fdiv_q($T, $B, $prefix->[$depth]);
            Rmpz_root($T, $T, $c - $depth);
            Rmpz_set($limit, $T) if Rmpz_cmp($T, $limit) > 0;
        }

        die "Range too large for the native prime table\n" if !Rmpz_fits_ulong_p($limit);

        my $s = Rmpz_get_ui($limit);
        extend_primes($s);
        return $s;
    }

    # Largest raw table index whose prime is <= x. The table contains only
    # primes in one order class, but no temporary filtered arrays are built.
    my sub upper_index ($t, $x) {
        my $n = class_count($t);
        my ($lo, $hi) = (0, $n);
        while ($lo < $hi) {
            my $mid = ($lo + $hi) >> 1;
            if   (p_at($t, $mid) <= $x) { $lo = $mid + 1 }
            else                        { $hi = $mid }
        }
        return $lo - 1;
    }

    # First eligible raw index >= i. Fixed-base exclusions are very sparse, so
    # scanning past them is cheaper than building a filtered Perl array.
    my sub next_allowed_index ($t, $i, $mbase, $L0, $m_nontrivial, $last) {
        my $n = class_count($t);
        while ($i < $n && $i <= $last) {
            my $p = p_at($t, $i);
            return $i if !forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
            ++$i;
        }
        return $n;
    }

    # Conservative residue-domain propagation. For each small prime-power
    # divisor h of L, collect the residues of all possible future class primes.
    # We then ask whether the target m^(-1) mod h can be expressed as a product
    # of exactly $rem residues. Reusing a residue is allowed in this relaxation,
    # so the set is a superset of the true distinct-prime completions: a failed
    # test is therefore a safe prune. We restrict this to small candidate
    # windows to avoid repeatedly scanning large prime ranges.
    my sub residue_feasible ($t, $m, $L, $rem, $first, $last) {
        return 1 if $rem <= 0 || $last < $first;
        return 1 if $last - $first + 1 > 256;

        my @mods = (3, 5, 7, 9, 11, 13, 17, 19, 23, 25, 27, 29, 31);

        for my $mod (@mods) {
            next if !Rmpz_divisible_ui_p($L, $mod);

            my @allowed = (0) x $mod;
            for my $i ($first .. $last) {
                my $p = p_at($t, $i);
                $allowed[$p % $mod] = 1;
            }

            my $m_mod  = Rmpz_fdiv_ui($m, $mod);
            my $target = invmod($m_mod, $mod);
            next if !defined($target);    # gcd(m,L)=1 should already guarantee this

            my @reach = (0) x $mod;
            $reach[1 % $mod] = 1;

            for (1 .. $rem) {
                my @next = (0) x $mod;
                for my $a (0 .. $mod - 1) {
                    next if !$reach[$a];
                    for my $b (1 .. $mod - 1) {
                        next if !$allowed[$b];
                        $next[($a * $b) % $mod] = 1;
                    }
                }
                @reach = @next;
            }

            if (!$reach[$target]) {
                ++$csp_prunes;
                return 0;
            }
        }

        return 1;
    }

    # Compute an admissible decimal-string priority for a child. The bound is
    # m_child times the first cofactor >= (i) the smallest possible remaining
    # prime product, (ii) ceil(A/m_child), and (iii) the required residue class
    # modulo L_child, with the additional fact that the cofactor is odd.
    # Called only for small branches near the leaves; it is used for ordering,
    # never as an approximation in a pruning decision.
    my sub child_priority ($t, $m, $L, $i, $p, $z, $left, $A, $A_matters, $mbase, $L0, $m_nontrivial, $B_ref, $sieve_max) {

        Rmpz_mul_ui($CHM, $m, $p);
        Rmpz_lcm_ui($CHL, $L, $z);
        return if Rmpz_cmp($CHL, $B_ref) >= 0;
        Rmpz_gcd($CHT, $CHM, $CHL);
        return if Rmpz_cmp_ui($CHT, 1) != 0;

        Rmpz_set_ui($CHQ, 1);
        my $idx   = $i + 1;
        my $got   = 0;
        my $count = class_count($t);

        while ($idx < $count && $got < $left) {
            my $j = $idx++;
            my $q = p_at($t, $j);
            last if $q > $sieve_max;
            next if forbidden_base_prime($q, $mbase, $L0, $m_nontrivial);
            next if Rmpz_gcd_ui($NULL, $CHM, z_at($t, $j)) != 1;
            Rmpz_mul_ui($CHQ, $CHQ, $q);
            ++$got;
        }
        my $sentinel = $sieve_max + 1;
        while ($got < $left) {
            Rmpz_mul_ui($CHQ, $CHQ, $sentinel);
            ++$got;
        }

        if ($A_matters) {
            Rmpz_cdiv_q($CHT, $A, $CHM);
            Rmpz_set($CHQ, $CHT) if Rmpz_cmp($CHT, $CHQ) > 0;
        }

        if (Rmpz_cmp_ui($CHL, 1) > 0) {
            Rmpz_invert($CHF, $CHM, $CHL) or return;

            if (Rmpz_cmp($CHF, $CHQ) < 0) {
                Rmpz_sub($CHT, $CHQ, $CHF);
                Rmpz_cdiv_q($CHT, $CHT, $CHL);
                Rmpz_addmul($CHF, $CHT, $CHL);
            }

            # All remaining primes are odd. If L_child is odd, the first
            # solution in the progression may be even; skip it immediately.
            if (Rmpz_tstbit($CHL, 0) && !Rmpz_tstbit($CHF, 0)) {
                Rmpz_add($CHF, $CHF, $CHL);
            }
            Rmpz_set($CHQ, $CHF);
        }
        elsif (!Rmpz_tstbit($CHQ, 0)) {
            Rmpz_add_ui($CHQ, $CHQ, 1);
        }

        Rmpz_fdiv_q($CHB, $B_ref, $CHM);
        return if Rmpz_cmp($CHQ, $CHB) > 0;

        Rmpz_mul($CHT, $CHM, $CHQ);
        return Rmpz_get_str($CHT, 10);
    }

    # Search numbers n = mbase*q in [A,B] within one order class.
    my sub search_combo ($t, $A_in, $mbase, $L0, $r, $prefix_override = undef, $sieve_override = undef) {

        my $c = $k - $r;
        return if $c < 2;
        return if Rmpz_cmp($mbase, $B) > 0;

        my $m_nontrivial = Rmpz_cmp_ui($mbase, 1) > 0 ? 1 : 0;
        Rmpz_gcd($T, $mbase, $L0);
        return if Rmpz_cmp_ui($T, 1) != 0;

        my $prefix = $prefix_override // class_prefix($t, $mbase, $L0, $c);
        return if !$prefix;

        my $A         = Rmpz_init_set($A_in);
        my $A_matters = Rmpz_cmp($A, $prefix->[$c]) > 0 ? 1 : 0;
        Rmpz_set($A, $prefix->[$c]) if !$A_matters;

        my $sieve_max = defined($sieve_override) ? $sieve_override : sieve_for($prefix, $c);
        extend_primes($sieve_max);
        my $cp     = $CP[$t] // '';
        my $cz     = $CZ[$t] // '';
        my $nclass = int(length($cp) / $record_bytes);
        return if !$nclass;

        my @M  = map { Rmpz_init() } 0 .. $c;
        my @LL = map { Rmpz_init() } 0 .. $c;
        my @QM = map { Rmpz_init() } 0 .. $c;
        my @QN = map { Rmpz_init() } 0 .. $c;
        my @AQ = map { Rmpz_init() } 0 .. $c;
        Rmpz_set($M[0],  $mbase);
        Rmpz_set($LL[0], $L0);

        # Search node: M[d] and LL[d] are the current m and lcm. i0 is a raw
        # index into the packed class table; all selected primes are before i0.
        my $search = sub ($d, $i0, $rem) {

            ++$visited_nodes;

            my $m    = $M[$d];
            my $L    = $LL[$d];
            my $qmax = $QM[$d];
            my $qmin = $QN[$d];
            my $aq   = $AQ[$d];

            Rmpz_fdiv_q($qmax, $B, $m);

            Rmpz_root($T, $qmax, $rem);
            my $hi = Rmpz_get_ui($T);
            $hi = $sieve_max if $hi > $sieve_max;

            my $hi_idx = upper_index($t, $hi);
            return if $hi_idx < $i0;

            my $first_idx = next_allowed_index($t, $i0, $mbase, $L0, $m_nontrivial, $hi_idx);
            return if $first_idx > $hi_idx;

            my $lo = p_at($t, $first_idx);

            # Product of the next $rem eligible class primes. This is a much
            # tighter lower bound than the unrestricted-prime product.
            Rmpz_set_ui($qmin, 1);
            my $idx = $first_idx;
            my $got = 0;
            while ($idx < $nclass && $got < $rem) {
                my $j = $idx++;
                my $p = p_at($t, $j);
                last if $p > $sieve_max;
                next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
                next if Rmpz_gcd_ui($NULL, $m, z_at($t, $j)) != 1;
                Rmpz_mul_ui($qmin, $qmin, $p);
                ++$got;
            }

            # The table intentionally ends at the maximum non-terminal prime.
            # Any missing later factor is > sieve_max, so sieve_max+1 is a safe
            # lower-bound substitute (as in the old sentinel-based array).
            my $sentinel = $sieve_max + 1;
            while ($got < $rem) {
                Rmpz_mul_ui($qmin, $qmin, $sentinel);
                ++$got;
            }
            return if Rmpz_cmp($qmin, $qmax) > 0;

            if ($A_matters) {
                Rmpz_cdiv_q($aq, $A, $m);
                Rmpz_set($qmin, $aq) if Rmpz_cmp($aq,   $qmin) > 0;
                return               if Rmpz_cmp($qmin, $qmax) > 0;
            }

            # The cofactor is a product of odd primes even when L == 1.
            Rmpz_add_ui($qmin, $qmin, 1)
              if Rmpz_cmp_ui($L, 1) == 0
              && !Rmpz_tstbit($qmin, 0);

            # Exact congruence lower bound: q == m^(-1) (mod L). Also use
            # q odd, which allows a 2L progression when L is odd.
            my $step_is_2L = 0;
            if (Rmpz_cmp_ui($L, 1) > 0) {
                Rmpz_invert($F, $m, $L) or return;

                if (Rmpz_cmp($F, $qmin) < 0) {
                    Rmpz_sub($T, $qmin, $F);
                    Rmpz_cdiv_q($T, $T, $L);
                    Rmpz_addmul($F, $T, $L);
                }

                if (Rmpz_tstbit($L, 0)) {
                    $step_is_2L = 1;
                    Rmpz_add($F, $F, $L) if !Rmpz_tstbit($F, 0);
                }
                Rmpz_set($qmin, $F);
                return if Rmpz_cmp($qmin, $qmax) > 0;
            }

            # For residue propagation we need the complete domain of every
            # remaining prime, not merely the bound on the *first* remaining
            # prime. The largest possible last prime is at most qmax divided
            # by the smallest possible product of the other rem-1 primes.
            # Apply the CSP filter only when that whole domain is covered by
            # the packed table; otherwise unknown larger primes are treated as
            # unconstrained and no CSP prune is attempted.
            if ($use_csp && $rem > 1) {
                Rmpz_set_ui($T2, 1);
                my $ri = $first_idx;
                my $rg = 0;
                while ($ri < $nclass && $rg < $rem - 1) {
                    my $rp = p_at($t, $ri++);
                    last if $rp > $sieve_max;
                    next if forbidden_base_prime($rp, $mbase, $L0, $m_nontrivial);
                    Rmpz_mul_ui($T2, $T2, $rp);
                    ++$rg;
                }
                while ($rg < $rem - 1) {
                    Rmpz_mul_ui($T2, $T2, $sentinel);
                    ++$rg;
                }
                Rmpz_fdiv_q($T3, $qmax, $T2);
                if (Rmpz_fits_ulong_p($T3)) {
                    my $csp_max = Rmpz_get_ui($T3);
                    if ($csp_max <= $sieve_max) {
                        my $csp_hi_idx = upper_index($t, $csp_max);
                        return if !residue_feasible($t, $m, $L, $rem, $first_idx, $csp_hi_idx);
                    }
                }
            }

            # ---- forced completion -------------------------------------------
            if ($force_ok && Rmpz_cmp_ui($L, 1) > 0) {

                Rmpz_set($F, $qmin);
                if ($step_is_2L) {
                    Rmpz_mul_2exp($S, $L, 1);
                }
                else {
                    Rmpz_set($S, $L);
                }

                Rmpz_sub($T, $qmax, $F);
                Rmpz_fdiv_q($T, $T, $S);

                if (Rmpz_fits_ulong_p($T) && Rmpz_sizeinbase($qmax, 2) <= $force_bits) {
                    my $cnt = Rmpz_get_ui($T) + 1;

                    my $thr = $force_count;
                    if ($force_ratio > 0) {
                        my $N_est =
                          $hi > $lo
                          ? ($hi / log($hi) - $lo / log($lo > 2 ? $lo : 3))
                          : 1;
                        $N_est = 1 if $N_est < 1;
                        my $by_cost = $force_ratio * $N_est;
                        $thr = $by_cost if $by_cost > $thr;
                    }

                    if ($cnt <= $thr) {
                        ++$forced_nodes;
                        Rmpz_set($Q, $F);

                        while (Rmpz_cmp($Q, $qmax) <= 0) {
                            ++$factorizations;
                            my $qs =
                                Rmpz_fits_ulong_p($Q)
                              ? Rmpz_get_ui($Q)
                              : Rmpz_get_str($Q, 10);

                            if (is_rough($qs, $lo) && is_almost_prime($rem, $qs)) {
                                my @f = factor_exp($qs);
                                if (@f == $rem && $f[0][0] >= $lo) {
                                    my $ok = 1;
                                    Rmpz_mul($N, $m, $Q);
                                    Rmpz_sub_ui($N1, $N, 1);

                                    for my $pe (@f) {
                                        my ($s, $e) = @$pe;
                                        if ($e != 1) { $ok = 0; last }
                                        Rmpz_set_str($T3, "$s", 10);
                                        if ($m_nontrivial && Rmpz_divisible_p($mbase, $T3)) {
                                            $ok = 0;
                                            last;
                                        }
                                        if (!class_ok_z($T3)) { $ok = 0; last }
                                        Rmpz_powm($R, $TWO, $N1, $T3);
                                        if (Rmpz_cmp_ui($R, 1) != 0) { $ok = 0; last }
                                    }

                                    if ($ok) {
                                        record($N);
                                        return;
                                    }
                                }
                            }

                            Rmpz_add($Q, $Q, $S);
                        }
                        return;
                    }
                }
            }

            # ---- ordinary recursion -----------------------------------------
            if ($rem > 2) {

                # Local best-first ordering. We only materialize choices when
                # there are at most 64 raw candidates and <= 4 primes remain;
                # the list is therefore bounded independently of n and the
                # global search frontier never grows.
                my $raw_width = $hi_idx - $first_idx + 1;
                if ($use_best_first && $rem <= 4 && $raw_width <= 64) {
                    my @choices;

                    for (my $i = $first_idx ; $i <= $hi_idx ; ++$i) {
                        my $p = p_at($t, $i);
                        next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
                        my $z = z_at($t, $i);
                        next if Rmpz_gcd_ui($NULL, $m, $z) != 1;

                        my $key = child_priority($t, $m, $L, $i, $p, $z, $rem - 1, $A, $A_matters, $mbase, $L0, $m_nontrivial, $B, $sieve_max);
                        push @choices, [$key, $i] if defined $key;
                    }

                    @choices = sort { length($a->[0]) <=> length($b->[0]) || $a->[0] cmp $b->[0] } @choices;

                    for my $choice (@choices) {
                        my $i = $choice->[1];
                        my $p = p_at($t, $i);
                        next if $p > $hi;    # B may have tightened after an earlier child
                        my $z = z_at($t, $i);

                        Rmpz_lcm_ui($LL[$d + 1], $L, $z);
                        next if Rmpz_cmp($LL[$d + 1], $B) >= 0;
                        Rmpz_mul_ui($M[$d + 1], $m, $p);
                        Rmpz_gcd($T, $M[$d + 1], $LL[$d + 1]);
                        next if Rmpz_cmp_ui($T, 1) != 0;

                        ++$best_first_nodes;
                        my $g = $gen;
                        __SUB__->($d + 1, $i + 1, $rem - 1);

                        if ($g != $gen) {
                            Rmpz_fdiv_q($qmax, $B, $m);
                            Rmpz_root($T, $qmax, $rem);
                            $hi     = Rmpz_get_ui($T);
                            $hi     = $sieve_max if $hi > $sieve_max;
                            $hi_idx = upper_index($t, $hi);
                        }
                    }

                    return;
                }

                my $g = $gen;
                for (my $i = $first_idx ; $i <= $hi_idx ; ++$i) {
                    my $p = p_at($t, $i);
                    next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
                    my $z = z_at($t, $i);
                    next if Rmpz_gcd_ui($NULL, $m, $z) != 1;

                    Rmpz_lcm_ui($LL[$d + 1], $L, $z);
                    next if Rmpz_cmp($LL[$d + 1], $B) >= 0;

                    Rmpz_mul_ui($M[$d + 1], $m, $p);
                    Rmpz_gcd($T, $M[$d + 1], $LL[$d + 1]);
                    next if Rmpz_cmp_ui($T, 1) != 0;

                    __SUB__->($d + 1, $i + 1, $rem - 1);

                    if ($g != $gen) {
                        $g = $gen;
                        Rmpz_fdiv_q($qmax, $B, $m);
                        Rmpz_root($T, $qmax, $rem);
                        $hi     = Rmpz_get_ui($T);
                        $hi     = $sieve_max if $hi > $sieve_max;
                        $hi_idx = upper_index($t, $hi);
                    }
                }

                return;
            }

            # ---- tail: two primes left, p and terminal prime q ---------------
            ++$tail_nodes;

            my $i;
            for ($i = $first_idx ; $i <= $hi_idx ; ++$i) {
                my $p = p_at($t, $i);
                next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
                my $z = z_at($t, $i);

                Rmpz_lcm_ui($L2, $L, $z);
                Rmpz_mul_ui($M2, $m, $p);

                Rmpz_invert($TT, $M2, $L2) or next;
                Rmpz_fdiv_q_ui($H, $qmax, $p);
                next if Rmpz_cmp($TT, $H) > 0;

                # q must be odd. If L2 is odd, use every second term of the
                # progression; if L2 is even, all terms already have odd parity.
                if (Rmpz_tstbit($L2, 0)) {
                    Rmpz_add($TT, $TT, $L2) if !Rmpz_tstbit($TT, 0);
                    Rmpz_mul_2exp($S, $L2, 1);
                }
                else {
                    Rmpz_set($S, $L2);
                }

                Rmpz_set_ui($LO, $p + 2);
                if ($A_matters) {
                    Rmpz_cdiv_q_ui($T2, $aq, $p);
                    Rmpz_set($LO, $T2) if Rmpz_cmp($T2, $LO) > 0;
                }

                if (Rmpz_cmp($TT, $LO) < 0) {
                    Rmpz_sub($T2, $LO, $TT);
                    Rmpz_cdiv_q($T2, $T2, $S);
                    Rmpz_addmul($TT, $T2, $S);
                }
                next if Rmpz_cmp($TT, $H) > 0;

                Rmpz_sub_ui($M2M1, $M2, 1);
                my $hit = 0;

                if (Rmpz_fits_ulong_p($M2M1) && Rmpz_fits_ulong_p($H) && Rmpz_fits_ulong_p($S)) {
                    my ($tn, $hn, $sn, $en) = (Rmpz_get_ui($TT), Rmpz_get_ui($H), Rmpz_get_ui($S), Rmpz_get_ui($M2M1));
                    for (; $tn <= $hn ; $tn += $sn) {
                        if (powmod(2, $en, $tn) == 1 && class_ok_ui($tn) && is_prime($tn)) {
                            next if $m_nontrivial && Rmpz_divisible_ui_p($mbase, $tn);
                            Rmpz_mul_ui($NN, $M2, $tn);
                            $hit = 1;
                            last;
                        }
                    }
                }
                else {
                    while (Rmpz_cmp($TT, $H) <= 0) {
                        Rmpz_powm($R, $TWO, $M2M1, $TT);
                        if (   Rmpz_cmp_ui($R, 1) == 0
                            && !($m_nontrivial && Rmpz_divisible_p($mbase, $TT))
                            && z_is_prime($TT)
                            && class_ok_z($TT)) {
                            Rmpz_mul($NN, $M2, $TT);
                            $hit = 1;
                            last;
                        }
                        Rmpz_add($TT, $TT, $S);
                    }
                }

                if ($hit) {
                    ++$terminal_hits;
                    record($NN);

                    Rmpz_fdiv_q($qmax, $B, $m);
                    Rmpz_root($T, $qmax, 2);
                    $hi     = Rmpz_get_ui($T);
                    $hi     = $sieve_max if $hi > $sieve_max;
                    $hi_idx = upper_index($t, $hi);
                }
            }

            $tail_primes += $i - $first_idx;
            return;
        };

        $search->(0, 0, $c);
    }

    my $one = Rmpz_init_set_ui(1);

    my sub search_class ($t, $A, $seed_prefix, $seed_sieve) {

        search_combo($t, $A, $one, $one, 0, $seed_prefix, $seed_sieve);

        # Include powers of Wieferich primes. The squarefree search above ensures
        # the table and Wieferich scan have been extended far enough for this
        # class before these combinations are constructed.
        my @combos = ([$one, $one, 0]);

        foreach my $w (@WIEF) {
            my ($p, $emax, $z, $wt) = @$w;
            next if $wt != $t;

            my @new;
            foreach my $cb (@combos) {
                my ($m0, $l0, $r) = @$cb;
                for my $e (2 .. $emax) {
                    my $nm = Rmpz_init();
                    Rmpz_ui_pow_ui($nm, $p, $e);
                    Rmpz_mul($nm, $nm, $m0);
                    my $nl = Rmpz_init_set_ui($z);
                    Rmpz_lcm($nl, $nl, $l0);
                    push @new, [$nm, $nl, $r + 1];
                }
            }
            push @combos, @new;
        }

        shift @combos;
        foreach my $cb (@combos) {
            search_combo($t, $A, @$cb);
        }
    }

    # Initial lower bound: product of the k smallest odd primes.
    my @prefix0 = (Rmpz_init_set_ui(1));
    {
        my $p = 2;
        for my $j (1 .. $k) {
            $p = next_prime($p);
            my $z = Rmpz_init();
            Rmpz_mul_ui($z, $prefix0[$j - 1], $p);
            push @prefix0, $z;
        }
    }

    my $lower = Rmpz_init_set($prefix0[$k]);
    my $upper = Rmpz_init();
    Rmpz_mul_2exp($upper, $lower, 1);

    while (1) {

        Rmpz_set($B, $upper);
        $have_best = 0;

        my $started = time();
        my $bits    = Rmpz_sizeinbase($B, 2);
        my $max_t   = int(($bits - 1) / $k);

        # First prepare every order class. This is important for completeness:
        # later classes can force the shared prime table to grow, and that can
        # reveal Wieferich primes belonging to an earlier class. We therefore
        # finish the global relevant Wieferich scan before searching any class.
        my (@seed_prefix, @seed_sieve);
        my $global_sieve_max = 3;

        for my $t (0 .. $max_t) {
            last if $t * $k >= Rmpz_sizeinbase($B, 2);
            if ($t == 0) { ($ce, $cr) = (0, 1) }
            else         { ($ce, $cr) = ($t - 1, -1) }

            my $pref = class_prefix($t, $one, $one, $k);
            next if !$pref;
            my $s = sieve_for($pref, $k);
            $seed_prefix[$t]  = $pref;
            $seed_sieve[$t]   = $s;
            $global_sieve_max = $s if $s > $global_sieve_max;
        }

        extend_primes($global_sieve_max);
        extend_wieferich($global_sieve_max);

        for my $t (0 .. $max_t) {
            next if !$seed_prefix[$t];
            last if $t * $k >= Rmpz_sizeinbase($B, 2);
            if ($t == 0) { ($ce, $cr) = (0, 1) }
            else         { ($ce, $cr) = ($t - 1, -1) }
            search_class($t, $lower, $seed_prefix[$t], $seed_sieve[$t]);
        }

        if ($verbose) {
            my $table_bytes = 0;
            $table_bytes += length($_ // '') for @CP, @CZ;
            printf STDERR
"[%s, %s] nodes=%d tails=%d tail_primes=%d forced=%d factorizations=%d terminal=%d csp_prunes=%d best_first=%d prime_table=%.1f MiB time=%.3f s%s\n",
              Rmpz_get_str($lower, 10), Rmpz_get_str($upper, 10),
              $visited_nodes,  $tail_nodes,    $tail_primes, $forced_nodes,
              $factorizations, $terminal_hits, $csp_prunes,  $best_first_nodes,
              ($table_bytes / 1048576),
              time() - $started, ($have_best ? ' FOUND' : '');
        }

        return Rmpz_init_set($best) if $have_best;

        Rmpz_add_ui($lower, $upper, 1);
        Rmpz_mul_2exp($upper, $upper, 1);
    }
}

sub usage ($status = 0) {
    my $fh = $status ? *STDERR : *STDOUT;
    print {$fh} <<'USAGE';
Usage:
  perl strong_psp_base2_smallest_optimized.pl [options] [n]

Find the smallest strong pseudoprime to base 2 with exactly n >= 2 distinct
prime factors (OEIS A180065). Without n, print the terms for n = 2..12.

Options:
  --force-bits=N    Maximum bit length for forced cofactor factoring (64)
  --force-count=N   Always factor directly when at most N candidates remain (16)
  --force-ratio=X   Also factor directly when candidates <= X * estimated loop
                    size (0.75; 0 = use only --force-count)
  --csp             Enable the conservative residue-CSP pruning experiment
  --best-first      Enable bounded best-first ordering near the search leaves
  --verbose         Print search statistics to STDERR
  --help            Show this help
USAGE
    exit $status;
}

my $force_bits     = 64;
my $force_count    = 16;
my $force_ratio    = 0.75;
my $verbose        = 0;
my $use_csp        = 0;
my $use_best_first = 0;
my $help           = 0;

GetOptions(
           'force-bits=i'  => \$force_bits,
           'force-count=i' => \$force_count,
           'force-ratio=f' => \$force_ratio,
           'csp!'          => \$use_csp,
           'best-first!'   => \$use_best_first,
           'verbose!'      => \$verbose,
           'help|h'        => \$help,
          )
  or usage(2);

usage(0) if $help;
usage(2) if @ARGV > 1;

my @ns = @ARGV ? ($ARGV[0]) : (2 .. 12);

foreach my $n (@ns) {
    usage(2) if $n !~ /\A\d+\z/ || $n < 2;
    my $term = strong_fermat_psp_base2_smallest(
                                                $n,
                                                force_bits  => $force_bits,
                                                force_count => $force_count,
                                                force_ratio => $force_ratio,
                                                csp         => $use_csp,
                                                best_first  => $use_best_first,
                                                verbose     => $verbose,
                                               );
    say "a($n) = $term";
    say STDERR "factorization: ", join(' * ', map { $_->[1] > 1 ? "$_->[0]^$_->[1]" : $_->[0] } factor_exp("$term")) if $verbose;
}
