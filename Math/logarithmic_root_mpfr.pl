#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 September 2016
# Website: https://github.com/trizen

# Logarithmic root of n.
# Solves c = x^x, where "c" is known.
# (based on Newton's method for nth-root)

# Example: 100 = x^x
#          x = lgrt(100)
#          x =~ 3.59728502354042

# The function is defined in real numbers for any value >= 0.7

use 5.010;
use strict;
use warnings;

use Math::MPFR;

my $PREC  = 128;                       # can be tweaked
my $ROUND = Math::MPFR::MPFR_RNDN();

sub lgrt {
    my ($c) = @_;

    if (ref($c) ne 'Math::MPFR') {
        my $n = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_str($n, "$c", 10, $ROUND);
        $c = $n;
    }

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ui_pow_ui($p, 10, $PREC >> 2, $ROUND);
    Math::MPFR::Rmpfr_ui_div($p, 1, $p, $ROUND);

    my $d = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_log($d, $c, $ROUND);

    my $x = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_ui($x, 1, $ROUND);

    my $y = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_ui($y, 0, $ROUND);

    my $tmp = Math::MPFR::Rmpfr_init2($PREC);

    while (1) {
        Math::MPFR::Rmpfr_sub($tmp, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

        Math::MPFR::Rmpfr_set($y, $x, $ROUND);

        Math::MPFR::Rmpfr_log($tmp, $x, $ROUND);
        Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

        Math::MPFR::Rmpfr_add($x, $x, $d, $ROUND);
        Math::MPFR::Rmpfr_div($x, $x, $tmp, $ROUND);
    }

    $x;
}

say lgrt(100);    # 3.597285023540417505497652251782286069146
