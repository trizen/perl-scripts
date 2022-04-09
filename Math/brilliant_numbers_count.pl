#!/usr/bin/perl

# Count the number of Brilliant numbers < 10^n.

# Brilliant numbers are semiprimes such that both prime factors have the same number of digits in base 10.

# OEIS sequence:
#   https://oeis.org/A086846 --  Number of brilliant numbers < 10^n.

# See also:
#   https://rosettacode.org/wiki/Brilliant_numbers

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub brilliant_numbers_count ($n) {

    use integer;

    my $count = 0;
    my $len   = length(sqrtint($n));

    foreach my $k (1 .. $len - 1) {
        my $pi = prime_count(10**($k - 1), 10**$k - 1);
        $count += binomial($pi, 2) + $pi;
    }

    my $min = 10**($len - 1);
    my $max = 10**$len - 1;

    forprimes {
        $count += prime_count($_, vecmin($max, $n / $_));
    } $min, $max;

    return $count;
}

sub brilliant_numbers_count_slow ($n) {

    my $count = 0;
    my $len   = length(sqrtint($n));

    foreach my $k (1 .. $len - 1) {
        my $pi = prime_count(10**($k - 1), 10**$k - 1);
        $count += binomial($pi, 2) + $pi;
    }

    my $P = primes(10**($len - 1), 10**$len - 1);

    foreach my $i (0 .. $#{$P}) {
        foreach my $j ($i .. $#{$P}) {
            $P->[$i] * $P->[$j] > $n ? last : ++$count;
        }
    }

    return $count;
}

foreach my $n (1 .. 11) {
    my $v = vecprod((10) x $n) - 1;
    printf("Less than 10^%s, there are %s brilliant numbers\n", $n, brilliant_numbers_count($v));
}

__END__
Less than 10^1, there are 3 brilliant numbers
Less than 10^2, there are 10 brilliant numbers
Less than 10^3, there are 73 brilliant numbers
Less than 10^4, there are 241 brilliant numbers
Less than 10^5, there are 2504 brilliant numbers
Less than 10^6, there are 10537 brilliant numbers
Less than 10^7, there are 124363 brilliant numbers
Less than 10^8, there are 573928 brilliant numbers
Less than 10^9, there are 7407840 brilliant numbers
Less than 10^10, there are 35547994 brilliant numbers
Less than 10^11, there are 491316166 brilliant numbers
Less than 10^12, there are 2409600865 brilliant numbers
