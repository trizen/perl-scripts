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

    # Find k such that B^(2k - 2) <= A < B^(2k)
    my $k = (logint($A, $B) >> 1) + 1;

    sub ($A, $k) {

        if ($A < $B) {
            return $A;
        }

        my ($Q, $R) = divrem($A, powint($B, $k));
        my $t = ($k + 1) >> 1;

        vecsum(__SUB__->($Q, $t), __SUB__->($R, $t));
    }->($A, $k);
}

foreach my $B (2 .. 100) {    # run some tests
    my $N = factorial($B);    # int(rand(~0));

    my $x = vecsum(todigits($N, $B));
    my $y = FastSumOfDigits($N, $B);

    if ($x != $y) {
        die "Error for: FastSumOfDigits($N, $B)";
    }
}

say join ', ', FastSumOfDigits(5040, 10);    #=> 9
say join ', ', FastSumOfDigits(5040, 11);    #=> 20
say join ', ', FastSumOfDigits(5040, 12);    #=> 13
say join ', ', FastSumOfDigits(5040, 13);    #=> 24
