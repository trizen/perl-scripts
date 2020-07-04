#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 October 2017
# https://github.com/trizen

# Find a solution to x^2 + y^2 = n, for numbers `n` whose prime divisors are
# all congruent to 1 mod 4, with the exception of at most a single factor of 2.

# Blog post:
#   https://trizenx.blogspot.com/2017/10/representing-integers-as-sum-of-two.html

# See also:
#   https://oeis.org/A008784

use 5.020;
use strict;
use warnings;

use ntheory qw(sqrtmod);
use experimental qw(signatures);

sub primitive_sum_of_two_squares ($p) {

    if ($p == 2) {
        return (1, 1);
    }

    my $s = sqrtmod($p - 1, $p) || return;
    my $q = $p;

    while ($s * $s > $p) {
        ($s, $q) = ($q % $s, $s);
    }

    return ($s, $q % $s);
}

foreach my $n (1 .. 100) {
    my ($x, $y) = primitive_sum_of_two_squares($n);

    if (defined($x) and defined($y)) {
        say "f($n) = $x^2 + $y^2";

        if ($n != $x**2 + $y**2) {
            die "error for $n";
        }
    }
}

__END__
f(2) = 1^2 + 1^2
f(5) = 2^2 + 1^2
f(10) = 3^2 + 1^2
f(13) = 3^2 + 2^2
f(17) = 4^2 + 1^2
f(25) = 4^2 + 3^2
f(26) = 5^2 + 1^2
f(29) = 5^2 + 2^2
f(34) = 5^2 + 3^2
f(37) = 6^2 + 1^2
f(41) = 5^2 + 4^2
f(50) = 7^2 + 1^2
f(53) = 7^2 + 2^2
f(58) = 7^2 + 3^2
f(61) = 6^2 + 5^2
f(65) = 8^2 + 1^2
f(73) = 8^2 + 3^2
f(74) = 7^2 + 5^2
f(82) = 9^2 + 1^2
f(85) = 7^2 + 6^2
f(89) = 8^2 + 5^2
f(97) = 9^2 + 4^2
