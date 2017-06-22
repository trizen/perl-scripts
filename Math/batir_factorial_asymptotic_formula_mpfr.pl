#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 21 June 2017
# https://github.com/trizen

# A very good factorial approximation, due to N. Batir.

# The asymptotic formula is:
#   n! ~ 1/216 * √(π/70) * exp(-n) * n^(n-2) * √(42*n*(24*n*(90*n*(12*n*(6*n + 1) + 1) - 31) - 139) + 9871)

use 5.010;
use strict;
use warnings;

our ($ROUND, $PREC);

BEGIN {
    use Math::MPFR qw();
    $ROUND = Math::MPFR::MPFR_RNDN();
    $PREC  = 200;
}

use Math::AnyNum (PREC => $PREC);

sub fac_batir {
    my ($n) = @_;

    my $f = Math::MPFR::Rmpfr_init2($PREC);

    # f = (12*n*(6*n + 1) + 1)
    Math::MPFR::Rmpfr_set_ui($f, $n, $ROUND);
    Math::MPFR::Rmpfr_mul_ui($f, $f, 6, $ROUND);
    Math::MPFR::Rmpfr_add_ui($f, $f, 1, $ROUND);
    Math::MPFR::Rmpfr_mul_ui($f, $f, $n, $ROUND);
    Math::MPFR::Rmpfr_mul_ui($f, $f, 12, $ROUND);
    Math::MPFR::Rmpfr_add_ui($f, $f, 1, $ROUND);

    # f = (24*n*(90*n*f - 31) - 139)
    Math::MPFR::Rmpfr_mul_ui($f, $f, $n, $ROUND);
    Math::MPFR::Rmpfr_mul_ui($f, $f, 90, $ROUND);
    Math::MPFR::Rmpfr_sub_ui($f, $f, 31, $ROUND);
    Math::MPFR::Rmpfr_mul_ui($f, $f, $n, $ROUND);
    Math::MPFR::Rmpfr_mul_ui($f, $f, 24, $ROUND);
    Math::MPFR::Rmpfr_sub_ui($f, $f, 139, $ROUND);

    # f = √(42*n*f + 9871)
    Math::MPFR::Rmpfr_mul_ui($f, $f, $n, $ROUND);
    Math::MPFR::Rmpfr_mul_ui($f, $f, 42, $ROUND);
    Math::MPFR::Rmpfr_add_ui($f, $f, 9871, $ROUND);
    Math::MPFR::Rmpfr_sqrt($f, $f, $ROUND);

    # f = f * n^(n-2)
    my $t = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ui_pow_ui($t, $n, $n - 2, $ROUND);
    Math::MPFR::Rmpfr_mul($f, $f, $t, $ROUND);

    # f = f * exp(-n)
    Math::MPFR::Rmpfr_set_ui($t, $n, $ROUND);
    Math::MPFR::Rmpfr_neg($t, $t, $ROUND);
    Math::MPFR::Rmpfr_exp($t, $t, $ROUND);
    Math::MPFR::Rmpfr_mul($f, $f, $t, $ROUND);

    # f = f * √(π/70)
    Math::MPFR::Rmpfr_const_pi($t, $ROUND);
    Math::MPFR::Rmpfr_div_ui($t, $t, 70, $ROUND);
    Math::MPFR::Rmpfr_sqrt($t, $t, $ROUND);
    Math::MPFR::Rmpfr_mul($f, $f, $t, $ROUND);

    # f = f/216
    Math::MPFR::Rmpfr_div_ui($f, $f, 216, $ROUND);

    # Create and return a new Math::AnyNum object
    Math::AnyNum->new($f);
}

foreach my $n (1 .. 10) {
    say fac_batir($n);
}

__END__
1.0001633529366947590265935448207438761433429838411
2.0000029860747051176081702869925254469658097576474
6.0000003229774185743648491096337544662543793954941
24.000000013320139202368363609786566171333392325063
119.99999982560322070035659496327332403346753218872
719.99999937604769710505519830495674394359333008983
5039.9999977053735752532469858794448681595399481797
40319.999990211060074629645362635300614581980624166
362879.99995110486335462650403778927886141969579338
3628799.9997167757110134397984453555772078233918289
