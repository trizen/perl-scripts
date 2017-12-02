#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 02 December 2017
# https://github.com/trizen

# A new algorithm for computing Bernoulli numbers.

# Inspired from Norman J. Wildberger video lecture:
#   https://www.youtube.com/watch?v=qmMs6tf8qZ8

# See also:
#   https://en.wikipedia.org/wiki/Bernoulli_number#Connection_with_Pascal’s_triangle

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload factorial bernfrac);

sub bernoulli_numbers {
    my ($n) = @_;

    my @B = (1);

    foreach my $i (1 .. $n) {
        foreach my $k (0 .. $i - 1) {
            $B[$i] -= $B[$k] / factorial($i - $k + 1);
        }
    }

    map { $B[$_] * factorial($_) } 0 .. $#B;
}

my @B = bernoulli_numbers(100);      # first 100 Bernoulli numbers

foreach my $i (0 .. $#B) {

    # Verify the results
    if ($i > 1 and $B[$i] != bernfrac($i)) {
        die "error for i=$i";
    }

    say "B($i) = $B[$i]";
}
