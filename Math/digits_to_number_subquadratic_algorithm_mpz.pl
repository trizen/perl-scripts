#!/usr/bin/perl

# Subquadratic algorithm for converting a given list of digits in a given base, to an integer.

# Algorithm presented in the book:
#
#   Modern Computer Arithmetic
#           - by Richard P. Brent and Paul Zimmermann
#

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub FastIntegerInput ($digits, $base = 10) {

    my $L = [map { Math::GMPz->new("$_") } reverse @$digits];
    my $B = Math::GMPz->new("$base");

    # Subquadratic Algorithm 1.25 FastIntegerInput from "Modern Computer Arithmetic v0.5.9"
    for (my $k = scalar(@$L) ; $k > 1 ; $k = ($k >> 1) + ($k & 1)) {

        my @T;
        for (0 .. ($k >> 1) - 1) {
            my $t = Math::GMPz::Rmpz_init_set($L->[2 * $_]);
            Math::GMPz::Rmpz_addmul($t, $L->[2 * $_ + 1], $B);
            push(@T, $t);
        }

        push(@T, $L->[-1]) if ($k & 1);
        $L = \@T;
        Math::GMPz::Rmpz_mul($B, $B, $B);
    }

    return $L->[0];
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
