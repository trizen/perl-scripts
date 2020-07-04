#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 21 September 2015
# Website: https://github.com/trizen

# The script generates formulas for calculating the sum
# of consecutive numbers raised to a given power, such as:
#    1^p + 2^p + 3^p + ... + n^p
# where p is a positive integer.

# See also: https://en.wikipedia.org/wiki/Faulhaber%27s_formula

# To simplify the formulas, use Wolfram Alpha:
# http://www.wolframalpha.com/

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload);
use Memoize qw( memoize );

memoize('binomial');
memoize('factorial');
memoize('bernoulli_number');

# Factorial
# See: https://en.wikipedia.org/wiki/Factorial
sub factorial {
    my ($n) = @_;

    return 1 if $n == 0;

    my $f = $n;
    while ($n-- > 1) {
        $f = "$f*$n";
    }

    return $f;
}

# Binomial coefficient
# See: https://en.wikipedia.org/wiki/Binomial_coefficient
sub binomial {
    my ($n, $k) = @_;

    ## This line expands the factorials
    #return "(".factorial($n) .")" . "/((" . factorial($k).")*(". factorial($n-$k) . "))";

    ## This line expands the binomial coefficients into factorials
    return "$n!/($k!*" . ($n - $k) . "!)";

    ## This line computes the binomial coefficients
    #$k == 0 || $n == $k ? 1.0 : binomial($n - 1, $k - 1) + binomial($n - 1, $k);
}

# Bernoulli numbers
# See: https://en.wikipedia.org/wiki/Bernoulli_number#Algorithmic_description
sub bernoulli_number {
    my ($n) = @_;

    # return 0 if $n > 1 && $n % 2;    # Bn = 0 for all odd n > 1

    my @A;
    for my $m (0 .. $n) {
        $A[$m] = 1 / ($m + 1);
        for (my $j = $m ; $j > 0 ; $j--) {
            $A[$j - 1] = "$j*" . '(' . join('-', ($A[$j - 1], $A[$j])) . ')';
        }
    }

    return $A[0];    # which is Bn
}

# Faulhaber's formula
# See: https://en.wikipedia.org/wiki/Faulhaber%27s_formula
sub faulhaber_s_formula {
    my ($p, $n) = @_;

    my @formula;
    for my $j (0 .. $p) {
        push @formula, ('(' . (binomial($p + 1, $j) . "*" . bernoulli_number($j)) . ')') . '*' . "n^" . ($p + 1 - $j);
    }

    my $formula = join(' + ', @formula);
    "1/" . ($p + 1) . " * ($formula)";
}

for my $i (0 .. 5) {
    printf "%d => %s\n", $i, faulhaber_s_formula($i + 0);
}

__END__
0 => 1/1 * ((1!/(0!*1!)*1)*n^1)
1 => 1/2 * ((2!/(0!*2!)*1)*n^2 + (2!/(1!*1!)*1*(1-1/2))*n^1)
2 => 1/3 * ((3!/(0!*3!)*1)*n^3 + (3!/(1!*2!)*1*(1-1/2))*n^2 + (3!/(2!*1!)*1*(1*(1-1/2)-2*(1/2-1/3)))*n^1)
3 => 1/4 * ((4!/(0!*4!)*1)*n^4 + (4!/(1!*3!)*1*(1-1/2))*n^3 + (4!/(2!*2!)*1*(1*(1-1/2)-2*(1/2-1/3)))*n^2 + (4!/(3!*1!)*1*(1*(1*(1-1/2)-2*(1/2-1/3))-2*(2*(1/2-1/3)-3*(1/3-1/4))))*n^1)
4 => 1/5 * ((5!/(0!*5!)*1)*n^5 + (5!/(1!*4!)*1*(1-1/2))*n^4 + (5!/(2!*3!)*1*(1*(1-1/2)-2*(1/2-1/3)))*n^3 + (5!/(3!*2!)*1*(1*(1*(1-1/2)-2*(1/2-1/3))-2*(2*(1/2-1/3)-3*(1/3-1/4))))*n^2 + (5!/(4!*1!)*1*(1*(1*(1*(1-1/2)-2*(1/2-1/3))-2*(2*(1/2-1/3)-3*(1/3-1/4)))-2*(2*(2*(1/2-1/3)-3*(1/3-1/4))-3*(3*(1/3-1/4)-4*(1/4-1/5)))))*n^1)
5 => 1/6 * ((6!/(0!*6!)*1)*n^6 + (6!/(1!*5!)*1*(1-1/2))*n^5 + (6!/(2!*4!)*1*(1*(1-1/2)-2*(1/2-1/3)))*n^4 + (6!/(3!*3!)*1*(1*(1*(1-1/2)-2*(1/2-1/3))-2*(2*(1/2-1/3)-3*(1/3-1/4))))*n^3 + (6!/(4!*2!)*1*(1*(1*(1*(1-1/2)-2*(1/2-1/3))-2*(2*(1/2-1/3)-3*(1/3-1/4)))-2*(2*(2*(1/2-1/3)-3*(1/3-1/4))-3*(3*(1/3-1/4)-4*(1/4-1/5)))))*n^2 + (6!/(5!*1!)*1*(1*(1*(1*(1*(1-1/2)-2*(1/2-1/3))-2*(2*(1/2-1/3)-3*(1/3-1/4)))-2*(2*(2*(1/2-1/3)-3*(1/3-1/4))-3*(3*(1/3-1/4)-4*(1/4-1/5))))-2*(2*(2*(2*(1/2-1/3)-3*(1/3-1/4))-3*(3*(1/3-1/4)-4*(1/4-1/5)))-3*(3*(3*(1/3-1/4)-4*(1/4-1/5))-4*(4*(1/4-1/5)-5*(1/5-1/6))))))*n^1)
