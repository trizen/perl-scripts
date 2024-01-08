#!/usr/bin/perl

# Find the least nonresidue of n.

# See also:
#   https://oeis.org/A020649 -- Least nonresidue of n.
#   https://oeis.org/A307809 -- Smallest "non-residue" pseudoprime to base prime(n).
#   https://mathworld.wolfram.com/QuadraticNonresidue.html

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub least_nonresidue_odd ($n) {    # for odd n

    my @factors = map { $_->[0] } factor_exp($n);

    for (my $p = 2 ; ; $p = next_prime($p)) {
        (vecall { kronecker($p, $_) == 1 } @factors) || return $p;
    }
}

sub least_nonresidue_sqrtmod ($n) {    # for any n
    for (my $p = 2 ; ; $p = next_prime($p)) {
        sqrtmod($p, $n) // return $p;
    }
}

my @tests = (
             3277,          3281,           121463,          491209,
             11530801,      512330281,      15656266201,     139309114031,
             7947339136801, 72054898434289, 334152420730129, 17676352761153241,
             172138573277896681
            );

say join ', ', map { least_nonresidue_odd($_) } @tests;        #=> 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41
say join ', ', map { least_nonresidue_sqrtmod($_) } @tests;    #=> 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41
