#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 October 2017
# https://github.com/trizen

# Algorithm for computing a Fibonacci polynomial modulo m.

#   (Sum_{k=1..n} (fibonacci(k) * x^k)) (mod m)

# See also:
#   https://projecteuler.net/problem=435

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(addmod mulmod powmod factor_exp chinese);

sub modular_fibonacci_polynomial ($n, $x, $m) {

    my @chinese;
    foreach my $p (factor_exp($m)) {

        my $pp = $p->[0]**$p->[1];

        my $sum = 0;
        my ($f1, $f2) = (0, 1);

        my @array;
        foreach my $k (1 .. $n) {

            $sum = addmod($sum, mulmod($f2, powmod($x, $k, $pp), $pp), $pp);

            push @array, $sum;

            ($f1, $f2) = ($f2, addmod($f1, $f2, $pp));

            if ($f1 == 0 and $f2 == 1 and $k > 20 and
                    join(' ', @array[9              .. $#array/2])
                 eq join(' ', @array[$#array/2 + 10 .. $#array])
            ) {
                $sum = $array[($n % $k) - 1];
                last;
            }
        }

        push @chinese, [$sum, $pp];
    }

    return chinese(@chinese);
}

say modular_fibonacci_polynomial(7,      11, 100000);        #=> 57683
say modular_fibonacci_polynomial(10**15, 13, 6227020800);    #=> 4631902275
