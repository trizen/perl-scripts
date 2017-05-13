#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 September 2016
# https://github.com/trizen

# Encode the first n prime numbers into a large integer.

# See also:
#    http://oeis.org/A135482

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload);
use ntheory qw(nth_prime valuation);

sub encode_primes {
    my ($n) = @_;

    my $sum = 0;
    foreach my $i (1 .. $n) {
        $sum += 1 << nth_prime($i);
    }

    $sum >> 2;
}

sub decode_primes {
    my ($n) = @_;

    my $p = 2;
    my @primes;

    while ($n) {
        if ($n & 1) {
            push @primes, $p;
        }

        my $v = valuation($n, 2) || 1;
        $n >>= $v;
        $p += $v;
    }

    @primes;
}

say "Encoded first 25 primes: ", encode_primes(25);
say "Decoded first 25 primes: ", join(' ', decode_primes(encode_primes(25)));

__END__
Encoded first 25 primes: 39771395718504928067455191595
Decoded first 25 primes: 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97
