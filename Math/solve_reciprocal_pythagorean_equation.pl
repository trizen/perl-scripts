#!/usr/bin/perl

# Find all the primitive solutions to the inverse Pythagorean equation:
#   1/x^2 + 1/y^2 = 1/z^2
# such that x <= y and 1 <= x,y,z <= N.

# It can be shown that all the primitive solutions are generated from the following parametric form:
#
#   x = 2*a*b*(a^2 + b^2)
#   y = a^4 - b^4
#   z = 2*a*b*(a^2 - b^2)
#
# where gcd(a, b) = 1 and a+b is odd.

# See also:
#   https://oeis.org/A341990
#   https://math.stackexchange.com/questions/2688808/diophantine-equation-of-three-variables

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub S ($N) {

    my @solutions;
    my $limit = rootint($N, 4);

    foreach my $a (1 .. $limit) {
        foreach my $b (1 .. $a - 1) {

            ($a + $b) % 2 == 1 or next;
            gcd($a, $b) == 1   or next;

            my $aa = mulint($a, $a);
            my $ab = mulint($a, $b);
            my $bb = mulint($b, $b);

            my $x = vecprod(2, $ab, addint($aa, $bb));
            my $y = subint(powint($a, 4), powint($b, 4));
            my $z = vecprod(2, $ab, subint($aa, $bb));

            $x <= $N or next;
            $y <= $N or next;
            $z <= $N or next;

            push @solutions, [$x, $y, $z];
        }
    }

    sort { $a->[0] <=> $b->[0] } @solutions;
}

my $N = 10000;

say <<"EOT";

:: Primitve solutions (x,y,z) with 1 <= x,y,z <= $N and x <= y, to equation:

    1/x^2 + 1/y^2 = 1/z^2
EOT

foreach my $triple (S($N)) {
    my ($x, $y, $z) = @$triple;
    say "($x, $y, $z)";
}

__END__

:: Primitve solutions (x,y,z) with 1 <= x,y,z <= 10000 and x <= y, to equation:

    1/x^2 + 1/y^2 = 1/z^2

(20, 15, 12)
(136, 255, 120)
(156, 65, 60)
(444, 1295, 420)
(580, 609, 420)
(600, 175, 168)
(1040, 4095, 1008)
(1484, 2385, 1260)
(1640, 369, 360)
(2020, 9999, 1980)
(3060, 6545, 2772)
(3504, 4015, 2640)
(3640, 2145, 1848)
(3660, 671, 660)
(6540, 9919, 5460)
(6984, 6305, 4680)
(7120, 3471, 3120)
(7140, 1105, 1092)
