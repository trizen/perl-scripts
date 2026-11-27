#!/usr/bin/env perl

# Daniel "Trizen" Șuteu
# https://github.com/trizen

# Generate all Fermat pseudoprimes to base b >= 2 with exactly k >= 1
# distinct prime factors in the inclusive range [lo, hi]:
#
#   n = p_1^e_1 * ... * p_k^e_k  (composite, distinct primes, omega(n) = k)
#   with  b^(n - 1) == 1 (mod n).
#
# Usage:
#   perl fermat_psp_in_range.pl [options] lo hi k [base]
#
# As a library:
#   my $list = generate_fermat_pseudoprimes($lo, $hi, $k, $base, %opts);
#
# Options:
#   --force-bits=N    Factor cofactors only when q_max has at most N bits
#                     (default: 64; 0 disables forced completion)
#   --force-count=N   Always factor directly when at most N candidates remain
#                     (default: 16; 0 disables forced completion)
#   --force-ratio=X   Also factor directly when candidates <= X * estimated loop
#                     size (default: 0.75; 0 = use only --force-count)
#   --step-div=N      Factor b^(m - 1) - 1 directly when the terminal progression
#                     has at least N steps and fits in 128 bits (default: 64; 0 disables)
#   --verbose         Print search statistics to STDERR
#   --help            Show this help
#
# Requires Math::Prime::Util >= 0.74 and Math::GMPz.

use v5.36;
use strict;
use warnings;
no warnings 'recursion';

use Getopt::Long qw(GetOptions);
use Time::HiRes  qw(time);

use Math::GMPz qw(:mpz);
use Math::Prime::Util 0.74 qw(:all);

# ---------------------------------------------------------------------------
# Small GMP helpers
# ---------------------------------------------------------------------------

sub z_from_dec ($value) {
    my $z = Rmpz_init();
    Rmpz_set_str($z, "$value", 10);
    return $z;
}

sub z_to_str ($z) {
    return Rmpz_get_str($z, 10);
}

sub parse_uint ($name, $value) {
    die "$name must be a non-negative integer\n"
      if !defined($value) || "$value" !~ /\A\d+\z/;

    my $z = z_from_dec($value);
    die "$name is too large for a native unsigned integer\n"
      if !Rmpz_fits_ulong_p($z);

    return Rmpz_get_ui($z);
}

sub is_prime_mpz ($z) {
    return is_prime(Rmpz_fits_ulong_p($z) ? Rmpz_get_ui($z) : z_to_str($z));
}

# ---------------------------------------------------------------------------
# Generate all k-omega Fermat pseudoprimes to base b in [lo_in, hi_in].
# ---------------------------------------------------------------------------

sub generate_fermat_pseudoprimes ($lo_in, $hi_in, $k_in, $base_in = 2, %opt) {

    die "lo must be a decimal integer\n" if !defined($lo_in)   || "$lo_in"   !~ /\A[+-]?\d+\z/;
    die "hi must be a decimal integer\n" if !defined($hi_in)   || "$hi_in"   !~ /\A[+-]?\d+\z/;
    die "k must be an integer >= 1\n"    if !defined($k_in)    || "$k_in"    !~ /\A\d+\z/;
    die "base must be an integer >= 2\n" if !defined($base_in) || "$base_in" !~ /\A[+-]?\d+\z/;

    my $k = parse_uint('k', $k_in);
    die "k must be an integer >= 1\n" if $k < 1;

    my $force_bits  = parse_uint('--force-bits',  $opt{force_bits}  // 64);
    my $force_count = parse_uint('--force-count', $opt{force_count} // 16);
    my $step_div    = parse_uint('--step-div',    $opt{step_div}    // 64);
    my $force_ratio = $opt{force_ratio} // 0.75;
    my $verbose     = $opt{verbose}     // 0;

    die "--force-ratio must be a non-negative number\n"
      if $force_ratio !~ /\A\d+(?:\.\d+)?\z/;

    my $started = time();

    (my $lo_str   = "$lo_in")   =~ s/\A\+//;
    (my $hi_str   = "$hi_in")   =~ s/\A\+//;
    (my $base_str = "$base_in") =~ s/\A\+//;

    my $lo     = z_from_dec($lo_str);
    my $hi     = z_from_dec($hi_str);
    my $base_z = z_from_dec($base_str);

    die "base must be an integer >= 2\n" if Rmpz_cmp_ui($base_z, 2) < 0;

    my @results;
    return \@results if Rmpz_cmp($lo, $hi) > 0 || Rmpz_cmp_ui($hi, 4) < 0;

    my $base_is_odd = Rmpz_tstbit($base_z, 0)    ? 1                    : 0;
    my $base_fits   = Rmpz_fits_ulong_p($base_z) ? 1                    : 0;
    my $base_ui     = $base_fits                 ? Rmpz_get_ui($base_z) : 0;
    my $base_log2 =
      $base_fits
      ? log($base_ui) / log(2)
      : Rmpz_sizeinbase($base_z, 2) - 1;

    my $force_ok = ($force_bits > 0 && $force_count > 0) ? 1 : 0;
    my $NULL     = $Math::GMPz::NULL;

    # Primes coprime to base, their multiplicative orders ord_p(base), and
    # Wieferich primes [p, max_exp, ord_p(base)] where base^ord_p(base) == 1 (mod p^max_exp).
    my (@all_primes, @all_orders, @wieferich_primes);
    my $sieved_upto = 1;

    # Statistics
    my ($visited_nodes, $tail_nodes, $tail_primes, $forced_nodes, $factorizations, $terminal_hits) = (0) x 6;

    # Shared scratch registers (never passed as arguments to helpers that mutate them)
    my ($tmp, $tmp2, $first_q, $cand_q, $cand_n, $cand_n_minus_1, $rem_z)          = map { Rmpz_init() } 1 .. 7;
    my ($req_min_q, $req_max_q)                                                    = map { Rmpz_init() } 1 .. 2;
    my ($tail_m, $tail_lcm, $tail_m_minus_1, $tail_hi, $tail_lo, $tail_res, $step) = map { Rmpz_init() } 1 .. 7;

    # ---- helpers --------------------------------------------------------------

    # Largest e >= 1 with base^z == 1 (mod p^e), where z = ord_p(base).
    # For odd base and p = 2 (z = 1), this equals v_2(base - 1).
    my sub wieferich_max_exp ($p, $z) {

        if ($p <= 65535) {    # p^2 fits in 32-bit unsigned long on all platforms
            my $p2 = $p * $p;
            return 1 if powmod(Rmpz_fdiv_ui($base_z, $p2), $z, $p2) != 1;
        }

        my $pe  = Rmpz_init_set_ui($p);
        my $z_z = Rmpz_init_set_ui($z);
        my $rem = Rmpz_init();
        my $exp = 1;

        while (1) {
            Rmpz_mul_ui($pe, $pe, $p);
            Rmpz_powm($rem, $base_z, $z_z, $pe);
            last if Rmpz_cmp_ui($rem, 1) != 0;
            ++$exp;
        }

        return $exp;
    }

    my sub extend_prime_tables ($limit) {
        return if $limit <= $sieved_upto;

        foreach my $p (@{primes($sieved_upto + 1, $limit)}) {
            next if Rmpz_divisible_ui_p($base_z, $p);    # gcd(n, base) must be 1
            my $z = znorder(Rmpz_fdiv_ui($base_z, $p), $p);
            next if Rmpz_cmp_ui($hi, $z) <= 0;           # ord_p(base) | (n - 1) => z < hi
            push @all_primes, $p;
            push @all_orders, $z;
            my $max_exp = wieferich_max_exp($p, $z);
            push @wieferich_primes, [$p, $max_exp, $z] if $max_exp > 1;
        }

        $sieved_upto = $limit;
    }

    # Build prefix[j] = mbase * (product of the j smallest primes coprime to mbase * L0 * base)
    my sub build_prefixes ($mbase, $L0, $count) {
        my @prefix = (Rmpz_init_set($mbase));
        my $p      = 1;
        for my $j (1 .. $count) {
            do {
                $p = next_prime($p);
            } while (   Rmpz_divisible_ui_p($base_z, $p)
                       || Rmpz_divisible_ui_p($mbase, $p)
                       || Rmpz_divisible_ui_p($L0,    $p));
            my $prod = Rmpz_init();
            Rmpz_mul_ui($prod, $prefix[$j - 1], $p);
            return if Rmpz_cmp($prod, $hi) > 0;
            push @prefix, $prod;
        }
        return \@prefix;
    }

    # Terminal prime finder for n = m2 * q where:
    #   q == m2^(-1) (mod L2),  base^(m2 - 1) == 1 (mod q),  min_q <= q <= max_q.
    # Note: $min_q and $max_q are read-only inputs and must never alias $tail_lo / $tail_hi.
    my sub scan_terminal_primes ($m2, $L2, $min_q, $max_q, $mbase, $m_nontrivial, $mbase_fits, $mbase_ui) {

        # Handle q = 2 separately when base is odd and m2 is odd (i.e. 2 does not divide m2)
        if ($base_is_odd && Rmpz_tstbit($m2, 0) && Rmpz_cmp_ui($min_q, 2) <= 0 && Rmpz_cmp_ui($max_q, 2) >= 0) {
            Rmpz_mul_2exp($cand_n, $m2, 1);
            Rmpz_sub_ui($cand_n_minus_1, $cand_n, 1);
            if (Rmpz_divisible_p($cand_n_minus_1, $L2)) {
                ++$terminal_hits;
                push @results, Rmpz_init_set($cand_n);
            }
        }

        # All remaining terminal primes q are odd (>= 3)
        Rmpz_set_ui($tail_lo, 3);
        Rmpz_set($tail_lo, $min_q) if Rmpz_cmp($min_q, $tail_lo) > 0;
        Rmpz_set($tail_hi, $max_q);
        return if Rmpz_cmp($tail_lo, $tail_hi) > 0;

        Rmpz_invert($tail_res, $m2, $L2) or return;

        # q is odd: if L2 is odd, force residue odd and advance by 2 * L2
        if (Rmpz_tstbit($L2, 0)) {
            Rmpz_add($tail_res, $tail_res, $L2) if !Rmpz_tstbit($tail_res, 0);
            Rmpz_mul_2exp($step, $L2, 1);
        }
        else {
            Rmpz_set($step, $L2);
        }

        if (Rmpz_cmp($tail_res, $tail_lo) < 0) {
            Rmpz_sub($tmp2, $tail_lo, $tail_res);
            Rmpz_cdiv_q($tmp2, $tmp2, $step);
            Rmpz_addmul($tail_res, $tmp2, $step);
        }
        return if Rmpz_cmp($tail_res, $tail_hi) > 0;

        Rmpz_sub_ui($tail_m_minus_1, $m2, 1);

        # Clamp upper bound using q | (base^(m2 - 1) - 1) when base^(m2 - 1) is small
        my $m2_fits  = Rmpz_fits_ulong_p($tail_m_minus_1);
        my $m2m1_ui  = $m2_fits ? Rmpz_get_ui($tail_m_minus_1) : 0;
        my $bits_est = $m2_fits ? ($m2m1_ui * $base_log2)      : 1e9;
        my $hi_bits  = Rmpz_sizeinbase($tail_hi, 2);

        if ($m2_fits && $bits_est <= $hi_bits + 1) {
            Rmpz_pow_ui($tmp2, $base_z, $m2m1_ui);
            Rmpz_sub_ui($tmp2, $tmp2, 1);
            if (Rmpz_cmp($tmp2, $tail_hi) < 0) {
                Rmpz_set($tail_hi, $tmp2);
                return if Rmpz_cmp($tail_res, $tail_hi) > 0;
            }
        }

        # Single candidate in [tail_lo, tail_hi]: test directly without looping
        Rmpz_add($tmp2, $tail_res, $step);
        if (Rmpz_cmp($tmp2, $tail_hi) > 0) {
            return if Rmpz_divisible_p($base_z, $tail_res);
            return if $m_nontrivial && Rmpz_divisible_p($mbase, $tail_res);
            Rmpz_powm($rem_z, $base_z, $tail_m_minus_1, $tail_res);
            if (Rmpz_cmp_ui($rem_z, 1) == 0 && is_prime_mpz($tail_res)) {
                ++$terminal_hits;
                Rmpz_mul($cand_n, $m2, $tail_res);
                push @results, Rmpz_init_set($cand_n);
            }
            return;
        }

        Rmpz_sub($tmp2, $tail_hi, $tail_res);
        Rmpz_fdiv_q($tmp2, $tmp2, $step);

        # Many progression steps and base^(m2 - 1) - 1 <= 128 bits: factor it directly
        if (   $step_div > 0
            && $bits_est <= 128
            && Rmpz_fits_ulong_p($tmp2)
            && Rmpz_get_ui($tmp2) >= $step_div) {

            Rmpz_pow_ui($tmp2, $base_z, $m2m1_ui);
            Rmpz_sub_ui($tmp2, $tmp2, 1);
            my $val_str = Rmpz_fits_ulong_p($tmp2) ? Rmpz_get_ui($tmp2) : z_to_str($tmp2);

            my $prev_q = '';
            foreach my $q (factor($val_str)) {
                next if "$q" eq $prev_q;
                $prev_q = "$q";
                Rmpz_set_str($cand_q, "$q", 10);
                next if Rmpz_cmp($cand_q, $tail_res) < 0;
                last if Rmpz_cmp($cand_q, $tail_hi) > 0;
                next if Rmpz_divisible_p($base_z, $cand_q);
                next if $m_nontrivial && Rmpz_divisible_p($mbase, $cand_q);

                Rmpz_sub($tmp2, $cand_q, $tail_res);
                if (Rmpz_divisible_p($tmp2, $step)) {
                    ++$terminal_hits;
                    Rmpz_mul($cand_n, $m2, $cand_q);
                    push @results, Rmpz_init_set($cand_n);
                }
            }
            return;
        }

        # Native 64-bit progression walk
        if ($m2_fits && Rmpz_fits_ulong_p($tail_hi) && Rmpz_fits_ulong_p($step)) {
            my $tn = Rmpz_get_ui($tail_res);
            my $hn = Rmpz_get_ui($tail_hi);
            my $sn = Rmpz_get_ui($step);
            for (; $tn <= $hn ; $tn += $sn) {
                next if $base_fits ? ($base_ui % $tn == 0) : Rmpz_divisible_ui_p($base_z, $tn);
                next if $m_nontrivial && ($mbase_fits ? ($mbase_ui % $tn == 0) : Rmpz_divisible_ui_p($mbase, $tn));
                if (powmod($base_fits ? $base_ui : Rmpz_fdiv_ui($base_z, $tn), $m2m1_ui, $tn) == 1 && is_prime($tn)) {
                    ++$terminal_hits;
                    Rmpz_mul_ui($cand_n, $m2, $tn);
                    push @results, Rmpz_init_set($cand_n);
                }
            }
            return;
        }

        # Arbitrary-precision GMP progression walk
        while (Rmpz_cmp($tail_res, $tail_hi) <= 0) {
            if (!Rmpz_divisible_p($base_z, $tail_res) && !($m_nontrivial && Rmpz_divisible_p($mbase, $tail_res))) {
                Rmpz_powm($rem_z, $base_z, $tail_m_minus_1, $tail_res);
                if (Rmpz_cmp_ui($rem_z, 1) == 0 && is_prime_mpz($tail_res)) {
                    ++$terminal_hits;
                    Rmpz_mul($cand_n, $m2, $tail_res);
                    push @results, Rmpz_init_set($cand_n);
                }
            }
            Rmpz_add($tail_res, $tail_res, $step);
        }
    }

    # ---- search numbers n = mbase * q in [lo, hi], where mbase = prod w^e ------
    # (r distinct Wieferich primes) and q is a squarefree product of c = k - r
    # primes coprime to mbase * L0 * base.

    my sub search_combo ($mbase, $L0, $r) {

        my $c = $k - $r;
        return if $c < 0 || Rmpz_cmp($mbase, $hi) > 0;

        Rmpz_gcd($tmp, $mbase, $L0);
        return if Rmpz_cmp_ui($tmp, 1) != 0;

        my $m_nontrivial = (Rmpz_cmp_ui($mbase, 1) > 0) ? 1                   : 0;
        my $mbase_fits   = Rmpz_fits_ulong_p($mbase)    ? 1                   : 0;
        my $mbase_ui     = $mbase_fits                  ? Rmpz_get_ui($mbase) : 0;

        # Case c = 0: all k prime factors are Wieferich prime powers (composite since r >= 1)
        if ($c == 0) {
            return if $r == 0 || Rmpz_cmp($mbase, $lo) < 0;
            Rmpz_sub_ui($cand_n_minus_1, $mbase, 1);
            if (Rmpz_divisible_p($cand_n_minus_1, $L0)) {
                push @results, Rmpz_init_set($mbase);
            }
            return;
        }

        my $prefix = build_prefixes($mbase, $L0, $c) or return;

        my $eff_lo     = Rmpz_init_set($lo);
        my $lo_matters = (Rmpz_cmp($eff_lo, $prefix->[$c]) > 0) ? 1 : 0;
        Rmpz_set($eff_lo, $prefix->[$c]) if !$lo_matters;

        # Case c = 1: single squarefree prime factor q left (requires r >= 1 so n is composite)
        if ($c == 1) {
            return if $r == 0;
            Rmpz_cdiv_q($req_min_q, $eff_lo, $mbase);
            Rmpz_fdiv_q($req_max_q, $hi, $mbase);
            scan_terminal_primes($mbase, $L0, $req_min_q, $req_max_q, $mbase, $m_nontrivial, $mbase_fits, $mbase_ui);
            return;
        }

        # Case c >= 2: sieve up to the largest non-terminal prime bound
        my $sieve_limit = Rmpz_init_set_ui(3);
        for my $depth (0 .. $c - 2) {
            Rmpz_fdiv_q($tmp, $hi, $prefix->[$depth]);
            Rmpz_root($tmp, $tmp, $c - $depth);
            Rmpz_set($sieve_limit, $tmp) if Rmpz_cmp($tmp, $sieve_limit) > 0;
        }

        die "Range too large\n" if !Rmpz_fits_ulong_p($sieve_limit);
        my $sieve_max = Rmpz_get_ui($sieve_limit);
        extend_prime_tables($sieve_max);

        # Filter candidate primes for this combination; append sentinel at the end
        my (@primes, @orders);
        for my $idx (0 .. $#all_primes) {
            my $p = $all_primes[$idx];
            last if $p > $sieve_max;
            next if $m_nontrivial && (Rmpz_divisible_ui_p($mbase, $p) || Rmpz_divisible_ui_p($L0, $p));
            push @primes, $p;
            push @orders, $all_orders[$idx];
        }
        push @primes, $sieve_max + 1;
        push @orders, 1;

        # Per-depth state arrays
        my @prefix_prod  = map { Rmpz_init() } 0 .. $c;
        my @prefix_lcm   = map { Rmpz_init() } 0 .. $c;
        my @max_cofactor = map { Rmpz_init() } 0 .. $c;
        my @min_cofactor = map { Rmpz_init() } 0 .. $c;
        my @lo_cofactor  = map { Rmpz_init() } 0 .. $c;
        Rmpz_set($prefix_prod[0], $mbase);
        Rmpz_set($prefix_lcm[0],  $L0);

        # Depth-first search over remaining primes >= $primes[$i0]
        my $dfs = sub ($depth, $i0, $rem) {

            ++$visited_nodes;

            my $m    = $prefix_prod[$depth];
            my $L    = $prefix_lcm[$depth];
            my $qmax = $max_cofactor[$depth];
            my $qmin = $min_cofactor[$depth];
            my $lo_q = $lo_cofactor[$depth];

            Rmpz_fdiv_q($qmax, $hi, $m);

            my $p_min = $primes[$i0];
            Rmpz_root($tmp, $qmax, $rem);
            my $p_max = Rmpz_get_ui($tmp);
            return if $p_min > $p_max;

            # Lower bound on cofactor: product of the next $rem primes
            Rmpz_set_ui($qmin, $p_min);
            for my $offset (1 .. $rem - 1) {
                my $idx = $i0 + $offset;
                $idx = $#primes if $idx > $#primes;
                Rmpz_mul_ui($qmin, $qmin, $primes[$idx]);
            }
            return if Rmpz_cmp($qmin, $qmax) > 0;

            if ($lo_matters) {
                Rmpz_cdiv_q($lo_q, $eff_lo, $m);
                if (Rmpz_cmp($lo_q, $qmin) > 0) {
                    Rmpz_set($qmin, $lo_q);
                    return if Rmpz_cmp($qmin, $qmax) > 0;
                }
            }

            # ---- forced completion -------------------------------------------
            # Any completion n = m * q satisfies q == m^(-1) (mod L).
            if ($force_ok && Rmpz_cmp_ui($L, 1) > 0) {

                Rmpz_invert($first_q, $m, $L)
                  or die "Internal error: modular inverse does not exist\n";

                # If all remaining prime factors are odd (p_min >= 3), q must be odd
                if ($p_min >= 3 && Rmpz_tstbit($L, 0)) {
                    Rmpz_add($first_q, $first_q, $L) if !Rmpz_tstbit($first_q, 0);
                    Rmpz_mul_2exp($step, $L, 1);
                }
                else {
                    Rmpz_set($step, $L);
                }

                if (Rmpz_cmp($first_q, $qmin) < 0) {
                    Rmpz_sub($tmp, $qmin, $first_q);
                    Rmpz_cdiv_q($tmp, $tmp, $step);
                    Rmpz_addmul($first_q, $tmp, $step);
                }

                return if Rmpz_cmp($first_q, $qmax) > 0;

                Rmpz_sub($tmp, $qmax, $first_q);
                Rmpz_fdiv_q($tmp, $tmp, $step);

                if (Rmpz_fits_ulong_p($tmp) && Rmpz_sizeinbase($qmax, 2) <= $force_bits) {

                    my $candidates = Rmpz_get_ui($tmp) + 1;

                    my $threshold = $force_count;
                    if ($force_ratio > 0) {
                        my $est_primes =
                          $p_max > $p_min
                          ? ($p_max / log($p_max) - $p_min / log($p_min > 2 ? $p_min : 3))
                          : 1;
                        $est_primes = 1 if $est_primes < 1;
                        my $by_cost = $force_ratio * $est_primes;
                        $threshold = $by_cost if $by_cost > $threshold;
                    }

                    if ($candidates <= $threshold) {

                        ++$forced_nodes;
                        Rmpz_set($cand_q, $first_q);

                        while (Rmpz_cmp($cand_q, $qmax) <= 0) {
                            ++$factorizations;

                            my $q_val = Rmpz_fits_ulong_p($cand_q) ? Rmpz_get_ui($cand_q) : z_to_str($cand_q);

                            if (is_rough($q_val, $p_min) && is_almost_prime($rem, $q_val)) {
                                my @factors = factor_exp($q_val);
                                if (@factors == $rem && $factors[0][0] >= $p_min) {
                                    my $valid = 1;
                                    Rmpz_mul($cand_n, $m, $cand_q);
                                    Rmpz_sub_ui($cand_n_minus_1, $cand_n, 1);

                                    for my $pe (@factors) {
                                        my ($s, $e) = @$pe;
                                        if ($e != 1 || Rmpz_divisible_ui_p($base_z, $s)) {
                                            $valid = 0;
                                            last;
                                        }
                                        if ($m_nontrivial && Rmpz_divisible_ui_p($mbase, $s)) {
                                            $valid = 0;
                                            last;
                                        }
                                        Rmpz_set_str($tmp, "$s", 10);
                                        if (Rmpz_fits_ulong_p($tmp)) {
                                            my $s_ui = Rmpz_get_ui($tmp);
                                            if (powmod(Rmpz_fdiv_ui($base_z, $s_ui), Rmpz_fdiv_ui($cand_n_minus_1, $s_ui - 1), $s_ui) != 1) {
                                                $valid = 0;
                                                last;
                                            }
                                        }
                                        else {
                                            Rmpz_powm($rem_z, $base_z, $cand_n_minus_1, $tmp);
                                            if (Rmpz_cmp_ui($rem_z, 1) != 0) {
                                                $valid = 0;
                                                last;
                                            }
                                        }
                                    }

                                    push @results, Rmpz_init_set($cand_n) if $valid;
                                }
                            }
                            Rmpz_add($cand_q, $cand_q, $step);
                        }
                        return;
                    }
                }
            }

            my $m_fits = Rmpz_fits_ulong_p($m) ? 1               : 0;
            my $m_ui   = $m_fits               ? Rmpz_get_ui($m) : 0;

            # ---- general recursion (rem > 2) ---------------------------------
            if ($rem > 2) {

                my $next_m   = $prefix_prod[$depth + 1];
                my $next_lcm = $prefix_lcm[$depth + 1];

                for (my $i = $i0 ; ; ++$i) {
                    my $p = $primes[$i];
                    last if $p > $p_max;
                    my $z = $orders[$i];

                    # ord_p(base) must be coprime to m (a prime of m cannot divide both n and n-1)
                    if ($m_fits) {
                        next if gcd($m_ui, $z) != 1;
                    }
                    else {
                        next if Rmpz_gcd_ui($NULL, $m, $z) != 1;
                    }

                    Rmpz_lcm_ui($next_lcm, $L, $z);
                    next if Rmpz_cmp($next_lcm, $hi) >= 0;    # L | (n - 1) => L < n <= hi

                    Rmpz_mul_ui($next_m, $m, $p);
                    __SUB__->($depth + 1, $i + 1, $rem - 1);
                }

                return;
            }

            # ---- tail (rem == 2): loop over p_(k-1) and find terminal prime q ---
            ++$tail_nodes;

            my $i;
            for ($i = $i0 ; ; ++$i) {
                my $p = $primes[$i];
                last if $p > $p_max;
                my $z = $orders[$i];

                if ($m_fits) {
                    next if gcd($m_ui, $z) != 1;
                }
                else {
                    next if Rmpz_gcd_ui($NULL, $m, $z) != 1;
                }

                Rmpz_lcm_ui($tail_lcm, $L, $z);
                next if Rmpz_cmp($tail_lcm, $hi) >= 0;

                Rmpz_mul_ui($tail_m, $m, $p);

                # Fast filter: skip primes where m2^(-1) mod L2 does not exist or exceeds max_q
                Rmpz_invert($tail_res, $tail_m, $tail_lcm) or next;
                Rmpz_fdiv_q_ui($req_max_q, $qmax, $p);
                next if Rmpz_cmp($tail_res, $req_max_q) > 0;

                # Rare path: residue lies inside the window
                my $min_q = ($p == 2) ? 3 : $p + 2;
                Rmpz_set_ui($req_min_q, $min_q);
                if ($lo_matters) {
                    Rmpz_cdiv_q_ui($tmp, $lo_q, $p);
                    Rmpz_set($req_min_q, $tmp) if Rmpz_cmp($tmp, $req_min_q) > 0;
                }

                scan_terminal_primes($tail_m, $tail_lcm, $req_min_q, $req_max_q, $mbase, $m_nontrivial, $mbase_fits, $mbase_ui);
            }

            $tail_primes += $i - $i0;
            return;
        };

        $dfs->(0, 0, $c);
        return;
    }

    # ---- main driver: squarefree run + Wieferich prime-power combinations -------

    my $sqfree_prefix = build_prefixes(Rmpz_init_set_ui(1), Rmpz_init_set_ui(1), $k);
    return \@results if !$sqfree_prefix;

    # Largest possible Wieferich prime w satisfies w^2 * sqfree_prefix[k - 1] <= hi
    Rmpz_fdiv_q($tmp, $hi, $sqfree_prefix->[$k - 1]);
    Rmpz_sqrt($tmp, $tmp);
    die "Range too large\n" if !Rmpz_fits_ulong_p($tmp);
    extend_prime_tables(Rmpz_get_ui($tmp));

    # Build all valid combinations of Wieferich prime powers w^e (e >= 2)
    my @combos = ([Rmpz_init_set_ui(1), Rmpz_init_set_ui(1), 0]);

    foreach my $w (@wieferich_primes) {
        my ($p, $max_exp, $z) = @$w;
        my @added;
        foreach my $cb (@combos) {
            my ($m0, $l0, $r) = @$cb;
            next if $r + 1 > $k;
            for my $e (2 .. $max_exp) {
                my $next_m = Rmpz_init();
                Rmpz_ui_pow_ui($next_m, $p, $e);
                Rmpz_mul($next_m, $next_m, $m0);

                # Prune immediately if even the smallest possible completion exceeds hi
                Rmpz_mul($tmp, $next_m, $sqfree_prefix->[$k - ($r + 1)]);
                last if Rmpz_cmp($tmp, $hi) > 0;

                my $next_l = Rmpz_init_set_ui($z);
                Rmpz_lcm($next_l, $next_l, $l0);

                Rmpz_gcd($tmp, $next_m, $next_l);
                next if Rmpz_cmp_ui($tmp, 1) != 0;

                push @added, [$next_m, $next_l, $r + 1];
            }
        }
        push @combos, @added;
    }

    foreach my $cb (@combos) {
        search_combo(@$cb);
    }

    @results = sort { Rmpz_cmp($a, $b) } @results;

    if ($verbose) {
        my $elapsed = time() - $started;
        printf STDERR "base=%s, k=%d, sieve=%s, nodes=%d, tails=%d, tail_primes=%d, forced=%d, factorizations=%d, terminal=%d, results=%d, time=%.3f s\n",
          z_to_str($base_z), $k, $sieved_upto, $visited_nodes, $tail_nodes, $tail_primes,
          $forced_nodes, $factorizations, $terminal_hits, scalar(@results), $elapsed;
    }

    return \@results;
}

# ---------------------------------------------------------------------------
# Command-line interface and examples
# ---------------------------------------------------------------------------

sub usage ($status = 0) {
    my $fh = $status ? *STDERR : *STDOUT;
    print {$fh} <<'USAGE';
Usage:
  perl fermat_psp_in_range.pl [options] lo hi k [base]

Generate all Fermat pseudoprimes to base b >= 2 (default: 2) with exactly
k >= 1 distinct prime factors in the inclusive range [lo, hi].

Options:
  --force-bits=N    Maximum bit length for forced cofactor factoring (64)
  --force-count=N   Always factor directly when at most N candidates remain (16)
  --force-ratio=X   Also factor directly when candidates <= X * estimated loop
                    size (0.75; 0 = use only --force-count)
  --step-div=N      Factor b^(m - 1) - 1 directly when the terminal progression
                    has at least N steps and fits in 128 bits (64; 0 disables)
  --verbose         Print search statistics to STDERR
  --help            Show this help

With no positional arguments, run default verification examples.
A negative or "+"-prefixed lo must follow "--" (e.g.: ... -- -50 1000 2 2).
USAGE
    exit $status;
}

my $force_bits  = 64;
my $force_count = 16;
my $force_ratio = 0.75;
my $step_div    = 64;
my $verbose     = 0;
my $help        = 0;

GetOptions(
           'force-bits=s'  => \$force_bits,
           'force-count=s' => \$force_count,
           'force-ratio=s' => \$force_ratio,
           'step-div=s'    => \$step_div,
           'verbose!'      => \$verbose,
           'help|h'        => \$help,
          )
  or usage(2);

usage(0) if $help;

if (!@ARGV) {
    my $upto = powint(10, 8);
    for my $base (2, 3) {
        for my $k (1 .. 5) {
            my $list = generate_fermat_pseudoprimes(
                                                    1, $upto, $k, $base,
                                                    force_bits  => $force_bits,
                                                    force_count => $force_count,
                                                    force_ratio => $force_ratio,
                                                    step_div    => $step_div,
                                                    verbose     => $verbose,
                                                   );
            say "Base $base pseudoprimes <= $upto with $k prime factors: ", scalar(@$list);
        }
    }
}
else {
    usage(2) if @ARGV < 3 || @ARGV > 4;
    my ($lo, $hi, $k, $base) = (@ARGV, 2);
    my $list = generate_fermat_pseudoprimes(
                                            $lo, $hi, $k, $base,
                                            force_bits  => $force_bits,
                                            force_count => $force_count,
                                            force_ratio => $force_ratio,
                                            step_div    => $step_div,
                                            verbose     => $verbose,
                                           );
    say "$k-factor base-$base Fermat pseudoprimes in [$lo, $hi]:";
    say '[', join(', ', map { z_to_str($_) } @$list), ']';
}
