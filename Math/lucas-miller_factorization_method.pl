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
use ntheory qw(:all);
use experimental qw(signatures);

sub lucas_miller_factor ($n, $j = 1, $k = 100) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $D = $n + $j;
    my $s = valuation($D, 2);
    my $r = $s - 1;
    my $d = $D >> $s;

    foreach my $i (1 .. $k) {

        my $P = vecmin(1 + int(rand(1e6)), urandomm($n));
        my $Q = vecmin(1 + int(rand(1e6)), urandomm($n));

        $Q *= -1 if (rand(1) < 0.5);

        next if is_square($P * $P - 4 * $Q);

        foreach my $z (0 .. $r) {

            my ($U, $V) = lucas_sequence($n, $P, $Q, $d << $z);

            foreach my $g (gcd($U, $n), gcd($V, $n), gcd($V - $P, $n)) {
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
say lucas_miller_factor("122738580838512721992324860157572874494433031849", -1);
say lucas_miller_factor("181490268975016506576033519670430436718066889008242598463521");
say lucas_miller_factor("173315617708997561998574166143524347111328490824959334367069087");
say lucas_miller_factor("57981220983721718930050466285761618141354457135475808219583649146881");
say lucas_miller_factor("2425361208749736840354501506901183117777758034612345610725789878400467");
say lucas_miller_factor("131754870930495356465893439278330079857810087607720627102926770417203664110488210785830750894645370240615968198960237761");
