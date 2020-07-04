#!/usr/bin/perl

# Subquadratic algorithm for converting a given list of digits in a given base, to an integer.

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

sub FastIntegerInput ($digits, $B) {

    my @l = reverse @$digits;
    my ($b, $k) = ($B, scalar(@l));

    while ($k > 1) {
        my @T;
        for (1 ... (@l >> 1)) {
            push(@T, addint(shift(@l), mulint($b, shift(@l))));
        }
        push(@T, shift(@l)) if @l;
        @l = @T;
        $b = mulint($b, $b);
        $k = ($k >> 1) + ($k % 2);
    }

    $l[0];
}

foreach my $B (2 .. 100) {    # run some tests
    my $N = factorial($B);    # int(rand(~0));

    my @a = todigits($N, $B);
    my $K = FastIntegerInput(\@a, $B);

    if ($N != $K) {
        die "Error for N = $N -> got $K";
    }
}

say join ', ', FastIntegerInput([todigits(5040, 10)], 10);    #=> 5040
say join ', ', FastIntegerInput([todigits(5040, 11)], 11);    #=> 5040
say join ', ', FastIntegerInput([todigits(5040, 12)], 12);    #=> 5040
say join ', ', FastIntegerInput([todigits(5040, 13)], 13);    #=> 5040
