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

use Math::GMPz;
use ntheory qw(:all);
use experimental qw(signatures);

sub FastIntegerOutput ($A, $B) {

    $A = Math::GMPz->new("$A");

    # Find k such that B^(2k - 2) <= A < B^(2k)
    my $k = (logint($A, $B) >> 1) + 1;

    my $Q = Math::GMPz::Rmpz_init();
    my $R = Math::GMPz::Rmpz_init();

    sub ($A, $k) {

        if (Math::GMPz::Rmpz_cmp_ui($A, $B) < 0) {
            return Math::GMPz::Rmpz_get_ui($A);
        }

        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_pow_ui($t, $B, 2 * ($k - 1));   # can this be optimized away?

        if (Math::GMPz::Rmpz_cmp($t, $A) > 0) {
            --$k;
        }

        Math::GMPz::Rmpz_ui_pow_ui($t, $B, $k);
        Math::GMPz::Rmpz_divmod($Q, $R, $A, $t);

        my $w = ($k + 1) >> 1;
        Math::GMPz::Rmpz_set($t, $Q);

        my @right = __SUB__->($R, $w);
        my @left  = __SUB__->($t, $w);

        (@left, (0) x ($k - scalar(@right)), @right);
    }->($A, $k);
}

foreach my $B (2 .. 100) {    # run some tests
    my $N = factorial($B);    # int(rand(~0));

    my @a = todigits($N, $B);
    my @b = FastIntegerOutput($N, $B);

    if ("@a" ne "@b") {
        die "Error for FastIntegerOutput($N, $B): (@a) != (@b)";
    }
}

say join ', ', FastIntegerOutput(5040, 10);    #=> 5, 0, 4, 0
say join ', ', FastIntegerOutput(5040, 11);    #=> 3, 8, 7, 2
say join ', ', FastIntegerOutput(5040, 12);    #=> 2, 11, 0, 0
say join ', ', FastIntegerOutput(5040, 13);    #=> 2, 3, 10, 9
