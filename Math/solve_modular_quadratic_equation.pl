#!/usr/bin/perl

# Author: Trizen
# Date: 04 May 2022
# https://github.com/trizen

# Solve modular quadratic equations of the form:
#   a*x^2 + b*x + c == 0 (mod m)

# Solving method:
#   D = b^2 - 4*a*c
#   t^2 == D (mod 4*m)

# By finding all the solutions to `t`, using `sqrtmod(D, 4*m)`, the candidate values for `x` are given by:
#   x_1 = (-b + t)/(2*a)
#   x_2 = (-b - t)/(2*a)

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use List::Util qw(uniq);
use Math::AnyNum qw(:overload);
use experimental qw(signatures);

sub modular_quadratic_equation ($A, $B, $C, $M) {

    my $D = ($B * $B - 4 * $A * $C);

    my @S;
    foreach my $t (allsqrtmod($D, 4 * $M)) {
        for my $uv ([-$B + $t, 2 * $A], [-$B - $t, 2 * $A]) {
            my ($u, $v) = @$uv;
            my $x = ($u % $v == 0) ? (($u / $v) % $M) : divmod($u, $v, $M);
            if (($A * $x * $x + $B * $x + $C) % $M == 0) {
                push @S, $x;
            }
        }
    }

    return sort { $a <=> $b } uniq(@S);
}

say join ' ', modular_quadratic_equation(1, 1, -10**10 + 8,  10**10);
say join ' ', modular_quadratic_equation(4, 6, 10 - 10**10,  10**10);
say join ' ', modular_quadratic_equation(1, 1, -10**10 - 10, 10**10);

__END__
1810486343 2632873031 7367126968 8189513656
905243171 1316436515 5905243171 6316436515
263226214 1620648089 8379351910 9736773785
