#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 January 2017
# https://github.com/trizen

# A simple example for the RSA algorithm.

use 5.010;
use strict;
use warnings;

use ntheory qw(random_strong_prime);

my $p = random_strong_prime(2048);
my $q = random_strong_prime(2048);

my $n = ($p * $q);

my $phi = ($p - 1) * ($q - 1);

sub gcd($$) {
    my ($u, $v) = @_;
    while ($v) {
        ($u, $v) = ($v, $u % $v);
    }
    return abs($u);
}

my $e = 0;
for (my $k = 16 ; gcd($e, $phi) != 1 ; ++$k) {
    $e = 2**$k + 1;
}

sub invmod($$) {
    my ($a, $n) = @_;
    my ($t, $nt, $r, $nr) = (0, 1, $n, $a % $n);
    while ($nr != 0) {
        my $quot = int(($r - ($r % $nr)) / $nr);
        ($nt, $t) = ($t - $quot * $nt, $nt);
        ($nr, $r) = ($r - $quot * $nr, $nr);
    }
    return if $r > 1;
    $t += $n if $t < 0;
    return $t;
}

my $d = invmod($e, $phi);

sub expmod($$$) {
    my ($a, $b, $n) = @_;
    my $c = 1;
    do {
        ($c *= $a) %= $n if $b & 1;
        ($a *= $a) %= $n;
    } while ($b >>= 1);
    return $c;
}

my $m = 1234;
my $c = expmod($m, $e, $n);
my $M = expmod($c, $d, $n);
say $M;
