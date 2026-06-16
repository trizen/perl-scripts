#!/usr/bin/perl

# Author: Daniel Șuteu
# Date: 16 June 2026
# https://github.com/trizen

# A sublinear algorithm for counting the number of primes <= n, using the inclusion-exclusion principle.

# Inspired by the Veritasium video:
#   https://youtube.com/watch?v=8HBDE-msUjw

# Formula:
#    π(n) = n - Σ⌊n/p⌋ + Σ⌊n/(p·q)⌋ - ... + π(√n) - 1

use 5.036;
use ntheory 0.74 qw(:all);

sub almost_primes_from_factors_sum ($n, $primes, $k) {

    my @factors = @$primes;
    my $end     = $#factors;
    my $sum     = 0;

    sub ($m, $k, $i) {

        if ($k == 1) {
            for my $j ($i .. $end) {
                my $q = $factors[$j];
                last if $q > $m;
                $sum += divint($m, $q);
            }
            return;
        }

        my $L = rootint($m, $k);
        for my $j ($i .. $end) {
            my $q = $factors[$j];
            last if $q > $L;
            __SUB__->(divint($m, $q), $k - 1, $j + 1);
        }
      }
      ->($n, $k, 0);

    return $sum;
}

sub inclusion_exclusion_prime_count ($n) {

    my $s      = sqrtint($n);
    my $primes = primes(2, $s);

    my $count = $n + scalar(@$primes) - 1;    # n + pi(sqrt(n)) - 1

    for my $k (1 .. exp(LambertW(log($n))) + 1) {
        $count += (-1)**$k * almost_primes_from_factors_sum($n, $primes, $k);
    }

    $count;
}

# Correctness check
for my $n (1 .. 1000) {
    inclusion_exclusion_prime_count($n) == prime_count($n)
      or die "error for n = $n";
}

for my $n (1 .. 7) {
    say "pi(10^$n) = ", inclusion_exclusion_prime_count(10**$n);
}
