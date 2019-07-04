#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 July 2019
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

use Math::GMPz;
use ntheory qw(divisors rootint logint is_power gcd vecprod powint);

sub diff_power_factorization ($n, $verbose = 0) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $orig = $n;
    my @f_params;

    my $f = sub ($r1, $e1, $r2, $e2) {
        my @factors;

        my @divs1 = divisors($e1);
        my @divs2 = divisors($e2);

        foreach my $d1 (@divs1) {
            foreach my $d2 (@divs2) {
                foreach my $j (1, -1) {

                    my $t = $r1**$d1 - $j * $r2**$d2;
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

    foreach my $r1 (map { Math::GMPz->new($_) } 2 .. logint($n, 2)) {

        my $e1 = logint($n, $r1);
        my $u  = $r1**($e1 + 1);
        my $dx = $u - $n;

        if ($dx == 1 or Math::GMPz::Rmpz_perfect_power_p($dx)) {
            my $e2 = ($dx == 1) ? 1 : is_power($dx);
            my $r2 = Math::GMPz->new(rootint($dx, $e2));

            if ($verbose) {
                say "[*] Difference of powers detected: ", sprintf("%s^%s - %s^%s", $r1, $e1 + 1, $r2, $e2);
            }

            push @f_params, [$r1, $e1 + 1, $r2, $e2];
        }
    }

    foreach my $r1 (map { Math::GMPz->new($_) } 2 .. logint($n, 2)) {

        my $e1 = logint($n, $r1);
        my $u  = $r1**$e1;
        my $dx = $n - $u;

        if ($dx == 1 or Math::GMPz::Rmpz_perfect_power_p($dx)) {
            my $e2 = ($dx == 1) ? 1 : is_power($dx);
            my $r2 = Math::GMPz->new(rootint($dx, $e2));

            if ($verbose) {
                say "[*] Sum of powers detected: ", sprintf("%s^%s + %s^%s", $r1, $e1, $r2, $e2);
            }

            push @f_params, [$r1, $e1, $r2, $e2];
        }
    }

    my @factors;

    foreach my $fp (@f_params) {
        push @factors, $f->(@$fp);
    }

    push @factors, $orig / vecprod(@factors);
    return sort { $a <=> $b } @factors;
}

if (@ARGV) {
    say join ', ', diff_power_factorization($ARGV[0], 1);
    exit;
}

say '2^256  - 1      = ', join ' * ', diff_power_factorization(powint(2,  256) - 1);
say '10^120 + 1      = ', join ' * ', diff_power_factorization(powint(10, 120) + 1);
say '10^120 - 1      = ', join ' * ', diff_power_factorization(powint(10, 120) - 1);
say '10^120 - 25     = ', join ' * ', diff_power_factorization(powint(10, 120) - 25);
say '10^105 - 1      = ', join ' * ', diff_power_factorization(powint(10, 105) - 1);
say '10^105 + 1      = ', join ' * ', diff_power_factorization(powint(10, 105) + 1);
say '10^120 - 2134^2 = ', join ' * ', diff_power_factorization(powint(10, 120) - 2134 * 2134);

__END__
2^256  - 1      = 3 * 5 * 17 * 257 * 65537 * 4294967297 * 18446744073709551617 * 340282366920938463463374607431768211457
10^120 + 1      = 100000001 * 9999999900000001 * 99999999000000009999999900000001 * 10000000099999999999999989999999899999999000000000000000100000001
10^120 - 1      = 3 * 9 * 11 * 37 * 91 * 101 * 9091 * 9901 * 10001 * 11111 * 90090991 * 99009901 * 99990001 * 109889011 * 9999000099990001 * 10099989899000101 * 100009999999899989999000000010001
10^120 - 25     = 3 * 5 * 5 * 29 * 2298850574712643678160919540229885057471264367816091954023 * 199999999999999999999999999999999999999999999999999999999999
10^105 - 1      = 9 * 111 * 11111 * 1111111 * 90090991 * 900900990991 * 900009090090909909099991 * 1109988789001111109989898989900111110998878900111
10^105 + 1      = 11 * 91 * 9091 * 909091 * 769223077 * 156985855573 * 1099988890111109888900011 * 910009191000909089989898989899909091000919100091
10^120 - 2134^2 = 3 * 7 * 7 * 36 * 61 * 167280026764804282368685178989628638340582134493141518903 * 18518518518518518518518518518518518518518518518518518518479
