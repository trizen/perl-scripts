#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 September 2022
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [A,B], using a given list of prime factors. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);
use List::Util   qw(uniq);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub carmichael_numbers_in_range ($A, $B, $k, $primes, $callback) {

    $A = vecmax($A, pn_primorial($k));

    # Largest possisble prime factor for Carmichael numbers <= B
    my $max_p = (1 + sqrtint(8*$B + 1))>>2;

    my @P   = sort { $a <=> $b } grep { $_ <= $max_p } uniq(@$primes);
    my $end = $#P;

    sub ($m, $lambda, $j, $k) {

        my $y = vecmin($max_p, rootint(divint($B, $m), $k));

        if ($k == 1) {

            my $x = divceil($A, $m);

            if ($P[-1] < $x) {
                return;
            }

            foreach my $i ($j .. $end) {
                my $p = $P[$i];

                last if ($p > $y);
                next if ($p < $x);

                my $t = $m * $p;

                if (($t - 1) % $lambda == 0 and ($t - 1) % ($p - 1) == 0) {
                    $callback->($t);
                }
            }

            return;
        }

        foreach my $i ($j .. $end) {
            my $p = $P[$i];
            last if ($p > $y);

            gcd($m, $p - 1) == 1 or next;

            # gcd($m*$p, euler_phi($m*$p)) == 1 or die "$m*$p: not cyclic";

            __SUB__->($m * $p, lcm($lambda, $p - 1), $i + 1, $k - 1);
        }
      }
      ->(1, 1, 0, $k);
}

my $lambda = 5040;
my @primes = grep { $_ > 2 and $lambda % $_ != 0 and is_prime($_) } map { $_ + 1 } divisors($lambda);

foreach my $k (3 .. 6) {
    my @arr;
    carmichael_numbers_in_range(1, 10**(2 * $k), $k, \@primes, sub ($n) { push @arr, $n });
    say "$k: ", join(', ', sort { $a <=> $b } @arr);
}

__END__
3: 29341, 115921, 399001, 488881
4: 75361, 552721, 852841, 1569457, 3146221, 5310721, 8927101, 12262321, 27402481, 29020321, 49333201, 80282161
5: 10877581, 18162001, 67994641, 75151441, 76595761, 129255841, 133205761, 140241361, 169570801, 311388337, 461854261, 548871961, 561777121, 568227241, 577240273, 609865201, 631071001, 765245881, 839275921, 1583582113, 2178944461, 2443829641, 2811315361, 3240392401, 3245477761, 3246238801, 3630291841, 4684846321, 4885398001, 5961977281, 6030849889, 7261390081, 7906474801, 9722094481, 9825933601
6: 496050841, 832060801, 868234081, 1256855041, 1676641681, 1698623641, 1705470481, 1932608161, 2029554241, 2111416021, 3722793481, 4579461601, 5507520481, 5990940901, 7192589041, 7368233041, 8221139641, 13907587681, 16596266401, 19167739921, 22374999361, 23796818641, 29397916801, 33643718641, 41778063601, 42108575041, 47090317681, 48537130321, 53365160521, 54173581561, 57627937081, 57840264721, 60769467361, 66940720561, 74382893761, 74513421361, 77005913041, 77494371361, 84552825841, 88968511801, 94267516561, 97894836481, 107729884081, 112180797121, 114659813521, 126110113921, 126631194481, 131056332121, 142101232561, 152222039761, 167836660321, 169456971601, 171414489961, 174294847441, 187443219601, 193051454401, 207928264321, 225607349521, 237902646241, 244357656481, 297973194121, 314190832033, 329236460281, 330090228721, 335330503201, 494544949921, 507455393761, 582435435457, 638204086801, 639883767601, 643919472001, 672941621521, 725104658881, 810976375441, 866981525761
