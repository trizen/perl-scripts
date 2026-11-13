#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 August 2022
# Edit: 13 November 2026
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [a,b].

use 5.036;
use ntheory 0.74 qw(:all);

sub carmichael_numbers_in_range ($A, $B, $k, $force_bits = 64, $force_count = 16) {

    $A = vecmax($A, pn_primorial($k + 1) >> 1);
    return if ($A > $B);

    # Largest possible prime factor for Carmichael numbers <= B
    my $max_p = (1 + sqrtint(8 * $B + 1)) >> 2;
    my $max_q = subint(powint(2, $force_bits), 1);

    my @list;

    # Verify a candidate cofactor q and test Korselt's criterion
    my $test_forced_product = sub ($m, $L, $q, $rem, $lo) {

        is_omega_prime($rem, $q) || return;

        my @fac = factor_exp($q);
        return if (@fac != $rem);
        return if $fac[0][0] < $lo;
        return if $fac[-1][0] > $max_p;

        my $full_L = $L;
        foreach my $pair (@fac) {
            my ($p, $e) = @$pair;
            return if ($e != 1);
            $full_L = lcm($full_L, $p - 1);
            return if ($full_L > $B - 1);
        }

        my $n = $m * $q;
        if ($n >= $A && $n <= $B && ($n - 1) % $full_L == 0) {
            push @list, $n;
        }
    };

    # Try to finish a subtree by directly factoring the remaining candidate cofactors
    my $try_forced_completion = sub ($m, $L, $lo, $rem) {
        return 0 if ($L <= 1);

        # Minimum product of `rem` distinct primes >= lo
        my $q_min = 1;
        my $p     = $lo - 1;
        for (1 .. $rem) {
            $p = next_prime($p);
            $q_min *= $p;
            return 1 if ($q_min > $B);
        }

        $q_min = vecmax($q_min, cdivint($A, $m));
        my $q_max = divint($B, $m);
        return 1 if ($q_min > $q_max);

        # Solve m * q == 1 (mod L)
        my $first = invmod($m, $L);
        return 1                                    if ($first > $q_max);
        $first += $L * cdivint($q_min - $first, $L) if ($first < $q_min);
        return 1                                    if ($first > $q_max);

        # Only factor directly if q fits in `force_bits` and there are <= `force_count` candidates
        return 0 if ($q_max > $max_q);
        return 0 if (divint($q_max - $first, $L) >= $force_count);

        for (my $q = $first ; $q <= $q_max ; $q += $L) {
            $test_forced_product->($m, $L, $q, $rem, $lo);
        }

        return 1;
    };

    sub ($m, $L, $lo, $k) {

        my $hi = rootint(divint($B, $m), $k);
        $lo > $hi && return;

        # Pinch's bound for the second to last prime
        if ($k == 2 and $m < 1_000) {
            my $bound = 2 * $m * $m - 3 * $m + 2;
            if ($hi > $bound) {
                $hi = $bound;
                $lo > $hi && return;
            }
        }

        if ($k == 1) {

            $hi = $m     if ($m < $hi);       # the last prime p_k must be <= m
            $hi = $max_p if ($max_p < $hi);
            $lo = vecmax($lo, cdivint($A, $m));
            $lo > $hi && return;

            my $inv_m = invmod($m, $L);
            $inv_m > $hi && return;

            my $t = $inv_m;
            $t += $L * cdivint($lo - $t, $L) if ($t < $lo);
            $t > $hi && return;

            if (divint($hi - $t, $L) < 100) {

                # Approach 1: Fast linear scan for small search spaces
                for (my $p = $t ; $p <= $hi ; $p += $L) {
                    if (($m - 1) % ($p - 1) == 0 and is_prime($p)) {
                        push @list, $m * $p;
                    }
                }
            }
            else {
                # Approach 2: Combinatorial divisor extraction for large spaces
                foreach my $d (divisors($m - 1, $hi)) {
                    my $p = $d + 1;

                    next if $p < $lo;
                    last if $p > $hi;

                    # Only check the congruence and primality
                    if ($p % $L == $inv_m and is_prime($p)) {
                        push @list, $m * $p;
                    }
                }
            }

            return;
        }

        # Attempt direct cofactor factorization shortcut before generating primes
        return if $try_forced_completion->($m, $L, $lo, $k);

        foreach my $p (@{primes($lo, $hi)}) {
            if (gcd($m, $p >> 1) == 1) {
                __SUB__->($m * $p, lcm($L, $p - 1), $p + 1, $k - 1);
            }
        }
      }
      ->(1, 1, 3, $k);

    return sort { $a <=> $b } @list;
}

my $from = 1;
my $upto = powint(10, 12);

foreach my $k (3 .. 7) {
    my @arr = carmichael_numbers_in_range($from, $upto, $k);
    say "There are: ", scalar(@arr), " Carmichael numbers <= $upto with $k prime factors";
}
