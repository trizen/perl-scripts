#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 May 2016
# Website: https://github.com/trizen

# Generic implementations for infinite sums, infinite
# products, continued fractions and nested radicals.

use 5.020;
use warnings;

no warnings 'recursion';
use experimental qw(signatures);

#
## Infinite sum
#

sub sum ($from, $to, $expr) {
    my $sum = 0;
    for my $i ($from .. $to) {
        $sum += $expr->($i);
    }
    $sum;
}

say "=> PI from an infinite sum:";
say 4 * sum(0, 100000, sub($n) { (-1)**$n / (2 * $n + 1) });

#
## Infinite product
#

sub prod ($from, $to, $expr) {
    my $prod = 1;
    for my $i ($from .. $to) {
        $prod *= $expr->($i);
    }
    $prod;
}

say "=> PI from an infinite product:";
say 2 / prod(1, 100000, sub($n) { 1 - 1 / (4 * $n**2) });

#
## Continued fractions
#

sub cfrac ($from, $to, $num, $den) {
    return 0 if ($from > $to);
    $num->($from) / ($den->($from) + cfrac($from + 1, $to, $num, $den));
}

say "=> PI from a continued fraction:";
say 4 / (1 + cfrac(1, 100000, sub($n) { $n**2 }, sub($n) { 2 * $n + 1 }));

#
## Nested radicals
#

sub nestrad ($from, $to, $coeff, $expr) {
    return 0 if ($from > $to);
    $expr->($coeff->($from) + nestrad($from + 1, $to, $coeff, $expr));
}

say "=> PI from nested square roots:";
say 2 / prod(
    1, 100,
    sub ($n) {
        nestrad(1, $n, sub($) { 2 }, sub($x) { sqrt($x) }) / 2;
    }
);

# A formula by N. J. Wildberger
# https://www.youtube.com/watch?v=lcIbCZR0HbU

say sqrt(4**(12+1) *
    (2 - nestrad(1, 12, sub($) { 2 }, sub($x) { sqrt($x) }))
);
