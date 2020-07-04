#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 December 2016
# https://github.com/trizen

# Implementation of the Lambert-W function in complex numbers.

# Example: x^x = 100
#            x = exp(lambert_w(log(100)))
#            x =~ 3.59728502354042

# See also:
#   https://en.wikipedia.org/wiki/Lambert_W_function

use 5.010;
use strict;
use warnings;

use Math::MPC;
use Math::MPFR;

my $PREC  = 128;                      # can be tweaked
my $ROUND = Math::MPC::MPC_RNDNN();

sub lambert_w {
    my ($c) = @_;

    if (ref($c) ne 'Math::MPC') {
        my $n = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_str($n, "$c", 10, $ROUND);
        $c = $n;
    }

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ui_pow_ui($p, 10, int($PREC / 4), $ROUND);
    Math::MPFR::Rmpfr_ui_div($p, 1, $p, $ROUND);

    my $x = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set($x, $c, $ROUND);
    Math::MPC::Rmpc_sqrt($x, $x, $ROUND);
    Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);

    my $y = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

    my $tmp = Math::MPC::Rmpc_init2($PREC);
    my $abs = Math::MPFR::Rmpfr_init2($PREC);

    my $count = 0;
    while (1) {
        Math::MPC::Rmpc_sub($tmp, $x, $y, $ROUND);

        Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
        Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

        Math::MPC::Rmpc_set($y, $x, $ROUND);

        Math::MPC::Rmpc_log($tmp, $x, $ROUND);
        Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

        Math::MPC::Rmpc_add($x, $x, $c, $ROUND);
        Math::MPC::Rmpc_div($x, $x, $tmp, $ROUND);
        last if ++$count > $PREC;
    }

    Math::MPC::Rmpc_log($x, $x, $ROUND);
    $x;
}

say lambert_w(100);     #  3.385630140290050184888244364529726867493
say lambert_w(-100);    #  3.205380786307449372155918213968303847481  + 2.482590531815923582117041287234452276982i
say lambert_w(-0.5);    # -0.7940236323446893679630153219005898091005 + 0.770111750510379109681313077405028929402i
