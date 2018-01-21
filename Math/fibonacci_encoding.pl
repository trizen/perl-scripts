#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 January 2018
# https://github.com/trizen

# Encode positive integers in binary format, using the Fibonacci numbers.

# Example:
#   30 = 10100010 = 1×21 + 0×13 + 1×8 + 0×5 + 0×3 + 0×2 + 1×1 + 0×1

# See also:
#   https://projecteuler.net/problem=473
#   https://en.wikipedia.org/wiki/Fibonacci_coding
#   https://en.wikipedia.org/wiki/Zeckendorf%27s_theorem
#   https://en.wikipedia.org/wiki/Golden_ratio_base

use 5.010;
use strict;
use warnings;

use ntheory qw(lucasu);
use experimental qw(signatures);

sub fib ($n) {
    lucasu(1, -1, $n);
}

sub fibonacci_encoding ($n) {
    return '0' if ($n == 0);

    my $phi = sqrt(1.25) + 0.5;
    my $log = int(log($n * sqrt(5)) / log($phi));

    my ($f1, $f2) = (fib($log), fib($log - 1));

    if ($f1 + $f2 <= $n) {
        ($f1, $f2) = ($f1 + $f2, $f1);
    }

    my $enc = '';

    while ($f1 > 0) {

        if ($n >= $f1) {
            $n -= $f1;
            $enc .= '1';
        }
        else {
            $enc .= '0';
        }

        ($f1, $f2) = ($f2, $f1 - $f2);
    }

    return $enc;
}

sub fibonacci_decoding($enc) {

    my $len = length($enc);
    my ($f1, $f2) = (fib($len), fib($len - 1));

    my $dec = 0;

    foreach my $i (0 .. $len - 1) {
        my $bit = substr($enc, $i, 1);
        $dec += $f1 if $bit;
        ($f1, $f2) = ($f2, $f1 - $f2);
    }

    return $dec;
}

say fibonacci_encoding(30);            #=> 10100010
say fibonacci_decoding('10100010');    #=> 30

say fibonacci_decoding(fibonacci_encoding(144));        #=> 144
say fibonacci_decoding(fibonacci_encoding(144 - 1));    #=> 143
say fibonacci_decoding(fibonacci_encoding(144 + 1));    #=> 145

# Transparent support for arbitrary large integers
say fibonacci_decoding(fibonacci_encoding('81923489126412312421758612841248123'));

# Verify the encoding/decoding algorithm
foreach my $n (0 .. 10000) {
    if (fibonacci_decoding(fibonacci_encoding($n)) != $n) {
        die "Error for $n";
    }
}
