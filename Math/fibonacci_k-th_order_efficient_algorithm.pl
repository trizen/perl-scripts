#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 January 2019
# https://github.com/trizen

# Generalized efficient formula for computing the k-th order Fibonacci numbers, using exponentation by squaring.

# OEIS sequences:
#   https://oeis.org/A000045    (2-nd order: Fibonacci numbers)
#   https://oeis.org/A000073    (3-rd order: Tribonacci numbers)
#   https://oeis.org/A000078    (4-th order: Tetranacci numbers)
#   https://oeis.org/A001591    (5-th order: Pentanacci numbers)

# See also:
#   https://en.wikipedia.org/wiki/Generalizations_of_Fibonacci_numbers
#   https://en.wikipedia.org/wiki/Exponentiation_by_squaring

# Example of Fibonacci matrices for k=2..4:
#
#   A_2 = Matrix(
#           [0, 1],
#           [1, 1]
#         )
#
#   A_3 = Matrix(
#           [0, 1, 0],
#           [0, 0, 1],
#           [1, 1, 1]
#         )
#
#   A_4 = Matrix(
#           [0, 1, 0, 0],
#           [0, 0, 1, 0],
#           [0, 0, 0, 1],
#           [1, 1, 1, 1]
#         )

# Let R = (A_k)^n.
# The n-th k-th order Fibonacci number is the last term in the first row of R.

use 5.020;
use strict;
use warnings;

use Math::MatrixLUP;
use experimental qw(signatures);

sub fibonacci_matrix($k) {
    Math::MatrixLUP->build(
        $k, $k,
        sub ($i, $j) {
                ($i == $k - 1) ? 1
              : ($i == $j - 1) ? 1
              :                  0;
        }
    );
}

sub modular_fibonacci_kth_order ($n, $k, $m) {
    my $A = fibonacci_matrix($k);
    ($A->powmod($n, $m))->[0][-1];
}

sub fibonacci_kth_order ($n, $k = 2) {
    my $A = fibonacci_matrix($k);
    ($A**$n)->[0][-1];
}

foreach my $k (2 .. 6) {
    say("Fibonacci of k=$k order: ", join(', ', map { fibonacci_kth_order($_, $k) } 0 .. 14 + $k));
}

say '';

foreach my $k (2 .. 6) {
    say("Last n digits of 10^n $k-order Fibonacci numbers: ",
        join(', ', map { modular_fibonacci_kth_order(10**$_, $k, 10**$_) } 0 .. 9));
}

__END__
Fibonacci of k=2 order: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987
Fibonacci of k=3 order: 0, 0, 1, 1, 2, 4, 7, 13, 24, 44, 81, 149, 274, 504, 927, 1705, 3136, 5768
Fibonacci of k=4 order: 0, 0, 0, 1, 1, 2, 4, 8, 15, 29, 56, 108, 208, 401, 773, 1490, 2872, 5536, 10671
Fibonacci of k=5 order: 0, 0, 0, 0, 1, 1, 2, 4, 8, 16, 31, 61, 120, 236, 464, 912, 1793, 3525, 6930, 13624
Fibonacci of k=6 order: 0, 0, 0, 0, 0, 1, 1, 2, 4, 8, 16, 32, 63, 125, 248, 492, 976, 1936, 3840, 7617, 15109

Last n digits of 10^n 2-order Fibonacci numbers: 0, 5, 75, 875, 6875, 46875, 546875, 546875, 60546875, 560546875
Last n digits of 10^n 3-order Fibonacci numbers: 0, 1, 58, 384, 1984, 62976, 865536, 2429440, 86712832, 941792256
Last n digits of 10^n 4-order Fibonacci numbers: 0, 6, 96, 160, 1792, 92544, 348928, 6868608, 41256704, 824732160
Last n digits of 10^n 5-order Fibonacci numbers: 0, 1, 33, 385, 1025, 69921, 360833, 4117505, 34469121, 304605953
Last n digits of 10^n 6-order Fibonacci numbers: 0, 6, 4, 925, 3376, 93151, 642996, 3541264, 38339728, 425978989
