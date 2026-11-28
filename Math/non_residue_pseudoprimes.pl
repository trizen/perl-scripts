#!/usr/bin/env perl

# Smallest "non-residue" pseudoprime to base prime(n):
# the least odd composite k with A020649(k) = q = prime(n) and q^((k-1)/2) == -1 (mod k).
#
# Usage:
#   perl nonresidue_psp_fast.pl [options] [n ...]
#
# Options:
#   --upper=N         stop at N (a known upper bound; the search then proves/refines it)
#   --force-count=N   factor the cofactor directly when at most N candidates remain (16)
#   --force-ratio=X   ... or at most X * (number of primes the loop would visit)   (0.5)
#   --force-bits=N    ... only when the cofactor has at most N bits                (64)
#   --wheel-count=N   max size of the residue wheel used to enumerate good primes  (400000)
#   --verbose         statistics on STDERR
#
# Requires Math::Prime::Util >= 0.74 and Math::GMPz.
#
# Theory
# ------
# Let q = prime(n), k odd composite, and z_p = ord_p(q).  The conditions are equivalent to:
#
#  (1) every prime p | k is "good":  p > q  and  (r/p) = 1 for every prime r < q
#      (r must be a square mod k;  a prime p < q dividing k is impossible, because the
#      least non-residue mod p is smaller than p, and q itself cannot divide k);
#  (2) q^((k-1)/2) == -1 (mod k):  then v2(z_p) = v2(k-1) = t for ALL p | k, and z_p | k-1.
#      So all primes of k lie in one class t = v2(z_p) >= 1, and with L = lcm(z_p):
#           k == 1 + L  (mod 2L)         (k-1 is an ODD multiple of L);
#  (3) q is a non-residue mod some p | k (equivalently, q is not a square mod k).
#
# Good primes are very rare (density 2^-(n-1)): they are enumerated with a CRT wheel over
# the primes r < q (the allowed residues of p mod 8*3*5*...), never by sieving everything.
#
# Search: depth-first over good primes p_1 < p_2 < ... of one class t (m = product so far,
# L = lcm of orders):
#   * forced completion: the cofactor Q must be  F + j*2L  -> if there are few, factor them;
#   * the last two levels are inlined; the terminal prime p_c satisfies the single congruence
#          p_c == (1+L)/m (mod 2L)       and      q^((m-1)/2) == -(q/p_c)  (mod p_c)
#     (because q^((k-1)/2) = q^((m-1)/2) * (q/p_c)^m), walked over a progression that is itself
#     filtered by a small wheel on the index;
#   * Wieferich primes (q^z == 1 mod p^2) are the only ones allowed with exponent >= 2: they
#     are handled as a fixed multiplier m_0.
# Every candidate is finally re-verified directly, so the pruning only has to be *necessary*.
# Intervals [A, B] double until a solution is found, so the first hit is the minimum.

use v5.36;
use strict;
use warnings;
no warnings 'recursion';

use Getopt::Long qw(GetOptions);
use Time::HiRes  qw(time);

use Math::GMPz        qw(:mpz);
use Math::Prime::Util qw(
  factor_exp is_prime kronecker nth_prime powmod primes valuation znorder
  next_prime lcm gcd
);

# ---------------------------------------------------------------------------
# 64-bit UV <-> Math::GMPz helpers (safe when GMP unsigned long is 32-bit)
# ---------------------------------------------------------------------------

my $U64_TMP = Rmpz_init();
my $U64_ARG = Rmpz_init();

sub z_dec ($s) { my $z = Rmpz_init(); Rmpz_set_str($z, "$s", 10); $z }
sub z_str ($z) { Rmpz_get_str($z, 10) }
sub z_val ($z) { Rmpz_fits_ulong_p($z) ? Rmpz_get_ui($z) : Rmpz_get_str($z, 10) }

sub mpz_set_u64 ($z, $u) {
    if ($u <= 0xffffffff) {
        Rmpz_set_ui($z, $u);
    }
    elsif ($u < ~0) {
        Rmpz_set_ui($z, $u >> 32);
        Rmpz_mul_2exp($z, $z, 32);
        Rmpz_add_ui($z, $z, $u & 0xffffffff);
    }
    else {
        Rmpz_set_str($z, "$u", 10);
    }
}

sub mpz_fits_u64 ($z) {
    return Rmpz_sgn($z) >= 0 && Rmpz_sizeinbase($z, 2) <= 64;
}

sub mpz_get_u64 ($z) {
    return Rmpz_get_ui($z) if Rmpz_fits_ulong_p($z);
    Rmpz_fdiv_q_2exp($U64_TMP, $z, 32);
    my $hi = Rmpz_get_ui($U64_TMP);
    Rmpz_tdiv_r_2exp($U64_TMP, $z, 32);
    my $lo = Rmpz_get_ui($U64_TMP);
    return (($hi << 32) | $lo);
}

sub mpz_mul_u64 ($z, $a, $u) {
    if ($u <= 0xffffffff) {
        Rmpz_mul_ui($z, $a, $u);
    }
    else {
        mpz_set_u64($U64_ARG, $u);
        Rmpz_mul($z, $a, $U64_ARG);
    }
}

sub mpz_lcm_u64 ($z, $a, $u) {
    if ($u <= 0xffffffff) {
        Rmpz_lcm_ui($z, $a, $u);
    }
    else {
        mpz_set_u64($U64_ARG, $u);
        Rmpz_lcm($z, $a, $U64_ARG);
    }
}

sub mpz_fdiv_q_u64 ($z, $a, $u) {
    if ($u <= 0xffffffff) {
        Rmpz_fdiv_q_ui($z, $a, $u);
    }
    else {
        mpz_set_u64($U64_ARG, $u);
        Rmpz_fdiv_q($z, $a, $U64_ARG);
    }
}

# ---------------------------------------------------------------------------
# a(n)
# ---------------------------------------------------------------------------

sub nonresidue_psp ($n, %opt) {

    my $force_count = $opt{force_count} // 16;
    my $force_ratio = $opt{force_ratio} // 0.5;
    my $force_bits  = $opt{force_bits}  // 64;
    my $wheel_cap   = $opt{wheel_count} // 400_000;
    my $verbose     = $opt{verbose}     // 0;
    my $upper_cap   = defined($opt{upper}) ? z_dec($opt{upper}) : undef;
    my $collect     = $opt{all}            ? 1                  : 0;       # list every solution in [lower, upper]
    my @found;

    my $started = time();
    my $q       = nth_prime($n);
    my $Q_Z     = Rmpz_init();
    mpz_set_u64($Q_Z, $q);
    my $NULL     = $Math::GMPz::NULL;
    my @SP       = @{primes($q - 1)};                                      # primes below q (all must be residues)
    my $force_ok = ($force_count > 0 && $force_bits > 0) ? 1 : 0;

    # ------------------------------------------------------------------
    # wheels. residues x mod W such that (r/x) = 1 for the wheel primes r
    # ------------------------------------------------------------------
    my sub make_wheel ($rmax, $count_cap, $w_cap) {
        my ($W, @res, @used) = (2);
        @res = (1);
        if ($q > 2) { ($W, @res) = (8, 1, 7) }
        for my $r (grep { $_ > 2 } @SP) {
            last if $r > $rmax;
            last if @res * ($r - 1) / 2 > $count_cap || $W * $r > $w_cap;
            my @new;
            for my $a (@res) {
                for my $i (0 .. $r - 1) {
                    my $x = $a + $W * $i;
                    push @new, $x if kronecker($r, $x) == 1;
                }
            }
            @res = @new;
            $W *= $r;
            push @used, $r;
        }
        @res = sort { $a <=> $b } @res;
        return ($W, \@res, \@used);
    }

    # big wheel: enumeration of good primes
    my ($WB, $resB, $usedB) = make_wheel(1e9, $wheel_cap, 2**42);
    my %inB   = map  { $_ => 1 } @$usedB;
    my @RESTB = grep { $_ > 2 && !$inB{$_} } @SP;    # tested by Kronecker per candidate
    $inB{2} = 1;

    # small wheel (primes <= 13): table lookup for the progression walks
    my ($WM, $resM, $usedM) = make_wheel(13, 10**9, 10**9);
    my @OKM = (0) x $WM;
    $OKM[$_] = 1 for @$resM;
    my %inM   = map  { $_ => 1 } @$usedM;
    my @RESTM = grep { $_ > 2 && !$inM{$_} } @SP;

    # ------------------------------------------------------------------
    # table of good primes, split in classes t = v2(ord_p(q))
    # ------------------------------------------------------------------
    my (@CP, @CZ, @WIEF);    # per class: primes / orders ; Wieferich list [p, z, t]
    my $have_X = $q;         # all good primes <= have_X are in the tables

    my ($W_P, $W_P2, $W_Z, $W_R) = map { Rmpz_init() } 1 .. 4;

    my sub extend_good ($X) {
        return                                              if $X <= $have_X;
        die "range too large for the native prime tables\n" if $X >= 2**62;
        my $lo = $have_X + 1;
        my $b0 = int($lo / $WB) * $WB;
        for (my $base = $b0 ; $base <= $X ; $base += $WB) {

            my $start = 0;
            if ($base == $b0) {    # binary search for the first residue >= lo - base
                my ($l, $h) = (0, scalar @$resB);
                my $key = $lo - $base;
                while ($l < $h) {
                    my $mid = ($l + $h) >> 1;
                    if   ($resB->[$mid] < $key) { $l = $mid + 1 }
                    else                        { $h = $mid }
                }
                $start = $l;
            }

          CAND: for my $idx ($start .. $#$resB) {
                my $p = $base + $resB->[$idx];
                last if $p > $X;
                for my $r (@RESTB) { next CAND if kronecker($r, $p) != 1 }
                next if !is_prime($p);
                my $z = znorder($q, $p);
                my $t = valuation($z, 2);
                next if $t == 0;
                push @{$CP[$t]}, $p;
                push @{$CZ[$t]}, $z;

                my $is_wief;
                if ($p < 4294967296) {
                    $is_wief = (powmod($q, $z, $p * $p) == 1);
                }
                else {
                    mpz_set_u64($W_P, $p);
                    Rmpz_mul($W_P2, $W_P, $W_P);
                    mpz_set_u64($W_Z, $z);
                    Rmpz_powm($W_R, $Q_Z, $W_Z, $W_P2);
                    $is_wief = (Rmpz_cmp_ui($W_R, 1) == 0);
                }
                push @WIEF, [$p, $z, $t] if $is_wief;
            }
        }
        $have_X = $X;
    }

    # largest e with q^z == 1 (mod p^e)
    my sub wief_exp ($p, $z) {
        my ($pe, $zz, $r, $e) = (Rmpz_init(), Rmpz_init(), Rmpz_init(), 1);
        mpz_set_u64($pe, $p);
        mpz_set_u64($zz, $z);
        while (1) {
            mpz_mul_u64($pe, $pe, $p);
            Rmpz_powm($r, $Q_Z, $zz, $pe);
            last if Rmpz_cmp_ui($r, 1) != 0;
            ++$e;
        }
        return $e;
    }

    # ------------------------------------------------------------------
    # state
    # ------------------------------------------------------------------
    my ($A, $B) = (Rmpz_init(), Rmpz_init());    # current window; B is lowered on every find
    my $best      = Rmpz_init();
    my $have_best = 0;
    my $gen       = 0;
    my ($visited, $walks, $cands, $forced, $facts) = (0) x 5;

    my ($T, $T2, $T3, $F, $S, $TT, $H, $LO, $M2, $L2, $S2, $NN, $R) = map { Rmpz_init() } 1 .. 13;
    my @stack;                                   # primes chosen so far (also the prime-power bases)

    # direct verification of a candidate k whose distinct primes are in @$pl
    my sub final_check ($k, $pl) {
        for my $p (@$pl) {
            for my $r (@SP) { return 0 if kronecker($r, $p) != 1 }
        }
        my $nonres = 0;
        for my $p (@$pl) {
            if (kronecker($q, $p) == -1) { $nonres = 1; last }
        }
        return 0 if !$nonres;
        Rmpz_sub_ui($R, $k, 1);
        Rmpz_fdiv_q_2exp($R, $R, 1);
        Rmpz_powm($R, $Q_Z, $R, $k);
        Rmpz_add_ui($R, $R, 1);
        return Rmpz_cmp($R, $k) == 0;
    }

    my sub record ($k) {
        if ($collect) { push @found, z_str($k); return }
        return if $have_best && Rmpz_cmp($k, $best) >= 0;
        Rmpz_set($best, $k);
        Rmpz_sub_ui($B, $k, 1);
        $have_best = 1;
        ++$gen;
    }

    # ------------------------------------------------------------------
    # terminal prime:  k = M2 * p_c,  p_c in [max(LO0, ceil(A/M2)), H],
    #   p_c == TT (mod S2),  q^((M2-1)/2) == -(q/p_c) (mod p_c)
    # ------------------------------------------------------------------
    my sub walk ($M2, $S2, $first, $Hz, $plast) {

        # lower end:  p_c > plast  and  M2*p_c >= A
        mpz_set_u64($LO, $plast + 1);
        Rmpz_cdiv_q($T3, $A, $M2);
        Rmpz_set($LO, $T3) if Rmpz_cmp($T3, $LO) > 0;
        if (Rmpz_cmp($first, $LO) < 0) {
            Rmpz_sub($T3, $LO, $first);
            Rmpz_cdiv_q($T3, $T3, $S2);
            Rmpz_addmul($first, $T3, $S2);
        }
        return if Rmpz_cmp($first, $Hz) > 0;
        ++$walks;

        Rmpz_sub_ui($T3, $M2, 1);
        Rmpz_fdiv_q_2exp($T3, $T3, 1);    # (M2-1)/2

        if (   mpz_fits_u64($Hz)
            && Rmpz_sizeinbase($Hz, 2) <= 63
            && mpz_fits_u64($S2)
            && mpz_fits_u64($T3)) {

            my ($pc, $hn, $sn, $e) = (mpz_get_u64($first), mpz_get_u64($Hz), mpz_get_u64($S2), mpz_get_u64($T3));

            # index wheel: p = pc + sn*j  is allowed only if OKM[p mod WM]
            my $cnt = int(($hn - $pc) / $sn) + 1;
            my @jl;
            my $J = 0;
            if ($WM > 1) {
                my $g = gcd($sn, $WM);
                $J = $WM / $g;
                if ($cnt >= 8 * $J && $J > 1) {
                    my ($x, $s) = ($pc % $WM, $sn % $WM);
                    for my $j (0 .. $J - 1) {
                        push @jl, $j if $OKM[$x];
                        $x += $s;
                        $x -= $WM if $x >= $WM;
                    }
                }
            }

            my $check = sub ($p) {
                ++$cands;
                for my $r (@RESTM) { return 0 if kronecker($r, $p) != 1 }
                my $eps  = kronecker($q, $p);
                my $want = $eps == 1 ? $p - 1 : 1;
                return 0 if powmod($q, $e, $p) != $want;
                return 0 if !is_prime($p);
                mpz_mul_u64($NN, $M2, $p);
                return 0 if !final_check($NN, [@stack, $p]);
                record($NN);
                return $collect ? 0 : 1;
            };

            if (@jl) {
                my $span = $sn * $J;
                for (my $base = $pc ; $base <= $hn ; $base += $span) {
                    for my $j (@jl) {
                        my $p = $base + $sn * $j;
                        last if $p > $hn;
                        if ($OKM[$p % $WM]) { return if $check->($p) }
                    }
                    last if $span > $hn - $base;
                }
                return;
            }

            while (1) {
                if ($OKM[$pc % $WM]) { return if $check->($pc) }
                last if $sn > $hn - $pc;
                $pc += $sn;
            }
            return;
        }

        # big numbers: generic path
        Rmpz_set($TT, $first);
        while (Rmpz_cmp($TT, $Hz) <= 0) {
            ++$cands;
            my $ps = z_val($TT);
            my $ok = 1;
            for my $r (@SP) {
                if (kronecker($r, $ps) != 1) { $ok = 0; last }
            }
            if ($ok) {
                my $eps = kronecker($q, $ps);
                Rmpz_powm($R, $Q_Z, $T3, $TT);
                my $good = $eps == 1 ? (Rmpz_add_ui($R, $R, 1), Rmpz_cmp($R, $TT) == 0) : (Rmpz_cmp_ui($R, 1) == 0);
                if ($good && is_prime($ps)) {
                    Rmpz_mul($NN, $M2, $TT);
                    if (final_check($NN, [@stack, $ps])) { record($NN); return if !$collect }
                }
            }
            Rmpz_add($TT, $TT, $S2);
        }
    }

    # ------------------------------------------------------------------
    # search of  k = m0 * (c further primes of class t), c >= 1
    # ------------------------------------------------------------------
    my sub search_class ($t, $m0, $L0, $c, $base_primes) {

        my $P    = $CP[$t] // [];
        my $Z    = $CZ[$t] // [];
        my $nP   = scalar @$P;
        my $sent = $have_X + 1;
        my %skip = map { $_ => 1 } @$base_primes;

        my @M  = map { Rmpz_init() } 0 .. $c;
        my @LL = map { Rmpz_init() } 0 .. $c;
        my @QM = map { Rmpz_init() } 0 .. $c;
        my @QN = map { Rmpz_init() } 0 .. $c;
        Rmpz_set($M[0],  $m0);
        Rmpz_set($LL[0], $L0);
        @stack = @$base_primes;

        my $node;
        $node = sub ($d, $i0, $rem) {

            ++$visited;
            my ($m, $L, $qmax, $qmin) = ($M[$d], $LL[$d], $QM[$d], $QN[$d]);

            Rmpz_fdiv_q($qmax, $B, $m);
            Rmpz_root($T, $qmax, $rem);
            return if !mpz_fits_u64($T);
            my $hi = mpz_get_u64($T);
            my $lo = $i0 < $nP ? $P->[$i0] : $sent;
            return if $lo > $hi;

            # cofactor lower bound: product of the next primes of the class table
            mpz_set_u64($qmin, $lo);
            for my $j (1 .. $rem - 1) {
                mpz_mul_u64($qmin, $qmin, $i0 + $j < $nP ? $P->[$i0 + $j] : $sent);
            }
            return if Rmpz_cmp($qmin, $qmax) > 0;

            Rmpz_cdiv_q($T2, $A, $m);
            if (Rmpz_cmp($T2, $qmin) > 0) {
                Rmpz_set($qmin, $T2);
                return if Rmpz_cmp($qmin, $qmax) > 0;
            }

            # ---- forced completion: Q == (1+L)/m (mod 2L) -----------------
            if ($force_ok && Rmpz_cmp_ui($L, 1) > 0) {

                Rmpz_mul_2exp($S, $L, 1);
                Rmpz_invert($F, $m, $S) or return;
                Rmpz_add_ui($T, $L, 1);
                Rmpz_mul($F, $F, $T);
                Rmpz_mod($F, $F, $S);
                if (Rmpz_cmp($F, $qmin) < 0) {
                    Rmpz_sub($T, $qmin, $F);
                    Rmpz_cdiv_q($T, $T, $S);
                    Rmpz_addmul($F, $T, $S);
                }
                return if Rmpz_cmp($F, $qmax) > 0;

                Rmpz_sub($T, $qmax, $F);
                Rmpz_fdiv_q($T, $T, $S);

                if (Rmpz_fits_ulong_p($T) && Rmpz_sizeinbase($qmax, 2) <= $force_bits) {
                    my $cnt = Rmpz_get_ui($T) + 1;

                    # number of primes the loop below would visit
                    my ($l, $h) = ($i0, $nP);
                    while ($l < $h) {
                        my $mid = ($l + $h) >> 1;
                        if   ($P->[$mid] <= $hi) { $l = $mid + 1 }
                        else                     { $h = $mid }
                    }
                    my $loop_n = $l - $i0;
                    my $thr    = $force_count;
                    $thr = $force_ratio * $loop_n if $force_ratio * $loop_n > $thr;

                    if ($cnt <= $thr) {
                        ++$forced;
                        Rmpz_set($TT, $F);
                        while (Rmpz_cmp($TT, $qmax) <= 0) {
                            ++$facts;
                            my @f = factor_exp(z_val($TT));
                            if (@f == $rem && $f[0][0] >= $lo && !grep { $_->[1] != 1 } @f) {
                                Rmpz_mul($NN, $m, $TT);
                                my @pl = map { $_->[0] } @f;
                                if (final_check($NN, [@stack, @pl])) { record($NN); return if !$collect }
                            }
                            Rmpz_add($TT, $TT, $S);
                        }
                        return;
                    }
                }
            }

            # ---- ordinary recursion -----------------------------------------
            if ($rem > 2) {
                my ($cm, $cl) = ($M[$d + 1], $LL[$d + 1]);
                my $g = $gen;
                for (my $i = $i0 ; $i < $nP ; ++$i) {
                    my $p = $P->[$i];
                    last if $p > $hi;
                    next if $skip{$p};
                    mpz_lcm_u64($cl, $L, $Z->[$i]);
                    next if Rmpz_cmp($cl, $B) >= 0;
                    mpz_mul_u64($cm, $m, $p);
                    next if Rmpz_gcd($T, $cm, $cl), Rmpz_cmp_ui($T, 1) != 0;
                    push @stack, $p;
                    $node->($d + 1, $i + 1, $rem - 1);
                    pop @stack;

                    if ($g != $gen) {
                        $g = $gen;
                        Rmpz_fdiv_q($qmax, $B, $m);
                        Rmpz_root($T, $qmax, $rem);
                        $hi = mpz_get_u64($T);
                    }
                }
                return;
            }

            # ---- tail: p and the terminal prime ---------------------------------
            my $g = $gen;
            for (my $i = $i0 ; $i < $nP ; ++$i) {
                my $p = $P->[$i];
                last if $p > $hi;
                next if $skip{$p};

                mpz_lcm_u64($L2, $L, $Z->[$i]);
                next if Rmpz_cmp($L2, $B) >= 0;
                mpz_mul_u64($M2, $m, $p);
                Rmpz_mul_2exp($S2, $L2, 1);
                Rmpz_invert($TT, $M2, $S2) or next;    # gcd(m*p, L2) != 1
                Rmpz_add_ui($T, $L2, 1);
                Rmpz_mul($TT, $TT, $T);
                Rmpz_mod($TT, $TT, $S2);

                mpz_fdiv_q_u64($H, $qmax, $p);
                next if Rmpz_cmp($TT, $H) > 0;         # common case: no terminal prime

                push @stack, $p;
                walk($M2, $S2, $TT, $H, $p);
                pop @stack;

                if ($g != $gen) {
                    $g = $gen;
                    Rmpz_fdiv_q($qmax, $B, $m);
                    Rmpz_root($T, $qmax, 2);
                    $hi = mpz_get_u64($T);
                }
            }
            return;
        };

        if ($c == 1) {

            # only the terminal prime: k = m0 * p,  m0 is a Wieferich power
            Rmpz_mul_2exp($S2, $L0, 1);
            Rmpz_invert($TT, $m0, $S2) or return;
            Rmpz_add_ui($T, $L0, 1);
            Rmpz_mul($TT, $TT, $T);
            Rmpz_mod($TT, $TT, $S2);
            Rmpz_fdiv_q($H, $B, $m0);
            return if Rmpz_cmp($TT, $H) > 0;
            Rmpz_set($M2, $m0);
            walk($M2, $S2, $TT, $H, $q);
            return;
        }

        $node->(0, 0, $c);
    }

    # ------------------------------------------------------------------
    # one window [A, B]
    # ------------------------------------------------------------------
    my sub search_window () {

        Rmpz_sqrt($T, $B);
        die "range too large\n" if !mpz_fits_u64($T);
        extend_good(mpz_get_u64($T));

        # Wieferich primes: exponent limits
        my @wf = map { [$_->[0], wief_exp($_->[0], $_->[1]), $_->[1], $_->[2]] } @WIEF;

        my $max_t = $#CP;
        for my $t (1 .. $max_t) {
            my $P = $CP[$t] or next;

            # squarefree k with c >= 2 primes of class t
            for my $c (2 .. 200) {
                my $nP = scalar @$P;
                last if $nP < $c - 1;
                my $prod = Rmpz_init_set_ui(1);
                for my $j (0 .. $c - 1) {
                    mpz_mul_u64($prod, $prod, $j < $nP ? $P->[$j] : $have_X + 1);
                }
                last if Rmpz_cmp($prod, $B) > 0;
                search_class($t, Rmpz_init_set_ui(1), Rmpz_init_set_ui(1), $c, []);
            }

            # k divisible by p^e (Wieferich prime, e >= 2)
            my @combos = ([Rmpz_init_set_ui(1), Rmpz_init_set_ui(1), []]);
            for my $w (grep { $_->[3] == $t } @wf) {
                my ($p, $emax, $z) = @$w;
                my @new;
                for my $cb (@combos) {
                    for my $e (2 .. $emax) {
                        my $nm = Rmpz_init();
                        mpz_set_u64($nm, $p);
                        Rmpz_pow_ui($nm, $nm, $e);
                        Rmpz_mul($nm, $nm, $cb->[0]);
                        last if Rmpz_cmp($nm, $B) > 0;
                        my $nl = Rmpz_init();
                        mpz_set_u64($nl, $z);
                        Rmpz_lcm($nl, $nl, $cb->[1]);
                        push @new, [$nm, $nl, [@{$cb->[2]}, $p]];
                    }
                }
                push @combos, @new;
            }
            shift @combos;
            for my $cb (@combos) {
                my ($m0, $L0, $bp) = @$cb;
                if (Rmpz_cmp($m0, $A) >= 0 && Rmpz_cmp($m0, $B) <= 0 && final_check($m0, $bp)) {
                    @stack = @$bp;
                    record($m0);
                }
                for my $c (1 .. 200) {
                    my $prod = Rmpz_init_set($m0);
                    for my $j (0 .. $c - 1) {
                        mpz_mul_u64($prod, $prod, $j < @$P ? $P->[$j] : $have_X + 1);
                    }
                    last if Rmpz_cmp($prod, $B) > 0;
                    search_class($t, $m0, $L0, $c, $bp);
                }
            }
        }
    }

    # ------------------------------------------------------------------
    # doubling windows
    # ------------------------------------------------------------------
    my $pmin  = $q == 2 ? 3 : $q + 2;
    my $lower = Rmpz_init();
    mpz_set_u64($lower, $pmin);
    Rmpz_mul($lower, $lower, $lower);

    my $upper = Rmpz_init();
    Rmpz_mul_2exp($upper, $lower, 2);

    if ($collect) {
        die "--all needs --upper\n" if !defined $upper_cap;
        if (defined $opt{lower}) {
            my $l = z_dec($opt{lower});
            Rmpz_set($lower, $l) if Rmpz_cmp($l, $lower) > 0;
        }
        Rmpz_set($A, $lower);
        Rmpz_set($B, $upper_cap);
        search_window() if Rmpz_cmp($A, $B) <= 0;
        my %seen;
        my @u = sort { length($a) <=> length($b) || $a cmp $b } grep { !$seen{$_}++ } @found;
        warn "WARNING: duplicates found\n" if @u != @found;
        printf STDERR "a(%d) all: %d solutions, %.3f s\n", $n, scalar(@u), time() - $started if $verbose;
        return \@u;
    }

    while (1) {
        Rmpz_set($A, $lower);
        Rmpz_set($B, $upper);
        Rmpz_set($B, $upper_cap) if defined($upper_cap) && Rmpz_cmp($B, $upper_cap) > 0;
        $have_best = 0;

        search_window() if Rmpz_cmp($A, $B) <= 0;

        if ($have_best) {
            printf STDERR "a(%d): q=%d, found in %.3f s (nodes=%d, walks=%d, candidates=%d, forced=%d, factorizations=%d, good primes <= %d)\n",
              $n, $q, time() - $started, $visited, $walks, $cands, $forced, $facts, $have_X
              if $verbose;
            return z_str($best);
        }
        return undef if defined($upper_cap) && Rmpz_cmp($upper, $upper_cap) >= 0;

        Rmpz_add_ui($lower, $upper, 1);
        Rmpz_mul_2exp($upper, $upper, 1);
    }
}

# ---------------------------------------------------------------------------
# command line
# ---------------------------------------------------------------------------

my %o = (force_count => 16, force_ratio => 0.5, force_bits => 64, wheel_count => 400_000);
my ($verbose, $help) = (0, 0);

GetOptions(
           'upper=s'       => \$o{upper},
           'lower=s'       => \$o{lower},
           'all!'          => \$o{all},
           'force-count=i' => \$o{force_count},
           'force-ratio=f' => \$o{force_ratio},
           'force-bits=i'  => \$o{force_bits},
           'wheel-count=i' => \$o{wheel_count},
           'verbose!'      => \$verbose,
           'help|h'        => \$help,
          )
  or die "Try --help\n";

if ($help) {
    print "Usage: $0 [--upper=N] [--verbose] [--force-count=N] [--force-ratio=X] [--force-bits=N] [--wheel-count=N] [n ...]\n";
    exit 0;
}
$o{verbose} = $verbose;

my @ns = @ARGV ? @ARGV : (1 .. 13);
for my $n (@ns) {
    my $r = nonresidue_psp($n, %o);
    if (ref $r) { say "a($n) solutions in [", ($o{lower} // 1), ", $o{upper}]: ", join(', ', @$r); next }
    say defined($r) ? "a($n) = $r" : "a($n) > $o{upper}";
}
