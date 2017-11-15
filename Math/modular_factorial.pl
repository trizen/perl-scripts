#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 21 August 2016
# Website: https://github.com/trizen

# An efficient algorithm for computing factorial of a large number, modulus a larger number.

use 5.020;
use strict;
use integer;
use warnings;

use experimental qw(signatures);
use ntheory qw(invmod powmod forprimes random_prime todigits vecsum);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

# This algorithm uses powers of primes to efficiently
# compute `n! mod k`. It works correctly in all cases.

sub facmod2 ($n, $mod) {

    my $p = 0;
    my $f = 1;

    forprimes {
        if ($p == 1) {
            $f *= $_;
            $f %= $mod;
        }
        else {
            $p = factorial_power($n, $_);
            $f *= powmod($_ % $mod, $p, $mod);
            $f %= $mod;
        }
    } $n;

    $f;
}

# This algorithm is fast and correct only when `mod`
# is larger than `n`, but no more than twice as large.

# Algorithm from:
#   http://stackoverflow.com/questions/9727962/fast-way-to-calculate-n-mod-m-where-m-is-prime

sub facmod1 ($n, $mod) {

    if ($n <= $mod / 2 or $mod <= $n) {
        return facmod2($n, $mod);
    }

    my $f = 1;
    foreach my $k ($n + 1 .. $mod - 1) {
        $f *= $k;
        $f %= $mod;
    }

    (-1 * (invmod($f, $mod) // 0) + $mod) % $mod;
}

foreach my $n (100000 .. 100000 + 10) {
    my $p = random_prime($n, $n * 2 - 1);
    my $f1 = facmod1($n, $p);
    my $f2 = facmod2($n, $p);

    if ($f1 != $f2) {
        warn "ERROR: returned values ($f1, $f2) don't agree for ($n, $p)\n";
    }

    printf("%5d! mod %5d = %5d\n", $n, $p, $f1);
}

__END__
100000! mod 124783 = 118955
100001! mod 169987 = 155308
100002! mod 188431 = 22741
100003! mod 100747 = 92927
100004! mod 164251 = 42227
100005! mod 117191 = 65606
100006! mod 121327 = 119432
100007! mod 172259 = 152151
100008! mod 176927 = 39009
100009! mod 135571 = 28311
100010! mod 164093 = 36407
