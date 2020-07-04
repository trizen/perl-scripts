#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 April 2017
# https://github.com/trizen

# Implementation of the arithmetic-geometric mean function, in complex numbers.

# See also:
#   https://en.wikipedia.org/wiki/Arithmetic%E2%80%93geometric_mean
#   https://www.mathworks.com/help/symbolic/mupad_ref/numeric-gaussagm.html

use 5.010;
use strict;
use warnings;

use Math::MPC;

our $PREC  = 192;
our $ROUND = Math::MPC::MPC_RNDNN;

# agm(a, -a) = 0
# agm(0,  x) = 0
# agm(x,  0) = 0

sub agm($$) {
    my ($x, $y) = @_;

    my $a0 = Math::MPC::Rmpc_init2($PREC);
    my $g0 = Math::MPC::Rmpc_init2($PREC);

    Math::MPC::Rmpc_set_str($a0, $x, 10, $ROUND);
    Math::MPC::Rmpc_set_str($g0, $y, 10, $ROUND);

    my $a1 = Math::MPC::Rmpc_init2($PREC);
    my $g1 = Math::MPC::Rmpc_init2($PREC);
    my $t  = Math::MPC::Rmpc_init2($PREC);

    # agm(0,  x) = 0
    if (!Math::MPC::Rmpc_cmp_si_si($a0, 0, 0)) {
        return $a0;
    }

    # agm(x, 0) = 0
    if (!Math::MPC::Rmpc_cmp_si_si($g0, 0, 0)) {
        return $g0;
    }

    my $count = 0;
    {
        Math::MPC::Rmpc_add($a1, $a0, $g0, $ROUND);
        Math::MPC::Rmpc_div_2exp($a1, $a1, 1, $ROUND);

        Math::MPC::Rmpc_mul($g1, $a0, $g0, $ROUND);
        Math::MPC::Rmpc_add($t, $a0, $g0, $ROUND);
        Math::MPC::Rmpc_sqr($t, $t, $ROUND);
        Math::MPC::Rmpc_cmp_si_si($t, 0, 0) || return $t;
        Math::MPC::Rmpc_div($g1, $g1, $t, $ROUND);
        Math::MPC::Rmpc_sqrt($g1, $g1, $ROUND);
        Math::MPC::Rmpc_add($t, $a0, $g0, $ROUND);
        Math::MPC::Rmpc_mul($g1, $g1, $t, $ROUND);

        if (Math::MPC::Rmpc_cmp($a0, $a1) and ++$count < $PREC) {
            Math::MPC::Rmpc_set($a0, $a1, $ROUND);
            Math::MPC::Rmpc_set($g0, $g1, $ROUND);
            redo;
        }
    }

    return $g0;
}

say agm(3,   4);
say agm(-1,  2);
say agm(1,   -2);
say agm(0,   5);
say agm(-10, 3.14159265358979323846264338327950288419716939938);
say agm(10,  0);
say agm(10,  -10);
say agm(10,  10);
say agm(-3,  -4);
say agm(-1,  -1);
say agm(-1,  -2);
say agm(-2,  -2);
say agm(2,   -3);
