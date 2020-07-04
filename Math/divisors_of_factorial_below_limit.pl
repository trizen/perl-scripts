#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 December 2018
# https://github.com/trizen

# Generate the divisors of n! below a given limit.

use 5.020;
use warnings;

use experimental qw(signatures);
use ntheory qw(primes todigits vecsum valuation factorial);

sub divisors_of_factorial ($f, $limit = factorial($f)) {

    my @primes = @{primes($f)};

    my @d = (1);
    foreach my $p (@primes) {

        # Maximum power of p in f!
        my $pow = ($f - vecsum(todigits($f, $p))) / ($p - 1);

        foreach my $n (@d) {
            if ($n * $p <= $limit) {
                last if (valuation($n, $p) >= $pow);
                push @d, $n * $p;
            }
        }
    }

    return \@d;
}

my $n     = 30;
my $limit = 10**12;

my $d = divisors_of_factorial($n, $limit);

printf "There are %s divisors of $n! below $limit\n", scalar(@$d);
printf "Sum of divisors of $n! below $limit = %s\n", vecsum(@$d);

__END__
There are 372197 divisors of 30! below 1000000000000
Sum of divisors of 30! below 1000000000000 = 53793088959503349
