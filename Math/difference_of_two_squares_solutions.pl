#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 August 2017
# https://github.com/trizen

# An algorithm for finding solutions to an equation:
#
#   x^2 - y^2 = 4*n
#
# where only `n` is known.

# This algorithm uses the divisors of `n` to generate all the non-negative integer solutions.

use 5.010;
use strict;
use warnings;

use ntheory qw(divisors sqrtint);

sub difference_of_two_squares_solutions {
    my ($n) = @_;

    if ($n % 4 != 0) {    # must be a multiple of 4
        return;
    }

    $n >>= 2;

    my @divisors = divisors($n);

    my @solutions;
    foreach my $divisor (@divisors) {

        last if $divisor > sqrt($n);

        my $p = $divisor;
        my $q = $n / $divisor;
        my $d = abs($p - $q);

        unshift @solutions, [sqrtint($d**2 + 4 * $n), $d];
    }

    return @solutions;
}

my $n         = 1275344;
my @solutions = difference_of_two_squares_solutions($n);

foreach my $solution (@solutions) {
    say "$solution->[0]^2 - $solution->[1]^2 = $n";
}

__END__
1185^2 - 359^2 = 1275344
1212^2 - 440^2 = 1275344
1587^2 - 1115^2 = 1275344
1845^2 - 1459^2 = 1275344
2820^2 - 2584^2 = 1275344
5463^2 - 5345^2 = 1275344
11415^2 - 11359^2 = 1275344
22788^2 - 22760^2 = 1275344
45555^2 - 45541^2 = 1275344
79713^2 - 79705^2 = 1275344
159420^2 - 159416^2 = 1275344
318837^2 - 318835^2 = 1275344
