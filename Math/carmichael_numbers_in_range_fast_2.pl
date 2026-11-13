#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 August 2022
# Edit: 13 November 2026
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [A,B]
# using modular progression stepping, suffix pruning, and forced cofactor factorization.

use 5.036;
use ntheory 0.74 qw(:all);

sub carmichael_numbers_in_range ($A, $B, $k, $force_bits = 64, $force_count = 16) {
    die "k must be an integer >= 3\n" if ($k < 3);

    return if ($A > $B);

    my $max_p = (1 + sqrtint(8 * $B + 1)) >> 2;
    my $max_q = subint(powint(2, $force_bits), 1);
    my @list;

    # First k odd primes give the absolute mathematical lower bound (3 * 5 * 7 * ...)
    my @first_primes = @{primes(3, nth_prime($k + 1))};

    my @prefix_product = (1);
    for my $i (1 .. $k) {
        $prefix_product[$i] = $prefix_product[$i - 1] * $first_primes[$i - 1];
    }

    my $lower = vecmax($A, $prefix_product[$k]);
    my $upper = $B;
    return if ($lower > $upper);

    my $upper_plus1 = $upper + 1;

    # Compute the global upper bound for every non-terminal prime loop
    my $sieve_limit = $first_primes[-1];
    for my $depth (0 .. $k - 2) {
        my $remaining = $k - $depth;
        my $limit     = rootint(divint($upper, $prefix_product[$depth]), $remaining);
        $sieve_limit = vecmax($sieve_limit, $limit);
    }

    # Extend sieve slightly beyond sieve_limit to guarantee suffix construction
    my $sieve_max = next_prime($sieve_limit);

    for (1 .. $k + 2) {
        $sieve_max = next_prime($sieve_max);
    }

    if ($sieve_max > $max_p) {
        $sieve_max = $max_p;
    }

    my @odd_primes   = @{primes(3, $sieve_max)};
    my $upper_minus1 = $B - 1;

    # Verify a candidate cofactor q and test Carmichael's criterion
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
            return if ($full_L > $upper_minus1);
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

        # Solve m * q == 1 (mod L) -> first residue
        my $first = invmod($m % $L, $L);
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

    # Recursive DFS search function with suffix pruning and forced completion
    sub ($m, $L, $prime_index, $remaining_k) {
        my $hi = rootint(divint($B, $m), $remaining_k);

        # Base case: find the final prime factor using modular progression stepping
        if ($remaining_k == 1) {
            $hi = $m     if ($m < $hi);
            $hi = $max_p if ($max_p < $hi);

            my $min_allowed = ($prime_index <= $#odd_primes) ? $odd_primes[$prime_index] : 3;
            my $p_min       = vecmax($min_allowed, cdivint($A, $m));
            return if ($p_min > $hi);

            # Solve m * p == 1 (mod L) -> p == m^(-1) (mod L)
            my $inv_m = invmod($m % $L, $L);
            return if ($inv_m > $hi);

            my $t = $inv_m;
            $t += $L * cdivint($p_min - $t, $L) if ($t < $p_min);
            return                              if ($t > $hi);

            if (divint($hi - $t, $L) < 100) {

                # Approach 1: Fast linear scan for small search spaces
                my $mm1 = $m - 1;
                for (my $p = $t ; $p <= $hi ; $p += $L) {
                    if ($mm1 % ($p - 1) == 0 and is_prime($p)) {
                        push @list, $m * $p;
                    }
                }
            }
            else {
                # Approach 2: Combinatorial divisor extraction for large spaces
                foreach my $d (divisors($m - 1, $hi - 1)) {
                    my $p = $d + 1;

                    next if $p < $p_min;
                    last if $p > $hi;

                    # Only check the congruence and primality
                    if ($p % $L == $inv_m and is_prime($p)) {
                        push @list, $m * $p;
                    }
                }
            }

            return;
        }

        # Minimum product bound: prune if remaining primes can't fit under $B
        return if ($prime_index + $remaining_k - 1 > $#odd_primes);

        my $q_min = 1;
        for my $i ($prime_index .. ($prime_index + $remaining_k - 1)) {
            $q_min *= $odd_primes[$i];
            return if ($q_min > divint($B, $m));
        }

        my $q_max = divint($B, $m);

        # Attempt direct cofactor factorization shortcut before branching further
        return if $try_forced_completion->($m, $L, $odd_primes[$prime_index], $remaining_k);

        # Recursive step with suffix pruning
        for my $i ($prime_index .. $#odd_primes) {
            my $p = $odd_primes[$i];
            last if ($p > $hi);

            my $p_minus1 = $p - 1;
            next if (gcd($m, $p_minus1) != 1);

            __SUB__->($m * $p, lcm($L, $p_minus1), $i + 1, $remaining_k - 1);
        }
      }
      ->(1, 1, 0, $k);

    return sort { $a <=> $b } @list;
}

sub A182490($n) {

    my $from  = powint(2, $n);
    my $upto  = powint(2, $n + 1);
    my $total = 0;

    for (my $k = 3 ; ; ++$k) {
        my @arr = carmichael_numbers_in_range($from, $upto, $k);
        $total += scalar(@arr) || last;
    }

    return $total;
}

local $| = 1;
foreach my $n (1 .. 37) {
    print(A182490($n), ", ");
}
