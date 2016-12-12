#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 24 August 2016
# License: GPLv3
# Website: https://github.com/trizen

# An example for how to solve a linear congruence equation.

# Solving for x in:
#    (10^5)x + 19541 = 0    (mod 19543)
#
# which is equivalent with:
#    (10^5)x = -19541       (mod 19543)

use 5.010;
use strict;
use warnings;

use ntheory qw(invmod);

my $k =  10**5;     # coefficient of x
my $r = -19541;     # congruent to this
my $m =  19543;     # modulo this number

say "x = ", (invmod($k, $m) * $r) % $m;
