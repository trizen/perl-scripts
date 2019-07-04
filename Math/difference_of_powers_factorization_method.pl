#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 July 2019
# https://github.com/trizen

# A simple factorization method for numbers that can be expressed as a difference of powers.

# Very effective for numbers of the form:
#
#   n^k - 1
#
# where k has many divisors.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use ntheory qw(divisors logint is_power);
use Math::AnyNum qw(iroot ipow prod gcd);

sub diff_power_factorization ($n) {

    my $orig = $n;
    my @f_params;

    my $f = sub ($r, $e, $r2, $e2) {
        my @factors;

        my @d1 = divisors($e);
        my @d2 = divisors($e2);

        foreach my $d (@d1) {
            foreach my $d2 (@d2) {
                foreach my $j (1, -1) {

                    my $t = ipow($r, $d) - $j * ipow($r2, $d2);
                    my $g = gcd($t, $n);

                    if ($g > 1 and $g < $n) {
                        while ($n % $g == 0) {
                            $n /= $g;
                            push @factors, $g;
                        }
                    }
                }
            }
        }

        foreach my $d (@d1) {
            foreach my $j (1, -1) {
                if ($d * log($e) / log(10) < 1e6) {

                    my $t = ipow($d, $e) - $j * ipow($d, $e2);
                    my $g = gcd($t, $n);

                    if ($g > 1 and $g < $n) {
                        while ($n % $g == 0) {
                            $n /= $g;
                            push @factors, $g;
                        }
                    }
                }
            }
        }

        foreach my $d2 (@d2) {
            foreach my $j (1, -1) {
                if ($d2 * log($e) / log(10) < 1e6) {

                    my $t = ipow($d2, $e) - $j * ipow($d2, $e2);
                    my $g = gcd($t, $n);

                    if ($g > 1 and $g < $n) {
                        while ($n % $g == 0) {
                            $n /= $g;
                            push @factors, $g;
                        }
                    }
                }
            }
        }

        sort { $a <=> $b } @factors;
    };

    foreach my $r (2 .. logint($n, 2)) {

        my $l    = logint($n, $r);
        my $u    = ipow($r, $l + 1);
        my $diff = $u - $n;

        if ($diff == 1 or is_power($diff)) {
            my $e  = ($diff == 1) ? 1 : is_power($diff);
            my $r2 = iroot($diff, $e);
            ##say "[*] Difference of powers detected: ", sprintf("%s^%s - %s^%s", $r, $l + 1, $r2, $e);
            push @f_params, [Math::AnyNum->new($r), $l + 1, $r2, $e];
        }
    }

    foreach my $r (2 .. logint($n, 2)) {

        my $l    = logint($n, $r);
        my $u    = ipow($r, $l);
        my $diff = $n - $u;

        if ($diff == 1 or is_power($diff)) {
            my $e  = ($diff == 1) ? 1 : is_power($diff);
            my $r2 = iroot($diff, $e);
            ##say "[*] Sum of powers detected: ", sprintf("%s^%s + %s^%s", $r, $l, $r2, $e);
            push @f_params, [Math::AnyNum->new($r), $l, $r2, $e];
        }
    }

    my @factors;

    foreach my $fp (@f_params) {
        push @factors, $f->(@$fp);
    }

    push @factors, $orig / prod(@factors);
    return sort { $a <=> $b } @factors;
}

if (@ARGV) {
    say join ', ', diff_power_factorization(Math::AnyNum->new($ARGV[0]), defined($ARGV[1]) ? $ARGV[1] : ());
    exit;
}

say '2^256  - 1      = ', join ' * ', diff_power_factorization(ipow(2,  256) - 1);
say '10^120 + 1      = ', join ' * ', diff_power_factorization(ipow(10, 120) + 1);
say '10^120 - 1      = ', join ' * ', diff_power_factorization(ipow(10, 120) - 1);
say '10^120 - 25     = ', join ' * ', diff_power_factorization(ipow(10, 120) - 25);
say '10^105 - 1      = ', join ' * ', diff_power_factorization(ipow(10, 105) - 1);
say '10^105 + 1      = ', join ' * ', diff_power_factorization(ipow(10, 105) + 1);
say '10^120 - 2134^2 = ', join ' * ', diff_power_factorization(ipow(10, 120) - 2134 * 2134);

__END__
2^256  - 1      = 3 * 5 * 17 * 257 * 65537 * 4294967297 * 18446744073709551617 * 340282366920938463463374607431768211457
10^120 + 1      = 100000001 * 9999999900000001 * 99999999000000009999999900000001 * 10000000099999999999999989999999899999999000000000000000100000001
10^120 - 1      = 3 * 9 * 11 * 37 * 91 * 101 * 9091 * 9901 * 10001 * 11111 * 90090991 * 99009901 * 99990001 * 109889011 * 9999000099990001 * 10099989899000101 * 100009999999899989999000000010001
10^120 - 25     = 3 * 5 * 5 * 29 * 2298850574712643678160919540229885057471264367816091954023 * 199999999999999999999999999999999999999999999999999999999999
10^105 - 1      = 9 * 111 * 11111 * 1111111 * 90090991 * 900900990991 * 900009090090909909099991 * 1109988789001111109989898989900111110998878900111
10^105 + 1      = 11 * 91 * 9091 * 909091 * 769223077 * 156985855573 * 1099988890111109888900011 * 910009191000909089989898989899909091000919100091
10^120 - 2134^2 = 3 * 7 * 7 * 36 * 61 * 167280026764804282368685178989628638340582134493141518903 * 18518518518518518518518518518518518518518518518518518518479
