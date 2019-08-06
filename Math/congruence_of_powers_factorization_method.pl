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

    for my $e (reverse 2 .. vecmin($const, logint($n, 2))) {

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

    for my $root (reverse 2 .. vecmin($const, logint($n, 2))) {

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
2 * 6 * 6 * 7 * 10 * 13 * 19 * 31 * 37 * 103 * 349 * 353 * 523 * 33937 * 5678713 * 45120343 * 14006607073 * 1074309285719975471632201
7 * 9 * 16 * 29 * 37 * 43 * 57 * 61 * 65 * 71 * 997 * 1097 * 1861 * 78797 * 28230245413 * 61015275368249 * 85497773607889 * 109215797426552565244488121
--------------------------------------------------------------------------------
3 * 5 * 17 * 257 * 641 * 65537 * 6700417 * 18446744073709551617 * 340282366920938463463374607431768211457
17 * 5882353 * 9999999900000001 * 99999999000000009999999900000001 * 10000000099999999999999989999999899999999000000000000000100000001
3 * 3 * 3 * 7 * 11 * 13 * 31 * 37 * 41 * 61 * 73 * 101 * 137 * 211 * 241 * 271 * 9091 * 9901 * 99009901 * 99990001 * 6280213921 * 165573604901641 * 9999000099990001 * 100009999999899989999000000010001
5 * 15 * 29 * 2298850574712643678160919540229885057471264367816091954023 * 199999999999999999999999999999999999999999999999999999999999
3 * 3 * 3 * 31 * 37 * 41 * 43 * 71 * 239 * 271 * 1933 * 2906161 * 50389065161 * 12676184367477604353521 * 1109988789001111109989898989900111110998878900111
7 * 7 * 11 * 13 * 127 * 211 * 241 * 2161 * 2689 * 9091 * 417900950881 * 1099988890111109888900011 * 910009191000909089989898989899909091000919100091
3 * 6 * 6 * 7 * 7 * 61 * 107 * 167280026764804282368685178989628638340582134493141518903 * 173070266528210453444098303911388023537556247836621668397
15 * 15 * 17 * 17 * 257 * 257 * 641 * 641 * 65537 * 65537 * 6700417 * 6700417 * 18446744073709551617 * 18446744073709551617 * 340282366920938463463374607431768211457
2 * 170141183460469231731687303715884105727 * 115792089237316195423570985008687907852929702298719625575994209400481361428481
