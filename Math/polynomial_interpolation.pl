#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 December 2018
# https://github.com/trizen

# Polynomial interpolation:
#   find the polynomial of lowest possible degree that passes through all the points of a given dataset.

# See also:
#   https://en.wikipedia.org/wiki/Vandermonde_matrix
#   https://en.wikipedia.org/wiki/Polynomial_interpolation

use 5.010;
use strict;
use warnings;

use Math::MatrixLUP;
use Math::AnyNum qw(ipow sum);

# A sequence of n numbers
my @v = (35, 85, 102, 137, 120);

# Create a new nXn Vandermonde matrix
my @A = map {
    my $n = $_;
    [map { ipow($n, $_) } 0..$#v];
} 0..$#v;

my $A = Math::MatrixLUP->new(\@A);
my $S = $A->solve(\@v);

say "Coefficients: [", join(', ', @$S), "]";
say "Polynomial  : ", join(' + ', map { "($S->[$_] * x^$_)" } 0..$#{$S});
say "Terms       : ", join(', ', map { my $x = $_; sum(map { $x**$_ * $S->[$_] } 0..$#{$S}) } 0..$#v);

__END__
Coefficients: [35, 455/4, -2339/24, 155/4, -121/24]
Polynomial  : (35 * x^0) + (455/4 * x^1) + (-2339/24 * x^2) + (155/4 * x^3) + (-121/24 * x^4)
Terms       : 35, 85, 102, 137, 120
