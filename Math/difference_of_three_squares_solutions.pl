#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 August 2017
# Edit: 26 October 2017
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

use ntheory qw(divisors);

sub difference_of_three_squares_solutions {
    my ($n) = @_;

    my @divisors = divisors($n);

    my @solutions;
    foreach my $divisor (@divisors) {

        last if $divisor > sqrt($n);

        my $p = $divisor;
        my $q = $n / $divisor;
        my $k = $q + $p;

        ($k % 4 == 0) ? ($k >>= 2) : next;

        my $x1 = 3*$k - (($q - $p) >> 1);
        my $x2 = 3*$k + (($q - $p) >> 1);

        if (($x1 - 2*$k) > 0) {
            push @solutions, [$x1, $k];
        }

        if ($x1 != $x2) {
            push @solutions, [$x2, $k];
        }
    }

    return sort { $a->[0] <=> $b->[0] } @solutions;
}

my $n         = 900;
my @solutions = difference_of_three_squares_solutions($n);

foreach my $solution (@solutions) {

    my $x = $solution->[0];
    my $k = $solution->[1];

    say "[$x, $k] => $x^2 - ($x - $k)^2 - ($x - 2*$k)^2 = $n";
}

__END__
[35, 17] => 35^2 - (35 - 17)^2 - (35 - 2*17)^2 = 900
[45, 15] => 45^2 - (45 - 15)^2 - (45 - 2*15)^2 = 900
[67, 17] => 67^2 - (67 - 17)^2 - (67 - 2*17)^2 = 900
[115, 25] => 115^2 - (115 - 25)^2 - (115 - 2*25)^2 = 900
[189, 39] => 189^2 - (189 - 39)^2 - (189 - 2*39)^2 = 900
[563, 113] => 563^2 - (563 - 113)^2 - (563 - 2*113)^2 = 900
