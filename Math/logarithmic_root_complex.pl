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

# The function is defined in complex numbers for any value != 0.

use 5.010;
use strict;
use warnings;

use Math::MPC;
use Math::MPFR;

my $PREC  = 128;                      # can be tweaked
my $ROUND = Math::MPC::MPC_RNDNN();

sub lgrt {
    my ($c) = @_;

    if (ref($c) ne 'Math::MPC') {
        my $n = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_str($n, "$c", 10, $ROUND);
        $c = $n;
    }

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ui_pow_ui($p, 10, $PREC >> 2, $ROUND);
    Math::MPFR::Rmpfr_ui_div($p, 1, $p, $ROUND);

    my $d = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_log($d, $c, $ROUND);

    my $x = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set($x, $c, $ROUND);
    Math::MPC::Rmpc_sqrt($x, $x, $ROUND);
    Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);
    Math::MPC::Rmpc_log($x, $x, $ROUND);

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

        Math::MPC::Rmpc_add($x, $x, $d, $ROUND);
        Math::MPC::Rmpc_div($x, $x, $tmp, $ROUND);
        last if ++$count > $PREC;
    }

    $x;
}

say lgrt(100);     # (3.597285023540417505497652251782286069146 0)
say lgrt(-100);    # (3.702029366602145942901939629527371028025 1.34823128471151901327831464969872480416)
say lgrt(-1);      # (1.690386757163589211290419139332364873691 1.869907964026775775222799239924290781916)
