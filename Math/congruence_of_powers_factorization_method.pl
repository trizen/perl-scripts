#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 04 July 2019
# Edit: 22 March 2022
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
use Math::AnyNum qw(ipow);
use experimental qw(signatures);

use constant {
              MIN_FACTOR => 1e6,    # ignore small factors
              LOG_BRANCH => 1,      # true to use the log branch in addition to the root branch
              FULL_RANGE => 0,      # true to use the full range from 0 to log_2(n)
             };

sub perfect_power ($n) {
    return 1 if ($n == 0);
    return 1 if ($n == 1);
    return is_power($n);
}

sub cgpow_factor ($n, $verbose = 0) {

    my %seen;

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $f = sub ($r, $e1, $k, $e2) {
        my @factors;

        my @divs1 = divisors($e1);
        my @divs2 = divisors($e2);

        foreach my $d1 (@divs1) {
            my $x = $r**$d1;
            foreach my $d2 (@divs2) {
                my $y = $k**$d2;
                foreach my $j (-1, 1) {

                    my $t = $x - $j * $y;
                    my $g = Math::GMPz->new(gcd($t, $n));

                    if ($g > MIN_FACTOR and $g < $n and !$seen{$g}++) {

                        if ($verbose) {
                            if ($r == $k) {
                                say "[*] Congruence of powers: a^$d1 == b^$d2 (mod n) -> $g";
                            }
                            else {
                                say "[*] Congruence of powers: $r^$d1 == $k^$d2 (mod n) -> $g";
                            }
                        }

                        push @factors, $g;
                    }
                }
            }
        }

        @factors;
    };

    my @params;
    my $orig  = $n;
    my $const = 64;

    my @range;

    if (FULL_RANGE) {
        @range = reverse(2 .. logint($n, 2));
    }
    else {
        @range = reverse(2 .. vecmin($const, logint($n, 2)));
    }

    my $process = sub ($root, $e) {

        for my $j (1, 0) {

            my $k = $root + $j;
            my $u = powmod($k, $e, $n);

            foreach my $z ($u, $n - $u) {

                if (my $t = perfect_power($z)) {

                    my $r1 = rootint($z, $t);
                    ##my $r2 = rootint($z, $e);

                    push @params, [Math::GMPz->new($r1), $t, Math::GMPz->new($k), $e];
                    ##push @params, [Math::GMPz->new($r2), $e, Math::GMPz->new($k), $e];
                }
            }
        }
    };

    for my $e (@range) {
        my $root = Math::GMPz->new(rootint($n, $e));
        $process->($root, $e);
    }

    if (LOG_BRANCH) {

        for my $root (@range) {
            my $e = Math::GMPz->new(logint($n, $root));
            $process->($root, $e);
        }

        my %seen_param;
        @params = grep { !$seen_param{join(' ', @$_)}++ } @params;
    }

    my @divisors;

    foreach my $args (@params) {
        push @divisors, $f->(@$args);
    }

    @divisors = sort { $a <=> $b } @divisors;

    my @factors;
    foreach my $d (@divisors) {
        my $g = Math::GMPz->new(gcd($n, $d));

        if ($g > MIN_FACTOR and $g < $n) {
            while ($n % $g == 0) {
                $n /= $g;
                push @factors, $g;
            }
        }
    }

    push @factors, $orig / vecprod(@factors);
    return sort { $a <=> $b } @factors;
}

if (@ARGV) {
    say join ', ', cgpow_factor($ARGV[0], 1);
    exit;
}

# Large roots
say join ' * ', cgpow_factor(ipow(1009,     24) + ipow(29,  12));
say join ' * ', cgpow_factor(ipow(1009,     24) - ipow(29,  12));
say join ' * ', cgpow_factor(ipow(59388821, 12) - ipow(151, 36));

say '-' x 80;

# Small roots
say join ' * ', cgpow_factor(ipow(2,  256) - 1);
say join ' * ', cgpow_factor(ipow(10, 120) + 1);
say join ' * ', cgpow_factor(ipow(10, 120) - 1);
say join ' * ', cgpow_factor(ipow(10, 120) - 25);
say join ' * ', cgpow_factor(ipow(10, 105) - 1);
say join ' * ', cgpow_factor(ipow(10, 105) + 1);
say join ' * ', cgpow_factor(ipow(10, 120) - 2134 * 2134);
say join ' * ', cgpow_factor((ipow(2, 128) - 1) * (ipow(2, 256) - 1));
say join ' * ', cgpow_factor(ipow(ipow(4, 64) - 1, 3) - 1);

say join ' * ', cgpow_factor((ipow(2, 128) - 1) * (ipow(3, 128) - 1));
say join ' * ', cgpow_factor((ipow(5, 48) + 1) * (ipow(3, 120) + 1));
say join ' * ', cgpow_factor((ipow(5, 48) + 1) * (ipow(3, 120) - 1));
say join ' * ', cgpow_factor((ipow(5, 48) - 1) * (ipow(3, 120) + 1));

__END__
1074309286591662655506002 * 1154140443257087164049583013000044736320575461201
1018052 * 1018110 * 1699854 * 45120343 * 14006607073 * 1036518447751 * 1074309285719975471632201
1038960 * 5594587 * 23044763 * 61015275368249 * 534765538858459 * 4033015478857732019 * 109215797426552565244488121
--------------------------------------------------------------------------------
4294967295 * 4294967297 * 18446744073709551617 * 340282366920938463463374607431768211457
100000001 * 9999999900000001 * 99999999000000009999999900000001 * 10000000099999999999999989999999899999999000000000000000100000001
50851 * 1000001 * 1040949 * 1110111 * 1450031 * 2463661 * 2906161 * 99009901 * 99990001 * 165573604901641 * 9999000099990001 * 100009999999899989999000000010001
999999999999999999999999999999999999999999999999999999999995 * 1000000000000000000000000000000000000000000000000000000000005
1111111 * 1269729 * 787569631 * 900900990991 * 900009090090909909099991 * 1109988789001111109989898989900111110998878900111
1313053 * 10000001 * 1236109099 * 61549824583 * 1099988890111109888900011 * 910009191000909089989898989899909091000919100091
999999999999999999999999999999999999999999999999999999997866 * 1000000000000000000000000000000000000000000000000000000002134
1114129 * 2451825 * 6700417 * 16843009 * 1103806595329 * 18446744073709551617 * 18446744073709551617 * 340282366920938463463374607431768211457
340282366920938463463374607431768211454 * 115792089237316195423570985008687907852929702298719625575994209400481361428481
7913 * 1109760 * 43046722 * 84215045 * 4294967297 * 926510094425921 * 18446744073709551617 * 1716841910146256242328924544641
1273028 * 29423041 * 145127617 * 240031591394168814433 * 4892905104216215334417146433664153647610647561409
1013824 * 1236031 * 1519505 * 43584805 * 47763361 * 1743392201 * 76293945313 * 50446744628921761 * 240031591394168814433
1083264 * 1331139 * 1971881 * 122070313 * 29802322387695313 * 617180487788001154016207027393267755290289744417
