#!/usr/bin/perl

# Author: Trizen
# Date: 13 June 2022
# https://github.com/trizen

# Find the factors of a Gaussian integer.

# See also:
#   https://www.alpertron.com.ar/GAUSSIAN.HTM
#   https://en.wikipedia.org/wiki/Table_of_Gaussian_integer_factorizations

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub gaussian_mul ($xa, $xb, $ya, $yb) {
    ($xa * $ya - $xb * $yb, $xa * $yb + $xb * $ya)
}

sub gaussian_div ($xa, $xb, $ya, $yb) {    # floor division
    my $t = $ya * $ya + $yb * $yb;
    (
        divint($ya * $t * $xa - $t * -$yb * $xb, $t * $t),
        divint($ya * $t * $xb + $t * -$yb * $xa, $t * $t)
    );
}

sub gaussian_is_div ($xa, $xb, $ya, $yb) {
    my ($ta, $tb) = gaussian_mul($ya, $yb, gaussian_div($xa, $xb, $ya, $yb));
    $xa - $ta == 0 and $xb - $tb == 0;
}

sub primitive_sum_of_two_squares ($p) {

    if ($p == 2) {
        return (1, 1);
    }

    my $s = sqrtmod(-1, $p) || return;
    my $q = $p;

    while ($s * $s > $p) {
        ($s, $q) = ($q % $s, $s);
    }

    ($s, $q % $s);
}

sub gaussian_factors ($x, $y = 0) {

    return if ($x == 0 and $y == 0);

    my $n = ($x * $x + $y * $y);
    my @factors;

    foreach my $pe (factor_exp($n)) {
        my ($p, $e) = @$pe;

        if ($p == 2) {
            while (gaussian_is_div($x, $y, 1, 1)) {
                push @factors, [1, 1];
                ($x, $y) = gaussian_div($x, $y, 1, 1);
            }
        }
        elsif ($p % 4 == 3) {
            while (gaussian_is_div($x, $y, $p, 0)) {
                push @factors, [$p, 0];
                ($x, $y) = gaussian_div($x, $y, $p, 0);
            }
        }
        elsif ($p % 4 == 1) {
            my ($a, $b) = primitive_sum_of_two_squares($p);

            while (gaussian_is_div($x, $y, $a, $b)) {
                push @factors, [$a, $b];
                ($x, $y) = gaussian_div($x, $y, $a, $b);
            }

            while (gaussian_is_div($x, $y, $a, -$b)) {
                push @factors, [$a, -$b];
                ($x, $y) = gaussian_div($x, $y, $a, -$b);
            }
        }
    }

    if ($x == 1 and $y == 0) {
        ## ok
    }
    else {
        push @factors, [$x, $y];
    }

    @factors = sort {
        ($a->[0] <=> $b->[0]) ||
        ($a->[1] <=> $b->[1])
    } @factors;

    my %count;
    $count{join(' ', @$_)}++ for @factors;

    my %seen;
    my @factor_exp =
      map { [$_, $count{join(' ', @$_)}] }
      grep { !$seen{join(' ', @$_)}++ } @factors;

    return @factor_exp;
}

my $z       = [440, -55];
my @factors = gaussian_factors($z->[0], $z->[1]);

say join(' ', map { '[' . join(', ', @{$_->[0]}) . ']' . ($_->[1] > 1 ? ('^' . $_->[1]) : '') } @factors);

my ($x, $y) = (1, 0);
foreach my $pe (@factors) {
    my ($p, $e) = @$pe;
    for (1 .. $e) {
        ($x, $y) = gaussian_mul($x, $y, $p->[0], $p->[1]);
    }
}

say "Product of factors: [$x, $y]";

__END__
[2, -1] [2, 1]^2 [3, -2] [11, 0]
Product of factors: [440, -55]
