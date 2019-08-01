#!/usr/bin/perl

# Subquadratic algorithm for computing the sum of digits of a given integer in a given base.

# Based on the FastIntegerOutput algorithm presented in the book:
#
#   Modern Computer Arithmetic
#           - by Richard P. Brent and Paul Zimmermann
#

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub FastSumOfDigits ($A, $B) {

    if ($A < $B) {
        return $A;
    }

    # Find k such that B^(2k - 2) <= A < B^(2k)
    my $k = (logint($A, $B) >> 1) + 1;

    my ($Q, $R) = divrem($A, powint($B, $k));
    vecsum(__SUB__->($Q, $B), __SUB__->($R, $B));
}

foreach my $B (2 .. 100) {    # run some tests
    my $N = factorial($B);    # int(rand(~0));

    my $x = vecsum(todigits($N, $B));
    my $y = FastSumOfDigits($N, $B);

    if ($x != $y) {
        die "Error for: FastSumOfDigits($N, $B)";
    }
}

say join ', ', FastSumOfDigits(5040, 10);    #=> 5, 0, 4, 0
say join ', ', FastSumOfDigits(5040, 11);    #=> 3, 8, 7, 2
say join ', ', FastSumOfDigits(5040, 12);    #=> 2, 11, 0, 0
say join ', ', FastSumOfDigits(5040, 13);    #=> 2, 3, 10, 9
