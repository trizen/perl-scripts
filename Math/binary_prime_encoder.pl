#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 September 2016
# https://github.com/trizen

# Encode prime numbers bellow a certain limit into a large number.

# Example for primes bellow 7:
#
#   x = 110101
#
# where each (k+1)-th bit in x is 1 when (k+1) is prime.
#
# This can be illustrated as:
#   [1, 1, 0, 1, 0, 1]
#   [2, 3, 4, 5, 6, 7]
#
# The binary number 110101 is represented by 53 in base 10.

# See also: https://oeis.org/A072762
#           https://en.wikipedia.org/wiki/Prime_constant

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

use Memoize qw(memoize);
use Math::AnyNum qw(:overload);
use ntheory qw(is_prime prev_prime);

memoize('_encode');

sub _encode {
    my ($n) = @_;
    $n < 2 ? 0 : 2 * _encode($n - 1) + (is_prime($n) ? 1 : 0);
}

sub encode_primes {
    my ($limit) = @_;
    _encode(prev_prime($limit + 1));
}

sub decode_primes {
    my ($n) = @_;

    my $pow   = $n >> 1;
    my $shift = 1;

    while (($pow + 1) & $pow) {
        $pow |= $pow >> $shift;
        $shift <<= 1;
    }

    $pow += 1;

    my @primes;
    my $p = 2;

    while ($pow) {
        if ($n & $pow) {
            push @primes, $p;
        }
        ++$p;
        $pow >>= 1;
    }

    @primes;
}

say "Encoded primes bellow 100: ", encode_primes(100);
say "Decoded primes bellow 100: ", join(' ', decode_primes(encode_primes(100)));

__END__
Encoded primes bellow 100: 65709066564613793476872782081
Decoded primes bellow 100: 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97
