#!/usr/bin/perl

# Simple implementation of the LU decomposition.

# See also:
#   https://en.wikipedia.org/wiki/LU_decomposition

use 5.014;
use warnings;

use Math::AnyNum qw(:overload);

# Code translated from Wikipedia (+ minor tweaks):
#   https://en.wikipedia.org/wiki/LU_decomposition#C_code_examples

sub _LUP_decompose {
    my ($matrix) = @_;

    my @A = map { [@$_] } @$matrix;
    my $N = $#A;
    my @P = (0 .. $N + 1);

    foreach my $i (0 .. $N) {

        my $maxA = 0;
        my $imax = $i;

        foreach my $k ($i .. $N) {
            my $absA = abs($A[$k][$i] // return ($N, \@A, \@P));

            if ($absA > $maxA) {
                $maxA = $absA;
                $imax = $k;
            }
        }

        if ($imax != $i) {

            @P[$i, $imax] = @P[$imax, $i];
            @A[$i, $imax] = @A[$imax, $i];

            ++$P[$N + 1];
        }

        foreach my $j ($i + 1 .. $N) {

            if ($A[$i][$i] == 0) {
                return ($N, \@A, \@P);
            }

            $A[$j][$i] /= $A[$i][$i];

            foreach my $k ($i + 1 .. $N) {
                $A[$j][$k] -= $A[$j][$i] * $A[$i][$k];
            }
        }
    }

    return ($N, \@A, \@P);
}

sub solve {
    my ($matrix, $vector) = @_;

    my ($N, $A, $P) = _LUP_decompose($matrix);

    my @x = map { $vector->[$P->[$_]] } 0 .. $N;

    foreach my $i (1 .. $N) {
        foreach my $k (0 .. $i - 1) {
            $x[$i] -= $A->[$i][$k] * $x[$k];
        }
    }

    for (my $i = $N ; $i >= 0 ; --$i) {
        foreach my $k ($i + 1 .. $N) {
            $x[$i] -= $A->[$i][$k] * $x[$k];
        }
        $x[$i] /= $A->[$i][$i];
    }

    return \@x;
}

sub invert {
    my ($matrix) = @_;

    my ($N, $A, $P) = _LUP_decompose($matrix);

    my @I;

    foreach my $j (0 .. $N) {
        foreach my $i (0 .. $N) {

            $I[$i][$j] = ($P->[$i] == $j) ? 1 : 0;

            foreach my $k (0 .. $i - 1) {
                $I[$i][$j] -= $A->[$i][$k] * $I[$k][$j];
            }
        }

        for (my $i = $N ; $i >= 0 ; --$i) {

            foreach my $k ($i + 1 .. $N) {
                $I[$i][$j] -= $A->[$i][$k] * $I[$k][$j];
            }

            $I[$i][$j] /= $A->[$i][$i] // return [[]];
        }
    }

    return \@I;
}

sub determinant {
    my ($matrix) = @_;

    my ($N, $A, $P) = _LUP_decompose($matrix);

    my $det = $A->[0][0] // return 1;

    foreach my $i (1 .. $N) {
        $det *= $A->[$i][$i];
    }

    if (($P->[$N + 1] - $N) % 2 == 0) {
        $det *= -1;
    }

    return $det;
}

#
## Examples
#

# Defining a matrix

my $A = [
    [2, -1,  5,  1],
    [3,  2,  2, -6],
    [1,  3,  3, -1],
    [5, -2, -3,  3],
];

# Determinant of a matrix
say "det(A) = ", determinant($A);

# Solve a system of linear equations
my $v = [-3, -32, -47, 49];
say '(', join(', ', @{solve($A, $v)}), ')';

# Invert a matrix
my $inv = invert($A);
say join(",\n", map { '[' . join(', ', map { sprintf('%8s', $_) } @$_) . ']' } @$inv);

__END__
det(A) = 684

(2, -12, -4, 1)

[   4/171,   11/171,   10/171,     8/57],
[ -55/342,  -23/342,  119/342,     2/57],
[ 107/684,   -5/684,   11/684,   -7/114],
[   7/684, -109/684,  103/684,    7/114]
