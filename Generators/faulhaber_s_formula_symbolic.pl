#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 February 2016
# Website: https://github.com/trizen

# The script generates formulas for calculating the sum
# of consecutive numbers raised to a given power, such as:
#    1^p + 2^p + 3^p + ... + n^p
# where p is a positive integer.

# See also: https://en.wikipedia.org/wiki/Faulhaber%27s_formula

use 5.010;
use strict;
use warnings;

use Math::Algebra::Symbols;

# This function returns the nth Bernoulli number
# See: https://en.wikipedia.org/wiki/Bernoulli_number
sub bernoulli_number {
    my ($n) = @_;

    return 0 if $n > 1 && $n % 2;    # Bn = 0 for all odd n > 1

    my @A;
    for my $m (0 .. $n) {
        $A[$m] = symbols(1) / ($m + 1);

        for (my $j = $m ; $j > 0 ; $j--) {
            $A[$j - 1] = $j * ($A[$j - 1] - $A[$j]);
        }
    }

    return $A[0];                    # which is Bn
}

# The binomial coefficient
# See: https://en.wikipedia.org/wiki/Binomial_coefficient
sub binomial {
    my ($n, $k) = @_;
    $k == 0 || $n == $k ? 1 : binomial($n-1, $k-1) + binomial($n-1, $k);
}

# The Faulhaber's formula
# See: https://en.wikipedia.org/wiki/Faulhaber%27s_formula
sub faulhaber_s_formula {
    my ($p) = @_;

    my $formula = 0;
    for my $j (0 .. $p) {
        $formula += (binomial($p + 1, $j) * bernoulli_number($j)) * symbols('n')**($p + 1 - $j);
    }

    (symbols(1) / ($p+1) * $formula) =~ s/\$n/n/gr =~ s/\*\*/^/gr;
}

foreach my $i (0 .. 10) {
    say "$i: ", faulhaber_s_formula($i);
}
