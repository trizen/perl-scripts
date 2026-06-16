#!/usr/bin/perl

# Author: Daniel Șuteu
# Date: 16 June 2026
# https://github.com/trizen

# A sublinear algorithm for counting the number of primes <= n, using the inclusion-exclusion principle.

# Inspired by the Veritasium video:
#   https://youtube.com/watch?v=8HBDE-msUjw

# For example, prime_count(100) is computed as:
#   100 - ([100/2] + [100/3] + [100/5] + [100/7])
#       + ([100/(2*3)] + [100/(2*5)] + [100/(2*7)] + [100/(3*5)] + [100/(3*7)] + [100/(5*7)])
#       - ([100/(2*3*5)] + [100/(2*3*7)] + [100/(2*5*7)] + [100/(3*5*7)])
#       + ([100/(2*3*5*7)])
#       + 4 (numbers of primes <= sqrt(100))
#       - 1 (because 1 is not prime)

use 5.036;
use ntheory 0.74 qw(:all);

sub almost_primes_from_factors ($n, $k, $factors, $squarefree = 0) {

    my $factors_end = $#{$factors};

    if ($k == 0) {
        return [1];
    }

    if ($k == 1) {
        return $factors;
    }

    my @list;

    sub ($m, $k, $i = 0) {

        if ($k == 1) {

            my $L = divint($n, $m);

            foreach my $j ($i .. $factors_end) {
                my $q = $factors->[$j];
                last if ($q > $L);
                push(@list, mulint($m, $q));
            }

            return;
        }

        my $L = rootint(divint($n, $m), $k);

        foreach my $j ($i .. $factors_end) {
            my $q = $factors->[$j];
            last if ($q > $L);
            __SUB__->(mulint($m, $q), $k - 1, $j + $squarefree);
        }
      }
      ->(1, $k);

    \@list;
}

sub inclusion_exclusion_prime_count($n) {

    my $s      = sqrtint($n);
    my $count  = $n;
    my $primes = primes(2, $s);

    foreach my $k (1 .. exp(LambertW(log($n))) + 1) {
        my $Pk = almost_primes_from_factors($n, $k, $primes, 1);
        $count += (-1)**$k * vecsum(map { divint($n, $_) } @$Pk);
    }

    $count + scalar(@$primes) - 1;
}

foreach my $n (1 .. 1000) {
    inclusion_exclusion_prime_count($n) == prime_count($n)
      or die "error for n = $n";
}

foreach my $n (1 .. 7) {
    say "pi(10^$n) = ", inclusion_exclusion_prime_count(10**$n);
}
