#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 05 July 2017
# https://github.com/trizen

# Finds the smallest fraction approximation to a given decimal expansion.

# The last digit of the decimal expansion is ignored.

use 5.014;
use strict;
use warnings;

use Math::AnyNum qw(:overload round);

sub decimal_to_rational {
    my ($dec) = @_;

    my $is_pos = $dec > '1';
    my $str    = "$dec";

    chop $str;

    $str =~ /[0-9]\.[0-9]/
      or return $str;

    for (my $n = int($str) + '1' ; ; ++$n) {

        my ($num, $den) =
          $is_pos
          ? (round($n * $dec), $n)
          : ($n, round($n / $dec));

        if ($den and index(($num / $den)->as_dec, $str) == 0) {
            return Math::AnyNum->new_q($num, $den);
        }
    }
}

say decimal_to_rational('5.010893246187');
say decimal_to_rational('5.054466230936');

say decimal_to_rational(5.010893246187363834422657952069716775599128540305);
say decimal_to_rational(5.054466230936819172113289760348583877995642701525);

use Test::More;
plan tests => 7;

is(decimal_to_rational((1 / 6)->as_dec),  '1/6');
is(decimal_to_rational((13 / 6)->as_dec), '13/6');
is(decimal_to_rational((6 / 13)->as_dec), '6/13');

is(decimal_to_rational(0.6180339887),    '17711/28657');
is(decimal_to_rational(1.008155930329),  '7293/7234');
is(decimal_to_rational(1.0019891835756), '524875/523833');
is(decimal_to_rational(529.12424242424), '174611/330');
