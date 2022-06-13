#!/usr/bin/perl

# Author: Trizen
# Date: 13 June 2022
# https://github.com/trizen

# Find the factors and divisors of a Gaussian integer.

# See also:
#   https://oeis.org/A125271
#   https://oeis.org/A078930
#   https://oeis.org/A078910
#   https://oeis.org/A078911
#   https://projecteuler.net/problem=153
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

sub gaussian_divisors ($x, $y = 0) {

    my @d = ([1, 0], [-1, 0], [0, 1], [0, -1]);

    foreach my $pe (gaussian_factors($x, $y)) {
        my ($p,  $e)  = @$pe;
        my ($ra, $rb) = (1, 0);
        my @t;
        for (1 .. $e) {
            ($ra, $rb) = gaussian_mul($ra, $rb, $p->[0], $p->[1]);
            foreach my $u (@d) {
                push @t, [gaussian_mul($u->[0], $u->[1], $ra, $rb)];
            }
        }
        push @d, @t;
    }

    @d = sort {
        ($a->[0] <=> $b->[0]) ||
        ($a->[1] <=> $b->[1])
    } @d;

    my %seen;
    @d = grep { !$seen{join(' ', @$_)}++ } @d;

    return @d;
}

say scalar gaussian_divisors(440, -55);    #=> 96

say join ', ', map {
    scalar grep { $_->[0] > 0 } gaussian_divisors($_, 0)
} 0 .. 30;    # A125271

say join ', ', map {
    vecsum(map { $_->[0] } grep { $_->[0] > 0 } gaussian_divisors($_, 0))
} 0 .. 30;    # A078930

say join ', ', map {
    vecsum(map { $_->[0] } grep { $_->[0] > 0 and $_->[1] > 0 } gaussian_divisors($_, 0))
} 0 .. 30;    # A078911

say join ', ', map {
    vecsum(map { $_->[0] } grep { $_->[0] > 0 or $_->[1] > 0 } gaussian_divisors($_, 0))
} 0 .. 30;    # A078910

my $sum = 0;

foreach my $n (1 .. 1000) {
    $sum += vecsum(map { $_->[0] } grep { $_->[0] > 0 } gaussian_divisors($n, 0));
}

say $sum;     #=> 1752541
