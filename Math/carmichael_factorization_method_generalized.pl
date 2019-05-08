#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 08 May 2019
# https://github.com/trizen

# A simple factorization method, using the binary search algorithm, for numbers of the form:
#
#   n = x * Prod_{k=1..r} ((x±1)*a_k ± 1)
#
# for `r` relatively small.

# Many Carmichael numbers and Lucas pseudoprimes are of this form and can be factorized relatively fast by this method.

# See also:
#   https://en.wikipedia.org/wiki/Binary_search_algorithm

use 5.024;
use warnings;
use experimental qw(signatures);
use ntheory qw(lastfor forcomb);
use Math::AnyNum qw(:overload bsearch_le iroot prod gcd);

sub carmichael_factorization ($n, $k = 3, $l = 2, $h = 6) {

    my @blocks = (
        sub ($x, @params) {
            map { ($x - 1) * $_ + 1 } @params;
        },
        sub ($x, @params) {
            map { ($x + 1) * $_ - 1 } @params;
        },
    );

    my @factors;
    my @range = ($l .. $h);

    forcomb {
        my @params = @range[@_];

        foreach my $block (@blocks) {

            my $r = bsearch_le(
                iroot($n, $k),
                sub ($x) {
                    (prod($block->($x, @params)) * $x) <=> $n;
                }
            );

            my $g = gcd($r, $n);

            if ($g > 1) {
                @factors = grep { $n % $_ == 0 } ($r, $block->($r, @params));
                lastfor, return @factors;
            }
        }
    } scalar(@range), $k - 1;

    return @factors;
}

#<<<
local $, = ", ";

say carmichael_factorization(7520940423059310542039581,                3);    #=> 79443853
say carmichael_factorization(570115866940668362539466801338334994649,  3);    #=> 4563211789627
say carmichael_factorization(8325544586081174440728309072452661246289, 3);    #=> 11153738721817

say '=' x 80;

say carmichael_factorization(60711773123792542753,                           4, 2,  10);    #=> 2597294701
say carmichael_factorization(73410179782535364796052059,                     2, 2,  18);    #=> 2141993519227
say carmichael_factorization(12946744736260953126701495197312513,            4, 2,  6);     #=> 37927921157953921

say '=' x 80;

say carmichael_factorization(1169586052690021349455126348204184925097724507,                  3, 11, 23);  #=> 166585508879747
say carmichael_factorization(61881629277526932459093227009982733523969186747,                 3, 3,  11);  #=> 1233150073853267
say carmichael_factorization(173315617708997561998574166143524347111328490824959334367069087, 3, 3,  11);  #=> 173823271649325368927

say '=' x 80;

# Works even with larger numbers
say carmichael_factorization(89279013890805987845789287109721287627454944588023686038653206281186298337098760877273881);                                      #=> 245960883729518060519840003581
say carmichael_factorization(131754870930495356465893439278330079857810087607720627102926770417203664110488210785830750894645370240615968198960237761, 4);    #=> 245960883729518060519840003581
#>>>
