#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 28 October 2015
# Website: https://github.com/trizen

# Count how many times an even number can be written as the sum of two or more sub-primes

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

use ntheory qw(primes);
use Memoize qw(memoize);

my $limit = 1000;
my $primes = primes(0, $limit);

my %primes;
@primes{@{$primes}} = ();

sub sum_prime {
    my ($n) = @_;

    my $sum = 0;
    foreach my $prime (@{$primes}) {
        last if ($prime > ($n / 2));
        my $diff = $n - $prime;
        if (exists $primes{$diff}) {
            $sum += 1 + sum_prime($diff);
        }
    }

    $sum;
}

memoize('sum_prime');     # cache the function to improve performance

for (my $i = 2 ; $i <= $limit ; $i += 2) {
    say "$i\t", sum_prime($i);
}
