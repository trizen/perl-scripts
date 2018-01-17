#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 July 2017
# https://github.com/trizen

# Simple and efficient algorithm for finding the smallest fraction
# approximation to any given real number, using continued fractions.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Test::More;
plan tests => 11;

use Math::AnyNum qw(:overload float round);

sub num2cfrac ($callback, $n) {
    while (1) {
        my $m = int(round($n));
        $callback->($m) && return 1;
        $n = 1 / (($n - $m) || last);
    }
}

sub cfrac2num (@f) {
    sub ($i) {
        $i < $#f ? ($f[$i] + 1 / __SUB__->($i + 1)) : $f[$i];
    }->(0);
}

sub fraction_approximation($dec) {

    $dec = float($dec);

    my ($rat, @nums);
    my $str = "$dec";

    num2cfrac(
        sub ($n) {
            push @nums, $n;
            $rat = cfrac2num(@nums);
            index($rat->as_dec, $str) == 0;
        }, $dec
    );

    return $rat;
}

is(fraction_approximation('0.6180339887'),    '260497/421493');
is(fraction_approximation('1.008155930329'),  '7293/7234');
is(fraction_approximation('1.0019891835756'), '524875/523833');
is(fraction_approximation('529.12424242424'), '174611/330');

is(fraction_approximation((1 / 6)->as_dec),  '1/6');
is(fraction_approximation((13 / 6)->as_dec), '13/6');
is(fraction_approximation((6 / 13)->as_dec), '6/13');

is(fraction_approximation('5.010893246187'), '2300/459');
is(fraction_approximation('5.054466230936'), '2320/459');

is(fraction_approximation(5.0108932461873638344226579520697167755991285403), '2300/459');
is(fraction_approximation(5.0544662309368191721132897603485838779956427015), '2320/459');
