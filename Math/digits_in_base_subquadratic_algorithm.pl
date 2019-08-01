#!/usr/bin/perl

# Subquadratic algorithm for converting a given integer into a list of digits in a given base.

# Algorithm presented in the book:
#
#   Modern Computer Arithmetic
#           - by Richard P. Brent and Paul Zimmermann
#

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub FastIntegerOutput ($A, $B) {

    if ($A < $B) {
        return $A;
    }

    # Find k such that B^(2k - 2) <= A < B^(2k)
    my $k = (logint($A, $B) >> 1) + 1;

    my ($Q, $R) = divrem($A, powint($B, $k));
    my @r = __SUB__->($R, $B);

    (__SUB__->($Q, $B), (0) x ($k - scalar(@r)), @r);
}

foreach my $B (2 .. 100) {    # run some tests
    my $N = factorial($B);    # int(rand(~0));

    my @a = todigits($N, $B);
    my @b = FastIntegerOutput($N, $B);

    if ("@a" ne "@b") {
        die "Error for: FastIntegerOutput($N, $B)";
    }
}

say join ', ', FastIntegerOutput(5040, 10);    #=> 5, 0, 4, 0
say join ', ', FastIntegerOutput(5040, 11);    #=> 3, 8, 7, 2
say join ', ', FastIntegerOutput(5040, 12);    #=> 2, 11, 0, 0
say join ', ', FastIntegerOutput(5040, 13);    #=> 2, 3, 10, 9
