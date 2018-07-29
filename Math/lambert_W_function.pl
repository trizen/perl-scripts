#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 December 2016
# https://github.com/trizen

# A simple implementation of Lambert's W function.

# Example: x^x = 100
#            x = exp(lambert_w(log(100)))
#            x =~ 3.5972850235404...

# See also:
#   https://en.wikipedia.org/wiki/Lambert_W_function

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload approx_cmp);

sub lambert_w {
    my ($c) = @_;

    my $x = sqrt($c) + 1;
    my $y = 0;

    while (approx_cmp(abs($x - $y), 0)) {
        $y = $x;
        $x = ($x + $c) / (1 + log($x));
    }

    log($x);
}

say exp(lambert_w(log(100)));    # 3.59728502354041750549765225178228606913554305489
say exp(lambert_w(log(-100)));   # 3.70202936660214594290193962952737102802777010583+1.34823128471151901327831464969872480416292147614i
