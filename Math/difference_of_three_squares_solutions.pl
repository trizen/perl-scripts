#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 August 2017
# https://github.com/trizen

# An efficient algorithm for finding solutions to the equation:
#
#   x^2 - (x - a)^2 - (x - 2*a)^2 = n
#
# where only `n` is known.

# This algorithm uses the divisors of `n` to generate all the positive integer solutions.

# See also:
#   https://projecteuler.net/problem=135

use 5.010;
use strict;
use warnings;

use ntheory qw(divisors sqrtint);

sub difference_of_three_squares_solutions {
    my ($n) = @_;

    my @divisors = divisors($n);

    my @solutions;
    foreach my $divisor (@divisors) {

        last if $divisor > sqrt($n);

        my $p = $divisor;
        my $q = $n / $divisor;
        my $d = abs($p - $q);

        my $k = sqrtint($d**2 + 4*$n);

        ($k % 4 == 0) ? ($k >>= 2) : return ();

        my $x1 = 3*$k - sqrtint(4 * $k**2 - $n);
        my $x2 = 3*$k + sqrtint(4 * $k**2 - $n);

        if (($x1 - 2*$k) > 0) {
            push @solutions, [$x1, $k];
        }

        push @solutions, [$x2, $k];
    }

    return sort { $a->[0] <=> $b->[0] } @solutions;
}

my $n         = 1155;
my @solutions = difference_of_three_squares_solutions($n);

foreach my $solution (@solutions) {
    my $x = $solution->[0];
    my $k = $solution->[1];

    say "[$x, $k] => $x^2 - ($x - $k)^2 - ($x - 2*$k)^2 = $n";
}

__END__
[40, 19] => 40^2 - (40 - 19)^2 - (40 - 2*19)^2 = 1155
[50, 17] => 50^2 - (50 - 17)^2 - (50 - 2*17)^2 = 1155
[52, 17] => 52^2 - (52 - 17)^2 - (52 - 2*17)^2 = 1155
[74, 19] => 74^2 - (74 - 19)^2 - (74 - 2*19)^2 = 1155
[100, 23] => 100^2 - (100 - 23)^2 - (100 - 2*23)^2 = 1155
[134, 29] => 134^2 - (134 - 29)^2 - (134 - 2*29)^2 = 1155
[208, 43] => 208^2 - (208 - 43)^2 - (208 - 2*43)^2 = 1155
[290, 59] => 290^2 - (290 - 59)^2 - (290 - 2*59)^2 = 1155
[482, 97] => 482^2 - (482 - 97)^2 - (482 - 2*97)^2 = 1155
[1444, 289] => 1444^2 - (1444 - 289)^2 - (1444 - 2*289)^2 = 1155
