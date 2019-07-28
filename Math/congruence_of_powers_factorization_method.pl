#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 July 2019
# Edit: 28 July 2019
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

    my $f = sub ($r, $e1, $k, $e2) {
        my @factors;

        my @divs1 = divisors($e1);
        my @divs2 = divisors($e2);

        foreach my $d1 (@divs1) {
            my $x = $k**$d1;
            foreach my $d2 (@divs2) {
                my $y = $r**$d2;
                foreach my $j (-1, 1) {

                    my $t = $x - $j * $y;
                    my $g = Math::GMPz->new(gcd($t, $n));

                    if ($g > 1 and $g < $n) {

                        if ($verbose) {
                            if ($r == $k) {
                                say "[*] Congruence of powers: a^$d1 == b^$d2 (mod n) -> $g";
                            }
                            else {
                                say "[*] Congruence of powers: $k^$d1 == $r^$d2 (mod n) -> $g";
                            }
                        }

                        while ($n % $g == 0) {
                            $n /= $g;
                            push @factors, $g;
                        }
                    }
                }
            }
        }

        @factors;
    };

    my @params;
    my $orig  = $n;
    my $const = 100;

    for my $e (2 .. vecmin($const, logint($n, 2))) {

        my $root = Math::GMPz->new(rootint($n, $e));

        for my $j (1, 0) {

            my $k = $root + $j;
            my $u = powmod($k, $e, $n);

            if (is_power($u, $e, \my $r)) {
                push @params, [Math::GMPz->new($r), $e, $k, $e];
            }

            if (is_power($n - $u, $e, \my $r)) {
                push @params, [Math::GMPz->new($r), $e, $k, $e];
            }
        }
    }

    for my $root (2 .. vecmin($const, logint($n, 2))) {

        my $e = Math::GMPz->new(logint($n, $root));

        for my $j (1, 0) {

            my $k = $root + $j;
            my $u = powmod($k, $e, $n);

            if (my $t = is_power($u)) {
                my $r = rootint($n, $t);
                push @params, [Math::GMPz->new($r), $t, Math::GMPz->new($k), $e];
            }

            if (my $t = is_power($n - $u)) {
                my $r = rootint($n, $t);
                push @params, [Math::GMPz->new($r), $t, Math::GMPz->new($k), $e];
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

# Large roots
say join ' * ', cgpow_factor(powint(1009,     24) + powint(29,  12));
say join ' * ', cgpow_factor(powint(1009,     24) - powint(29,  12));
say join ' * ', cgpow_factor(powint(59388821, 12) - powint(151, 36));

say '-' x 80;

# Small roots
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
2 * 241 * 4729 * 6361 * 537154643295831327753001 * 159201409188674992252015489114548201169
2 * 2 * 2 * 31 * 349 * 523 * 4095 * 5678713 * 857286517 * 1233915383 * 1113509674956668989037907206205667802
2 * 2 * 2 * 2 * 3 * 3 * 5 * 13 * 19 * 21 * 43 * 61 * 997 * 28230245413 * 227078691743 * 85497773607889 * 1769442985679221 * 203250599010814323919992393181
--------------------------------------------------------------------------------
15 * 17 * 257 * 65537 * 4294967297 * 18446744073709551617 * 340282366920938463463374607431768211457
9999999900000001 * 10000000000000000000000000000000000000001 * 10000000099999999999999989999999899999999000000000000000100000001
3 * 31 * 3367 * 2906161 * 109889011 * 99999999990000000001 * 99999999999999999999 * 1000000000000000000000000000000000000000000000000000000000001
5 * 199999999999999999999999999999999999999999999999999999999999 * 1000000000000000000000000000000000000000000000000000000000005
3 * 3 * 3 * 31 * 2906161 * 33333336666667 * 11111111111111111111111111111111111 * 1109988789001111109989898989900111110998878900111
7 * 7 * 13 * 109889011 * 156985855573 * 100000000000000000000000000000000001 * 910009191000909089989898989899909091000919100091
2 * 27 * 107 * 173070266528210453444098303911388023537556247836621668397 * 1000000000000000000000000000000000000000000000000000000002134
9 * 113427455640312821154458202477256070485 * 113427455640312821154458202477256070485 * 340282366920938463463374607431768211457
2 * 170141183460469231731687303715884105727 * 115792089237316195423570985008687907852929702298719625575994209400481361428481
