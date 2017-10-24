#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 October 2017
# https://github.com/trizen

# Algorithm for representing a positive integer `n` as a sum of an even number of positive squares.

# Example:
#   9925 = 5^2 * 397
#   9925 = (3^2 + 4^2) * (6^2 + 19^2)
#   9925 = 18^2 + 24^2 + 57^2 + 76^2

# This algorithm is efficient when the factorization of `n` is known.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Set::Product::XS qw(product);
use ntheory qw(sqrtmod factor_exp vecprod vecsum);

sub primitive_sum_of_two_squares ($p) {

    if ($p == 2) {
        return [1, 1];
    }

    my $s = sqrtmod($p - 1, $p) || return;
    my $q = $p;

    while ($s * $s > $p) {
        ($s, $q) = ($q % $s, $s);
    }

    return [$s, $q % $s];
}

sub sum_of_squares_solution ($n) {

    my @primitives;
    my $left_prod = 1;

    foreach my $f (factor_exp($n)) {
        if ($f->[0] % 4 == 3) {            # p = 3 (mod 4)
            $f->[1] % 2 == 0 or return;    # power must be even
            $left_prod *= $f->[0]**($f->[1] >> 1);
        }
        elsif ($f->[0] == 2) {             # p = 2
            if ($f->[1] % 2 == 0) {        # power is even
                $left_prod *= $f->[0]**($f->[1] >> 1);
            }
            else {                         # power is odd
                push @primitives, [1, 1];
                $left_prod *= $f->[0]**(($f->[1] - 1) >> 1);
            }
        }
        else {                             # p = 1 (mod 4)
            push @primitives, primitive_sum_of_two_squares($f->[0]**$f->[1]);
        }
    }

    my @solution;

    product {
        push @solution, vecprod($left_prod, @_);
    } @primitives;

    return sort { $a <=> $b } @solution;
}

foreach my $n (1..1e5) {
    (my @solution = sum_of_squares_solution($n)) || next;

    say "$n = ", join(' + ', map { "$_^2" } @solution);

    # Verify solution
    if ((my $sum = vecsum(map { $_**2 } @solution)) != $n) {
        die "error for $n -> $sum";
    }
}

__END__
99872 = 156^2 + 156^2 + 160^2 + 160^2
99873 = 108^2 + 297^2
99874 = 116^2 + 116^2 + 191^2 + 191^2
99877 = 79^2 + 306^2
99881 = 5^2 + 316^2
99892 = 28^2 + 32^2 + 42^2 + 48^2 + 112^2 + 128^2 + 168^2 + 192^2
99901 = 26^2 + 315^2
99905 = 8^2 + 12^2 + 16^2 + 20^2 + 24^2 + 28^2 + 30^2 + 40^2 + 42^2 + 56^2 + 60^2 + 70^2 + 84^2 + 105^2 + 140^2 + 210^2
99908 = 208^2 + 238^2
99909 = 39^2 + 66^2 + 156^2 + 264^2
99914 = 111^2 + 111^2 + 194^2 + 194^2
99917 = 24^2 + 30^2 + 196^2 + 245^2
99920 = 60^2 + 120^2 + 128^2 + 256^2
99929 = 220^2 + 227^2
99937 = 36^2 + 96^2 + 105^2 + 280^2
99944 = 124^2 + 124^2 + 186^2 + 186^2
99945 = 42^2 + 84^2 + 135^2 + 270^2
99954 = 144^2 + 144^2 + 171^2 + 171^2
99956 = 10^2 + 316^2
99961 = 156^2 + 275^2
99965 = 48^2 + 96^2 + 133^2 + 266^2
99970 = 24^2 + 24^2 + 36^2 + 36^2 + 48^2 + 48^2 + 50^2 + 50^2 + 72^2 + 72^2 + 75^2 + 75^2 + 100^2 + 100^2 + 150^2 + 150^2
99972 = 174^2 + 264^2
99973 = 10^2 + 17^2 + 160^2 + 272^2
99976 = 82^2 + 82^2 + 208^2 + 208^2
99977 = 16^2 + 64^2 + 75^2 + 300^2
99985 = 26^2 + 52^2 + 139^2 + 278^2
99986 = 68^2 + 68^2 + 213^2 + 213^2
99989 = 217^2 + 230^2
99994 = 16^2 + 16^2 + 30^2 + 30^2 + 104^2 + 104^2 + 195^2 + 195^2
99997 = 171^2 + 266^2
100000 = 152^2 + 152^2 + 164^2 + 164^2
