#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 03 September 2015
# Website: https://github.com/trizen

# The scrips generates formulas for calculating the sum of series such as:
#    1^p + 2^p + 3^p + ... n^p
# where p is a positive integer.

# See also: https://en.wikipedia.org/wiki/Faulhaber%27s_formula

# To simplify the formulas, use Wolfram Alpha:
# http://www.wolframalpha.com/

use 5.010;
use strict;
use warnings;

use bigrat (try => 'GMP');

# This function returns the nth Bernoulli number
# See: https://en.wikipedia.org/wiki/Bernoulli_number
sub bernoulli_number {
    my ($n) = @_;

    my @A;
    for my $m (0 .. $n) {
        $A[$m] = 1 / ($m + 1);

        for (my $j = $m ; $j > 0 ; $j--) {
            $A[$j - 1] = $j * ($A[$j - 1] - $A[$j]);
        }
    }

    $A[0];
}

# The binomial coefficient
# See: https://en.wikipedia.org/wiki/Binomial_coefficient
sub nok {
    my ($n, $k) = @_;
    Math::BigRat->new($n)->bnok($k);
}

# The Faulhaber's formula
# See: https://en.wikipedia.org/wiki/Faulhaber%27s_formula
sub faulhaber_s_formula {
    my ($p, $n) = @_;

    my @formula;
    for my $j (0 .. $p) {
        push @formula, ('(' . (nok($p + 1, $j) * bernoulli_number($j)) . ')') . '*' . "n^" . ($p + 1 - $j);
    }

    my $formula = join(' + ', grep { !/\(0\)\*/ } @formula);

    $formula =~ s{\(1\)\*}{}g;
    $formula =~ s{\^1\b}{}g;

    "1/" . ($p + 1) . " * ($formula)";
}

foreach my $i (0 .. 10) {
    say "$i: ", faulhaber_s_formula($i);
}
