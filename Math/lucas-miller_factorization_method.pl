#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 07 January 2020
# https://github.com/trizen

# A simple factorization method, using the Lucas `U_n(P,Q)` sequences.
# Inspired by the Miller-Rabin factorization method.

# Works best on Lucas pseudoprimes.

# See also:
#   https://en.wikipedia.org/wiki/Lucas_pseudoprime
#   https://en.wikipedia.org/wiki/Miller-Rabin_primality_test

use 5.020;
use warnings;

use Math::GMPz;
use ntheory qw(valuation powmod gcd vecmin lucas_sequence urandomm);
use experimental qw(signatures);

sub lucas_miller_factor ($n, $k = 100) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $D = $n + 1;
    my $s = valuation($D, 2);
    my $r = $s - 1;
    my $d = $D >> $s;

    foreach my $P (1 .. $k) {

        my $Q = -vecmin(1+int(rand(1e6)), urandomm($n));

        foreach my $b (0 .. $r) {

            my ($U, $V) = lucas_sequence($n, $P, $Q, $d << $b);

            foreach my $g (gcd($U, $n), gcd($V, $n)) {
                if ($g > 1 and $g < $n) {
                    return $g;
                }
            }
        }
    }

    return 1;
}

say lucas_miller_factor("16641689036184776955112478816668559");
say lucas_miller_factor("17350074279723825442829581112345759");
say lucas_miller_factor("61881629277526932459093227009982733523969186747");
say lucas_miller_factor("173315617708997561998574166143524347111328490824959334367069087");
say lucas_miller_factor("2425361208749736840354501506901183117777758034612345610725789878400467");
