#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 July 2016
# Edit: 23 October 2017
# https://github.com/trizen

# Compute the inverse of n-factorial.
# The function is defined only for factorial numbers.
# It may return non-sense for non-factorials.

# See also:
#   https://oeis.org/A090368

use 5.010;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(valuation factor factorial);

sub factorial_prime_pow ($n, $p) {

    my $count = 0;
    my $ppow  = $p;

    while ($ppow <= $n) {
        $count += int($n / $ppow);
        $ppow *= $p;
    }

    return $count;
}

sub p_adic_inverse ($p, $k) {

    my $n = $k * ($p - 1);
    while (factorial_prime_pow($n, $p) < $k) {
        $n -= $n % $p;
        $n += $p;
    }

    return $n;
}

sub inverse_of_factorial ($f) {

    return 1 if $f == 1;

    my $t = valuation($f, 2);         # largest power of 2 in f
    my $z = p_adic_inverse(2, $t);    # smallest number z such that 2^t divides z!
    my $d = (factor($z + 1))[-1];     # largest factor of z+1

    if (valuation($f, $d) != factorial_prime_pow($z + 1, $d)) {
        return $z;
    }

    return $z + 1;
}

foreach my $n (1 .. 30) {

    my $f = factorial($n);
    my $i = inverse_of_factorial($f);

    say "$i! = $f";

    if ($i != $n) {
        die "error: $i != $n";
    }
}
