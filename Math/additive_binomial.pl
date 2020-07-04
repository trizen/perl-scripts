#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 October 2017
# https://github.com/trizen

# Analogy to the binomial coefficient, using addition instead of multiplication.

# Defined as:
#    additive_binomial(n, k) = (Sum_{a = n-k+1..n} a) - (Sum_{b = 1..k} b)
#                            = n*(n+1)/2 - (n-k)*(n-k+1)/2 - k*(k+1)/2
#                            = n*k - k^2
#                            = k*(n-k)

# Additionally:
#   f(x, n) = Sum_{k=0, n} ( additive_binomial(n, k) + x*k )
#           = x*n*(n+1)/2 + (n+1)/3 * n*(n-1)/2
#           = x*(n^2 + n)/2 + (n^3 - n)/6
#           = {x, 3x+1, 6x+4, 10x+10, 15x+20, 21x+35, 28x+56, 36x+84, 45x+120, 55x+165, ...}

# Where for x=1, we have:
#   f(1, n) = {1, 4, 10, 20, 35, 56, 84, 120, 165, 220, 286, 364, 455, 560, 680, 816, 969, ...}

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

sub additive_binomial ($n, $k) {
    $k * ($n - $k);
}

foreach my $n (0 .. 19) {
    say join(' ', map { sprintf('%2s', additive_binomial($n, $_)) } 0 .. $n);
}

__END__
 0
 0  0
 0  1  0
 0  2  2  0
 0  3  4  3  0
 0  4  6  6  4  0
 0  5  8  9  8  5  0
 0  6 10 12 12 10  6  0
 0  7 12 15 16 15 12  7  0
 0  8 14 18 20 20 18 14  8  0
 0  9 16 21 24 25 24 21 16  9  0
 0 10 18 24 28 30 30 28 24 18 10  0
 0 11 20 27 32 35 36 35 32 27 20 11  0
 0 12 22 30 36 40 42 42 40 36 30 22 12  0
 0 13 24 33 40 45 48 49 48 45 40 33 24 13  0
 0 14 26 36 44 50 54 56 56 54 50 44 36 26 14  0
 0 15 28 39 48 55 60 63 64 63 60 55 48 39 28 15  0
 0 16 30 42 52 60 66 70 72 72 70 66 60 52 42 30 16  0
 0 17 32 45 56 65 72 77 80 81 80 77 72 65 56 45 32 17  0
 0 18 34 48 60 70 78 84 88 90 90 88 84 78 70 60 48 34 18  0
