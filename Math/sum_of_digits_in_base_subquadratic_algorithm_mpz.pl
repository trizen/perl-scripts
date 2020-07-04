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

use Math::GMPz;
use ntheory qw(:all);
use experimental qw(signatures);

sub FastSumOfDigits ($A, $B) {

    $A = Math::GMPz->new("$A");

    # Find k such that B^(2k - 2) <= A < B^(2k)
    my $k = (logint($A, $B) >> 1) + 1;

    my $Q = Math::GMPz::Rmpz_init();
    my $R = Math::GMPz::Rmpz_init();

    sub ($A, $k) {

        if (Math::GMPz::Rmpz_cmp_ui($A, $B) < 0) {
            return Math::GMPz::Rmpz_get_ui($A);
        }

        my $w = ($k + 1) >> 1;
        my $t = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_ui_pow_ui($t, $B, $k);
        Math::GMPz::Rmpz_divmod($Q, $R, $A, $t);
        Math::GMPz::Rmpz_set($t, $Q);

        __SUB__->($R, $w) + __SUB__->($t, $w);
    }->($A, $k);
}

foreach my $B (2 .. 300) {    # run some tests
    my $N = factorial($B);    # int(rand(~0));

    my $x = vecsum(todigits($N, $B));
    my $y = FastSumOfDigits($N, $B);

    if ($x != $y) {
        die "Error for FastSumOfDigits($N, $B): $x != $y";
    }
}

say join ', ', FastSumOfDigits(5040, 10);    #=> 9
say join ', ', FastSumOfDigits(5040, 11);    #=> 20
say join ', ', FastSumOfDigits(5040, 12);    #=> 13
say join ', ', FastSumOfDigits(5040, 13);    #=> 24
