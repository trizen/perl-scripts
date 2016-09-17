#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 September 2016
# Website: https://github.com/trizen

# A provable (but not very efficient) primality test.

use 5.010;
use strict;
use integer;
use warnings;

# Based on a derivation of the theorem:
#    (p-1)! + 1 (mod p) = 0         ; for any prime p

# The derivation is:
#   (k-1)! (mod n) = 0              ; for any composite n with some k < n

use ntheory qw(powmod forprimes);

sub power {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    $s;
}

sub is_provable_prime {
    my ($n, $mod) = @_;

    return 0 if $n <= 1;
    return 0 if $n == 4;

    my $f = 1;

    eval {
        forprimes {

            $f *= powmod($_, power($n - 1, $_), $n);
            $f %= $n;

            $f || die "composite at $_\n";
        }
        ($n - 1);
    };

    $@ ? 0 : 1;
}

say is_provable_prime(267_391);       # prime
say is_provable_prime(23_498_729);    # composite
