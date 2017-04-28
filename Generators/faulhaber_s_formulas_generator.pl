#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 03 September 2015
# Website: https://github.com/trizen

# The script generates formulas for calculating the sum
# of consecutive numbers raised to a given power, such as:
#    1^p + 2^p + 3^p + ... + n^p
# where p is a positive integer.

# See also:
#   https://en.wikipedia.org/wiki/Faulhaber%27s_formula

# For simplifying the formulas, we can use Wolfram|Alpha:
#   http://www.wolframalpha.com/

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload binomial);

# This function returns the nth Bernoulli number
# See: https://en.wikipedia.org/wiki/Bernoulli_number
sub bernoulli_number {
    my ($n) = @_;

    return 0 if $n > 1 && $n % 2;    # Bn = 0 for all odd n > 1

    my @A;
    for my $m (0 .. $n) {
        $A[$m] = 1 / ($m + 1);

        for (my $j = $m ; $j > 0 ; $j--) {
            $A[$j - 1] = $j * ($A[$j - 1] - $A[$j]);
        }
    }

    return $A[0];                    # which is Bn
}

# The Faulhaber's formula
# See: https://en.wikipedia.org/wiki/Faulhaber%27s_formula
sub faulhaber_s_formula {
    my ($p) = @_;

    my @formula;
    for my $j (0 .. $p) {
        push @formula, ('(' . (binomial($p + 1, $j) * bernoulli_number($j)) . ')') . '*' . "n^" . ($p + 1 - $j);
    }

    my $formula = join(' + ', grep { !/\(0\)\*/ } @formula);

    $formula =~ s{\(1\)\*}{}g;
    $formula =~ s{\^1\b}{}g;

    "1/" . ($p + 1) . " * ($formula)";
}

foreach my $i (0 .. 10) {
    say "$i: ", faulhaber_s_formula($i);
}

__END__
0: 1/1 * (n)
1: 1/2 * (n^2 + n)
2: 1/3 * (n^3 + (3/2)*n^2 + (1/2)*n)
3: 1/4 * (n^4 + (2)*n^3 + n^2)
4: 1/5 * (n^5 + (5/2)*n^4 + (5/3)*n^3 + (-1/6)*n)
5: 1/6 * (n^6 + (3)*n^5 + (5/2)*n^4 + (-1/2)*n^2)
6: 1/7 * (n^7 + (7/2)*n^6 + (7/2)*n^5 + (-7/6)*n^3 + (1/6)*n)
7: 1/8 * (n^8 + (4)*n^7 + (14/3)*n^6 + (-7/3)*n^4 + (2/3)*n^2)
8: 1/9 * (n^9 + (9/2)*n^8 + (6)*n^7 + (-21/5)*n^5 + (2)*n^3 + (-3/10)*n)
9: 1/10 * (n^10 + (5)*n^9 + (15/2)*n^8 + (-7)*n^6 + (5)*n^4 + (-3/2)*n^2)
10: 1/11 * (n^11 + (11/2)*n^10 + (55/6)*n^9 + (-11)*n^7 + (11)*n^5 + (-11/2)*n^3 + (5/6)*n)
