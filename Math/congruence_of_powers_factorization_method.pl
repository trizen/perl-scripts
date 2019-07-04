#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 July 2019
# https://github.com/trizen

# A simple factorization method, by finding congruences of powers.

# Given a composite integer `n`, if we find:
#
#   a^k == b^k (mod n)
#
# for some k >= 2 and a != b, then gcd(a-b, n) is a non-trivial factor of n.

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

    my $N = $n;    # original n
    my @factors;

    for my $e (2 .. logint($N, 2)) {

        my $root = rootint($N, $e);

        if ($root + 1 >= ~0) {
            $root = Math::GMPz->new("$root");
        }

        for my $j (1, 0) {

            my $k = $root + $j;
            my $u = powmod($k, $e, $N);

            if (is_power($u, $e, \my $r)) {

                if (!ref($k) and $r + $k >= ~0) {
                    $r = Math::GMPz->new("$r");
                }

                foreach my $t ($r + $k, $k - $r) {
                    my $g = gcd($t, $n);
                    if ($g > 1 and $g < $n) {

                        if ($verbose) {
                            say "[-] Congruence: a^$e == b^$e -> $g";
                        }

                        while ($n % $g == 0) {
                            $n /= $g;
                            push @factors, $g;
                        }
                    }
                }
            }

            if (is_power($N - $u, $e, \my $r)) {

                if (!ref($k) and $r + $k >= ~0) {
                    $r = Math::GMPz->new("$r");
                }

                foreach my $t ($r + $k, $k - $r) {
                    my $g = gcd($t, $n);
                    if ($g > 1 and $g < $n) {

                        if ($verbose) {
                            say "[+] Congreunce: a^$e == b^$e -> $g";
                        }

                        while ($n % $g == 0) {
                            $n /= $g;
                            push @factors, $g;
                        }
                    }
                }
            }
        }
    }

    push @factors, $N / vecprod(@factors);
    return sort { $a <=> $b } @factors;
}

if (@ARGV) {
    say join ', ', cgpow_factor($ARGV[0], 1);
    exit;
}

say '2^256  - 1         = ', join ' * ', cgpow_factor(powint(2,  256) - 1);
say '10^120 + 1         = ', join ' * ', cgpow_factor(powint(10, 120) + 1);
say '10^120 - 1         = ', join ' * ', cgpow_factor(powint(10, 120) - 1);
say '10^120 - 25        = ', join ' * ', cgpow_factor(powint(10, 120) - 25);
say '10^105 - 1         = ', join ' * ', cgpow_factor(powint(10, 105) - 1);
say '10^105 + 1         = ', join ' * ', cgpow_factor(powint(10, 105) + 1);
say '10^120 - 2134^2    = ', join ' * ', cgpow_factor(powint(10, 120) - 2134 * 2134);
say '(2^128-1)(2^256-1) = ', join ' * ', cgpow_factor((powint(2, 128) - 1) * (powint(2, 256) - 1));

__END__
2^256  - 1         = 3 * 5 * 17 * 257 * 65537 * 4294967297 * 18446744073709551617 * 340282366920938463463374607431768211457
10^120 + 1         = 9999999900000001 * 10000000000000000000000000000000000000001 * 10000000099999999999999989999999899999999000000000000000100000001
10^120 - 1         = 3 * 31 * 3367 * 2906161 * 109889011 * 99999999990000000001 * 99999999999999999999 * 1000000000000000000000000000000000000000000000000000000000001
10^120 - 25        = 5 * 199999999999999999999999999999999999999999999999999999999999 * 1000000000000000000000000000000000000000000000000000000000005
10^105 - 1         = 3 * 90090991 * 33333336666667 * 99999999999999999999999999999999999 * 1109988789001111109989898989900111110998878900111
10^105 + 1         = 109889011 * 99999990000001 * 100000000000000000000000000000000001 * 910009191000909089989898989899909091000919100091
10^120 - 2134^2    = 54 * 18518518518518518518518518518518518518518518518518518518479 * 1000000000000000000000000000000000000000000000000000000002134
(2^128-1)(2^256-1) = 340282366920938463463374607431768211455 * 340282366920938463463374607431768211455 * 340282366920938463463374607431768211457
