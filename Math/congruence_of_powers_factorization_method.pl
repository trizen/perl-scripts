#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 July 2019
# https://github.com/trizen

# A simple factorization method, based on congruences of powers.

# Given a composite integer `n`, if we find:
#
#   a^k == b^k (mod n)
#
# for some k >= 2, then gcd(a-b, n) may be a non-trivial factor of n.

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(:all);
use experimental qw(signatures);

sub cgpow_factor ($n, $verbose = 0) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $f = sub ($r, $k, $e) {
        my @factors;

        foreach my $t ($r + $k, $k - $r) {
            my $g = gcd($t, $n);
            if ($g > 1 and $g < $n) {

                if ($verbose) {
                    if ($r == $k) {
                        say "[*] Congruence of powers: a^$e == b^$e (mod n) -> $g";
                    }
                    else {
                        say "[*] Congruence of powers: $k^$e == $r^$e (mod n) -> $g";
                    }
                }

                while ($n % $g == 0) {
                    $n /= $g;
                    push @factors, $g;
                }
            }
        }

        @factors;
    };

    my @params;
    my $orig = $n;

    # In practice, we can check only the range `2 <= e < min(50, log_2(n))`
    for my $e (2 .. logint($n, 2)) {

        my $root = rootint($n, $e);

        if ($root + 1 >= ~0) {
            $root = Math::GMPz->new("$root");
        }

        for my $j (1, 0) {

            my $k = $root + $j;
            my $u = powmod($k, $e, $n);

            if (is_power($u, $e, \my $r)) {

                if (!ref($k) and $r + $k >= ~0) {
                    $r = Math::GMPz->new("$r");
                }

                push @params, [$r, $k, $e];
            }

            if (is_power($n - $u, $e, \my $r)) {

                if (!ref($k) and $r + $k >= ~0) {
                    $r = Math::GMPz->new("$r");
                }

                push @params, [$r, $k, $e];
            }
        }
    }

    my @factors;

    foreach my $args (@params) {
        push @factors, $f->(@$args);
    }

    push @factors, $orig / vecprod(@factors);
    return sort { $a <=> $b } @factors;
}

if (@ARGV) {
    say join ', ', cgpow_factor($ARGV[0], 1);
    exit;
}

say join ' * ', cgpow_factor(powint(2,  256) - 1);
say join ' * ', cgpow_factor(powint(10, 120) + 1);
say join ' * ', cgpow_factor(powint(10, 120) - 1);
say join ' * ', cgpow_factor(powint(10, 120) - 25);
say join ' * ', cgpow_factor(powint(10, 105) - 1);
say join ' * ', cgpow_factor(powint(10, 105) + 1);
say join ' * ', cgpow_factor(powint(10, 120) - 2134 * 2134);
say join ' * ', cgpow_factor((powint(2, 128) - 1) * (powint(2, 256) - 1));
say join ' * ', cgpow_factor(powint(powint(4, 64) - 1, 3) - 1);

__END__
3 * 5 * 17 * 257 * 65537 * 4294967297 * 18446744073709551617 * 340282366920938463463374607431768211457
9999999900000001 * 10000000000000000000000000000000000000001 * 10000000099999999999999989999999899999999000000000000000100000001
3 * 31 * 3367 * 2906161 * 109889011 * 99999999990000000001 * 99999999999999999999 * 1000000000000000000000000000000000000000000000000000000000001
5 * 199999999999999999999999999999999999999999999999999999999999 * 1000000000000000000000000000000000000000000000000000000000005
3 * 90090991 * 33333336666667 * 99999999999999999999999999999999999 * 1109988789001111109989898989900111110998878900111
109889011 * 99999990000001 * 100000000000000000000000000000000001 * 910009191000909089989898989899909091000919100091
54 * 18518518518518518518518518518518518518518518518518518518479 * 1000000000000000000000000000000000000000000000000000000002134
340282366920938463463374607431768211455 * 340282366920938463463374607431768211455 * 340282366920938463463374607431768211457
2 * 170141183460469231731687303715884105727 * 115792089237316195423570985008687907852929702298719625575994209400481361428481
