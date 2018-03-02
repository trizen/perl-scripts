#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 02 March 2018
# https://github.com/trizen

# Find representations for a given number (n) as a sum of three triangular
# numbers, where the index (k) of one triangular number is also given.

# Equivalent with finding solutions to `x` and `y` in the following equation:
#
#   n = k*(k+1)/2 + x*(x+1)/2 + y*(y+1)/2
#
# where `n` and `k` are given.

# Example:
#   n = 1234
#   k = 42

# Solutions:
#   1234 = 42*(42+1)/2 +  3*( 3+1)/2 + 25*(25+1)/2
#   1234 = 42*(42+1)/2 + 10*(10+1)/2 + 23*(23+1)/2
#   1234 = 42*(42+1)/2 + 12*(12+1)/2 + 22*(22+1)/2

# When k=0, `n` will be represented as a sum of two triangular numbers only (if possible):
#   1234 = 17*(17+1)/2 + 46*(46+1)/2

# See also:
#   https://projecteuler.net/problem=621
#   https://trizenx.blogspot.com/2017/10/representing-integers-as-sum-of-two.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Set::Product::XS qw(product);
use ntheory qw(sqrtmod factor_exp chinese is_polygonal);

sub sum_of_two_squares ($n) {

    $n == 0 and return [0, 0];

    my $prod1 = 1;
    my $prod2 = 1;

    my @prime_powers;

    foreach my $f (factor_exp($n)) {
        if ($f->[0] % 4 == 3) {            # p = 3 (mod 4)
            $f->[1] % 2 == 0 or return;    # power must be even
            $prod2 *= $f->[0]**($f->[1] >> 1);
        }
        elsif ($f->[0] == 2) {             # p = 2
            if ($f->[1] % 2 == 0) {        # power is even
                $prod2 *= $f->[0]**($f->[1] >> 1);
            }
            else {                         # power is odd
                $prod1 *= $f->[0];
                $prod2 *= $f->[0]**(($f->[1] - 1) >> 1);
                push @prime_powers, [$f->[0], 1];
            }
        }
        else {                             # p = 1 (mod 4)
            $prod1 *= $f->[0]**$f->[1];
            push @prime_powers, $f;
        }
    }

    $prod1 == 1 and return [$prod2, 0];
    $prod1 == 2 and return [$prod2, $prod2];

    my %table;
    foreach my $f (@prime_powers) {
        my $pp = $f->[0]**$f->[1];
        my $r = sqrtmod($pp - 1, $pp);
        push @{$table{$pp}}, [$r, $pp], [$pp - $r, $pp];
    }

    my @square_roots;

    product {
        push @square_roots, chinese(@_);
    } values %table;

    my @solutions;

    foreach my $r (@square_roots) {

        my $s = $r;
        my $q = $prod1;

        while ($s * $s > $prod1) {
            ($s, $q) = ($q % $s, $s);
        }

        push @solutions, [$prod2 * $s, $prod2 * ($q % $s)];
    }

    foreach my $f (@prime_powers) {
        for (my $i = $f->[1] % 2 ; $i < $f->[1] ; $i += 2) {

            my $sq = $f->[0]**(($f->[1] - $i) >> 1);
            my $pp = $f->[0]**($f->[1] - $i);

            push @solutions, map {
                [map { $sq * $prod2 * $_ } @$_]
            } __SUB__->($prod1 / $pp);
        }
    }

    return sort { $a->[0] <=> $b->[0] } do {
        my %seen;
        grep { !$seen{$_->[0]}++ } map {
            [sort { $a <=> $b } @$_]
        } @solutions;
    };
}

sub sum_of_triangles ($n, $k) {

    my $z = ($n - $k * ($k + 1) / 2) * 8 + 1;

    return if $z <= 0;

    my @result;
    my @solutions = sum_of_two_squares($z + 1);

    foreach my $s (@solutions) {

        is_polygonal(($s->[0]**2 - 1)/8, 3, \my $x);
        is_polygonal(($s->[1]**2 - 1)/8, 3, \my $y);

        push @result, [$x, $y];
    }

    return @result;
}

my $n = 1234;
my $k = 42;

my @solutions = sum_of_triangles($n, $k);

foreach my $s (@solutions) {
    say "$n = $k*($k+1)/2 + $s->[0]*($s->[0]+1)/2 + $s->[1]*($s->[1]+1)/2";
}
