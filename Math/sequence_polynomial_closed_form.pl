#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 January 2019
# https://github.com/trizen

# Find a closed-form polynomial to a given sequence of numbers.

# See also:
#   https://www.youtube.com/watch?v=gur16QsZ0r4
#   https://en.wikipedia.org/wiki/Polynomial_interpolation
#   https://en.wikipedia.org/wiki/Vandermonde_matrix

use 5.020;
use warnings;

use Math::MatrixLUP;
use Math::AnyNum qw(ipow sum);

use List::Util qw(all);
use experimental qw(signatures);

sub find_poly_degree(@seq) {
    for (my $c = 1 ; ; ++$c) {
        @seq = map { $seq[$_ + 1] - $seq[$_] } 0 .. $#seq - 1;
        return $c if all { $_ == 0 } @seq;
    }
}

sub eval_poly ($S, $x) {
    sum(map { ($S->[$_] == 0) ? 0 : ($S->[$_] * ipow($x, $_)) } 0 .. $#{$S});
}

# An arbitrary sequence of numbers
my @seq = (
           @ARGV
           ? (map { Math::AnyNum->new($_) } grep { /[0-9]/ } map { split(' ') } map { split(/\s*,\s*/) } @ARGV)
           : (0, 1, 17, 98, 354, 979, 2275, 4676)
          );

# Find the lowest polygonal degree to express the sequence
my $c = find_poly_degree(@seq);

# Create a new cXc Vandermonde matrix
my $A = Math::MatrixLUP->build($c, sub ($n, $k) { ipow($n, $k) });

# Find the polygonal coefficients
my $S = $A->solve([@seq[0 .. $c - 1]]);

# Stringify the polynomial
my $P = join(' + ', map { ($S->[$_] == 0) ? () : "($S->[$_] * x^$_)" } 0 .. $#{$S});

if ($c == scalar(@seq)) {
    say "\n*** WARNING: the polynomial found may not be a closed-form to this sequence! ***\n";
}

say "Coefficients : [", join(', ', @$S), "]";
say "Polynomial   : $P";
say "Next 5 terms : [", join(', ', map { eval_poly($S, $_) } scalar(@seq) .. scalar(@seq) + 4), "]";

__END__
Coefficients : [0, -1/30, 0, 1/3, 1/2, 1/5]
Polynomial   : (-1/30 * x^1) + (1/3 * x^3) + (1/2 * x^4) + (1/5 * x^5)
Next 5 terms : [8772, 15333, 25333, 39974, 60710]
