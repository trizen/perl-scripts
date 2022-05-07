#!/usr/bin/perl

# Find all the solutions to a cubic equation.

# See also:
#   https://en.wikipedia.org/wiki/Cubic_equation#General_cubic_formula

use 5.020;
use strict;
use warnings;

use Math::AnyNum qw(:overload cbrt sgn);
use experimental qw(signatures);

sub solve_cubic_equation($a,$b,$c,$d) {

    my $D0 = ($b*$b - 3*$a*$c);
    my $D1 = (2*$b**3 - 9*$a*$b*$c + 27*$a*$a*$d);

    my @roots;
    my $z = (-1 + sqrt(-3))/2;

    my $C = cbrt(($D1 - (sgn($D0)||-1)*sqrt($D1*$D1 - 4*$D0**3))/2);

    foreach my $k (0..2) {
        my $t = ($C * $z**$k);
        my $x = -(($b + $t + $D0/$t))/(3*$a);
        push @roots, $x;
    }

    return @roots;
}

say ":: Solutions to: x^3 + 5*x^2 + 2*x - 8 = 0";
say for solve_cubic_equation(1, 5, 2, -8);

say "\n:: Solutions to: x^3 + 4*x^2 + 7*x + 6 = 0";
say for solve_cubic_equation(1, 4, 7, 6);

say "\n:: Solutions to: -36*x^3 + 8*x^2 - 82*x + 2850986 = 0:";
say for solve_cubic_equation(-36, 8, -82, 2850986);

say "\n:: Solutions to: 15*x^3 - 22*x^2 + 8*x - 7520940423059310542039581 = 0:";
say for solve_cubic_equation(15, -22, 8, -7520940423059310542039581);

__END__
:: Solutions to: x^3 + 5*x^2 + 2*x - 8 = 0
-4+2.12412254817660303603850719702361574078813940692e-58i
-2
1

:: Solutions to: x^3 + 4*x^2 + 7*x + 6 = 0
-2
-1-1.41421356237309504880168872420969807856967187538i
-1+1.41421356237309504880168872420969807856967187538i

:: Solutions to: -36*x^3 + 8*x^2 - 82*x + 2850986 = 0:
43
-21.3888888888888888888888888888888888888888888889+37.2053444322316098931489931056362914296357714346i
-21.3888888888888888888888888888888888888888888889-37.2053444322316098931489931056362914296357714346i

:: Solutions to: 15*x^3 - 22*x^2 + 8*x - 7520940423059310542039581 = 0:
-39721925.7666666666666666666666666666666666666667-68800394.4491263888002422566466396186371117612128i
79443853+7.88093052224943999146836047476866957980682147598e-51i
-39721925.7666666666666666666666666666666666666667+68800394.4491263888002422566466396186371117612128i
