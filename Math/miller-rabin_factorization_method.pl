#!/usr/bin/perl

# Factorization method, based on the Miller-Rabin primality test.
# Described in the book "Elementary Number Theory", by Peter Hackman.

# Works best on Carmichael numbers.

# Example:
#   N   = 1729
#   N-1 = 2^6 * 27

# Then, we find that:
#       2^(2*27) == 1065 != -1 (mod N)
# and
#       2^(4*27) == 1 (mod N)

# This proves that N is composite and gives the following factorization:
#   x = 2^(2*27) (mod N)
#   N = gcd(x+1, N) * gcd(x-1, N)
#   N = gcd(1065+1, N) * gcd(1065-1, N)
#   N = 13 * 133

# See also:
#   https://www.math.waikato.ac.nz/~kab/509/bigbook.pdf
#   https://en.wikipedia.org/wiki/Miller-Rabin_primality_test

use 5.020;
use warnings;

use Math::GMPz;
use ntheory qw(valuation powmod gcd);
use experimental qw(signatures);

sub miller_rabin_factor ($n, $k = 100) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $D = $n - 1;
    my $s = valuation($D, 2);
    my $r = $s - 1;
    my $d = $D >> $s;

    return 1 if ($r <= 0);

    foreach my $a (2 .. $k) {
        my $x = powmod($a, $d, $n);
        next if (($x == 1) || ($x == $D));

        foreach my $k (1 .. $r) {
            my $y = powmod($x, 2, $n);

            if ($y == 1) {
                my $g = gcd($x + 1, $n);

                if ($g > 1 and $g < $n) {
                    return $g;
                }
            }

            $x = $y;
            last if ($x == $D);
        }
    }

    return 1;
}

say miller_rabin_factor("1729");
say miller_rabin_factor("335603208601");
say miller_rabin_factor("30459888232201");
say miller_rabin_factor("162021627721801");
say miller_rabin_factor("1372144392322327801");
say miller_rabin_factor("7520940423059310542039581");
say miller_rabin_factor("8325544586081174440728309072452661246289");
say miller_rabin_factor("181490268975016506576033519670430436718066889008242598463521");
say miller_rabin_factor("57981220983721718930050466285761618141354457135475808219583649146881");
say miller_rabin_factor("131754870930495356465893439278330079857810087607720627102926770417203664110488210785830750894645370240615968198960237761");
