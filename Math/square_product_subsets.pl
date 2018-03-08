#!/usr/bin/perl

# Find subsets of integers whose product is a square, using Gaussian elimination on a GF(2) matrix of vector exponents.

# Code inspired by:
#   https://github.com/martani/Quadratic-Sieve/blob/master/matrix.c

# See also:
#   https://btravers.weebly.com/uploads/6/7/2/9/6729909/quadratic_sieve_slides.pdf

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use List::Util qw(first);
use ntheory qw(factor_exp prime_count);
use Math::AnyNum qw(:overload is_square);

sub getbit ($n, $k) {
    ($n >> $k) & 1;
}

sub setbit ($n, $k) {
    (1 << $k) | $n;
}

sub gaussian_elimination ($rows, $n) {

    my @A = @$rows;
    my $m = $#A;
    my @I = map { 1 << $_ } 0 .. $m;

    my $nrow = -1;
    my $mcol = $m < $n ? $m : $n;

    foreach my $col (0 .. $mcol) {
        my $npivot = -1;

        foreach my $row ($nrow+1 .. $m) {
            if (getbit($A[$row], $col)) {
                $npivot = $row;
                $nrow++;
                last;
            }
        }

        next if ($npivot == -1);

        if ($npivot != $nrow) {
            @A[$npivot, $nrow] = @A[$nrow, $npivot];
            @I[$npivot, $nrow] = @I[$nrow, $npivot];
        }

        foreach my $row ($nrow+1 .. $m) {
            if (getbit($A[$row], $col)) {
                $A[$row] ^= $A[$nrow];
                $I[$row] ^= $I[$nrow];
            }
        }
    }

    return (\@A, \@I);
}

sub exponents_signature(@factors) {
    my $sig = 0;

    foreach my $p (@factors) {
        if ($p->[1] & 1) {
            $sig = setbit($sig, prime_count($p->[0]) - 1);
        }
    }

    return $sig;
}

sub find_square_subsets(@set) {

    my $max_prime = 2;

    my @rows;
    foreach my $n (@set) {
        my @factors = factor_exp($n);

        if (@factors) {
            my $p = $factors[-1][0];
            $max_prime = $p if ($p > $max_prime);
        }

        push @rows, exponents_signature(@factors);
    }

    if (@rows < prime_count($max_prime)) {
        push @rows, (0) x (prime_count($max_prime) - @rows + 1);
    }

    my ($A, $I) = gaussian_elimination(\@rows, prime_count($max_prime) - 1);

    my $LR = (first { $A->[-$_] } 1 .. @$A) - 1;

    my @square_subsets;

    foreach my $solution (@{$I}[@$I - $LR .. $#$I]) {

        my @terms;
        my $prod = 1;

        foreach my $i (0 .. $#set) {
            if (getbit($solution, $i)) {

                $prod *= $set[$i];

                push @terms, $set[$i];
                push @square_subsets, [@terms] if is_square($prod);
            }
        }
    }

    return @square_subsets;
}

my @Q = (
    10, 97, 24, 35, 75852, 54, 12, 13, 11,
    33, 37, 48, 57, 58, 63, 68, 377, 15,
    20, 26, 7, 3, 17, 29, 43, 41, 4171, 78
);

#@Q = (10, 24, 35, 52, 54, 78);

my @S = find_square_subsets(@Q);

foreach my $solution (@S) {
    say join(' ', @$solution);
}

__END__
12 48
10 24 35 12 63
24 54
24 12 13 58 377
10 24 15
10 24 12 20
24 12 13 26
10 24 35 12 7
12 3
68 17
24 12 58 29
75852 43
12 11 33
97 75852 4171
24 13 78
