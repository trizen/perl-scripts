#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 July 2017
# https://github.com/trizen

# An interesting function: logarithmic root in two variables.

# For certain values of x, it has the following identity:
#   lgrt2(x, x) = lgrt(x)

# such that:
#   exp(log(lgrt(x)) * lgrt(x)) = x

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload pi e euler);

sub lgrt2 {
    my ($n, $k) = @_;

    my $f = log($n);
    my $d = log($k);

    my $r = sqrt($f * $d);

    for (1 .. 200) {

        my $x = exp($f / $r);
        my $y = $d / log($x);

        $r = sqrt($x * $y);
    }

    return $r;
}

say lgrt2(pi, e);                     # 1.70771856994915347630915983730048900477178427941
say lgrt2(e,  pi);                    # 1.92464943796370515962751401131903762619866583525

say lgrt2(exp(euler), e);             # 2.24133450569957655907533525796185668012280055007
say lgrt2(e,          exp(euler));    # 1.26917997775582192005119311046938840265836794516

say lgrt2(exp(euler), pi);            # 2.49858594291645763243658930518886102264912661091
say lgrt2(pi,         exp(euler));    # 1.25519152681721226553799617023948749426608115087

say lgrt2(100, 100);                  # 3.59728502354041750549765225178228606913554305489

say lgrt2(i,  -1);                    # 2.32604988653472423641885139636547364864085030537+1.30957380904696411943253549742370685112065954665i
say lgrt2(-1, i);                     # 1.10679171296146730411561900792354747210041425159+1.55699997420064988554089005455614440858763281837i
