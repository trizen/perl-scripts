#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 June 2019
# https://github.com/trizen

# A simple factorization method for numbers close to a perfect power.

# Very effective for numbers of the form:
#
#   n^k - 1
#
# where k has many divisors.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Math::GMPz;
use ntheory qw(divisors is_power gcd powint rootint vecprod);

sub near_power_factorization ($n, $bound = 10000) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $orig = $n;

    my $f = sub ($r, $e, $k) {

        my @factors;

        foreach my $d (divisors($e)) {
            foreach my $j (1, -1) {

                my $t = $r**$d - $k * $j;
                my $g = gcd($t, $n);

                if ($g > 1 and $g < $n) {
                    while ($n % $g == 0) {
                        $n /= $g;
                        push @factors, $g;
                    }
                }
            }
        }

        push @factors, $orig / vecprod(@factors);
        return sort { $a <=> $b } @factors;
    };

    foreach my $j (1 .. $bound) {
        foreach my $k (1, -1) {

            my $u = $k * $j * $j;

            if ($n + $u > 0) {
                if (my $e = is_power($n + $u)) {
                    my $r = Math::GMPz->new(rootint($n + $u, $e));
                    return $f->($r, $e, $j);
                }
            }
        }
    }

    return $n;
}

if (@ARGV) {
    say join ', ', near_power_factorization($ARGV[0], defined($ARGV[1]) ? $ARGV[1] : ());
    exit;
}

say join ' * ', near_power_factorization(powint(2,  256) - 1);
say join ' * ', near_power_factorization(powint(10, 120) + 1);
say join ' * ', near_power_factorization(powint(10, 120) - 1);
say join ' * ', near_power_factorization(powint(10, 120) - 25);
say join ' * ', near_power_factorization(powint(10, 105) - 1);
say join ' * ', near_power_factorization(powint(10, 105) + 1);
say join ' * ', near_power_factorization(powint(10, 120) - 2134 * 2134);

__END__
3 * 5 * 17 * 257 * 65537 * 4294967297 * 18446744073709551617 * 340282366920938463463374607431768211457
100000001 * 9999999900000001 * 99999999000000009999999900000001 * 10000000099999999999999989999999899999999000000000000000100000001
3 * 9 * 11 * 37 * 91 * 101 * 9091 * 9901 * 10001 * 11111 * 90090991 * 99009901 * 99990001 * 109889011 * 9999000099990001 * 10099989899000101 * 100009999999899989999000000010001
3 * 5 * 5 * 29 * 2298850574712643678160919540229885057471264367816091954023 * 199999999999999999999999999999999999999999999999999999999999
9 * 111 * 11111 * 1111111 * 90090991 * 900900990991 * 900009090090909909099991 * 1109988789001111109989898989900111110998878900111
11 * 91 * 9091 * 909091 * 769223077 * 156985855573 * 1099988890111109888900011 * 910009191000909089989898989899909091000919100091
3 * 7 * 7 * 36 * 61 * 167280026764804282368685178989628638340582134493141518903 * 18518518518518518518518518518518518518518518518518518518479
