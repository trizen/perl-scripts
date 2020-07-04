#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 26 January 2019
# https://github.com/trizen

# Given a positive integer `n`, find the integer values `k` such that both `k-2*n` and `k+2*n` are squares.

# If `n = 4*x*y`, then `k = 4*(x^2 + y^2)`, with rational values x and y.

# For `n = 18`, we have the following solutions:
#   a(18) = [45, 85, 325]
#
# which produce the following squares:
#   45 + 2*18 =  9^2  ;  45 - 2*18 =  3^2
#   85 + 2*18 = 11^2  ;  85 - 2*18 =  7^2
#  325 + 2*18 = 19^2  ; 325 - 2*18 = 17^2

# See also:
#   https://oeis.org/A323728
#   https://en.wikipedia.org/wiki/Difference_of_two_squares

use 5.010;
use strict;
use warnings;

use ntheory qw(divisors sqrtint);
use Math::AnyNum qw(:overload min);

sub equally_spaced_squares {
    my ($n) = @_;

    my $limit = sqrtint($n);

    my @solutions;
    foreach my $d (divisors($n)) {

        last if $d > $limit;

        my $x = $d / 2;
        my $y = ($n / $d) / 2;

        unshift @solutions, 4 * ($x**2 + $y**2);
    }

    return @solutions;
}

foreach my $n (1 .. 20) {
    say "a($n) = [", join(", ", equally_spaced_squares($n)), "]";
}

say '';
say "A323728 = [", join(', ', map { min equally_spaced_squares($_) } 1 .. 100), ", ...]";

__END__
a(1) = [2]
a(2) = [5]
a(3) = [10]
a(4) = [8, 17]
a(5) = [26]
a(6) = [13, 37]
a(7) = [50]
a(8) = [20, 65]
a(9) = [18, 82]
a(10) = [29, 101]
a(11) = [122]
a(12) = [25, 40, 145]
a(13) = [170]
a(14) = [53, 197]
a(15) = [34, 226]
a(16) = [32, 68, 257]
a(17) = [290]
a(18) = [45, 85, 325]
a(19) = [362]
a(20) = [41, 104, 401]

A323728 = [2, 5, 10, 8, 26, 13, 50, 20, 18, 29, 122, 25, 170, 53, 34, 32, 290, 45, 362, 41, 58, 125, 530, 52, 50, 173, 90, 65, 842, 61, 962, 80, 130, 293, 74, 72, 1370, 365, 178, 89, 1682, 85, 1850, 137, 106, 533, 2210, 100, 98, 125, 298, 185, 2810, 117, 146, 113, 370, 845, 3482, 136, 3722, 965, 130, 128, 194, 157, 4490, 305, 538, 149, 5042, 145, 5330, 1373, 250, 377, 170, 205, 6242, 164, 162, 1685, 6890, 193, 314, 1853, 850, 185, 7922, 181, 218, 545, 970, 2213, 386, 208, 9410, 245, 202, 200, ...]
