#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 July 2019
# Edit: 22 March 2022
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

use constant {
              MIN_FACTOR => 1,    # ignore small factors
              LOG_BRANCH => 0,    # true to use the log branch in addition to the root branch
             };

sub diff_power_factorization ($n, $verbose = 0) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $orig = $n;
    my @diff_powers_params;

    my $diff_powers = sub ($r1, $e1, $r2, $e2) {
        my @factors;

        my @divs1 = divisors($e1);
        my @divs2 = divisors($e2);

        foreach my $d1 (@divs1) {
            my $x = $r1**$d1;
            foreach my $d2 (@divs2) {
                my $y = $r2**$d2;
                foreach my $j (1, -1) {

                    my $t = $x - $j * $y;
                    my $g = gcd($t, $n);

                    if ($g > MIN_FACTOR and $g < $n) {
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

    my $diff_power_check = sub ($r1, $e1) {

        my $u  = $r1**$e1;
        my $dx = abs($u - $n);

        if ($dx >= 1 and Math::GMPz::Rmpz_perfect_power_p($dx)) {

            my $e2 = ($dx == 1) ? 1 : is_power($dx);
            my $r2 = Math::GMPz->new(rootint($dx, $e2));

            if ($verbose) {
                if ($u > $n) {
                    say "[*] Difference of powers detected: ", sprintf("%s^%s - %s^%s", $r1, $e1, $r2, $e2);
                }
                else {
                    say "[*] Sum of powers detected: ", sprintf("%s^%s + %s^%s", $r1, $e1, $r2, $e2);
                }
            }

            push @diff_powers_params, [$r1, $e1, $r2, $e2];
        }
    };

    # Sum and difference of powers of the form a^k ± b^k, where a and b are large.
    foreach my $e1 (reverse 2 .. logint($n, 2)) {

        my $t = Math::GMPz->new(rootint($n, $e1));

        $diff_power_check->($t,     $e1);    # sum of powers
        $diff_power_check->($t + 1, $e1);    # difference of powers
    }

    # Sum and difference of powers of the form a^k ± b^k, where a and b are small.
    if (LOG_BRANCH) {
        foreach my $r1 (2 .. logint($n, 2)) {

            my $t = logint($n, $r1);

            $diff_power_check->(Math::GMPz->new($r1), $t);        # sum of powers
            $diff_power_check->(Math::GMPz->new($r1), $t + 1);    # difference of powers
        }

        my %seen_param;
        @diff_powers_params = grep { !$seen_param{join(' ', @$_)}++ } @diff_powers_params;
    }

    my @factors;

    foreach my $fp (@diff_powers_params) {
        push @factors, $diff_powers->(@$fp);
    }

    push @factors, $orig / vecprod(@factors);
    return sort { $a <=> $b } @factors;
}

if (@ARGV) {
    say join ', ', diff_power_factorization($ARGV[0], 1);
    exit;
}

# Large roots
say join ' * ', diff_power_factorization(powint(1009,     24) + powint(29,  12));
say join ' * ', diff_power_factorization(powint(1009,     24) - powint(29,  12));
say join ' * ', diff_power_factorization(powint(59388821, 12) - powint(151, 36));

say '-' x 80;

# Small roots
say join ' * ', diff_power_factorization(powint(2,  256) - 1);
say join ' * ', diff_power_factorization(powint(10, 120) + 1);
say join ' * ', diff_power_factorization(powint(10, 120) - 1);
say join ' * ', diff_power_factorization(powint(10, 120) - 25);
say join ' * ', diff_power_factorization(powint(10, 105) - 1);
say join ' * ', diff_power_factorization(powint(10, 105) + 1);
say join ' * ', diff_power_factorization(powint(10, 120) - 2134 * 2134);

__END__
2 * 537154643295831327753001 * 1154140443257087164049583013000044736320575461201
6 * 6 * 13 * 19 * 31 * 37 * 140 * 33937 * 36359 * 45120343 * 14006607073 * 1036518447751 * 1074309285719975471632201
3 * 3 * 10 * 12 * 13 * 14 * 19 * 61 * 1745327 * 5594587 * 28145554676761 * 85497773607889 * 1769442985679221 * 203250599010814323919992393181
--------------------------------------------------------------------------------
3 * 5 * 17 * 257 * 65537 * 4294967297 * 18446744073709551617 * 340282366920938463463374607431768211457
100000001 * 9999999900000001 * 99999999000000009999999900000001 * 10000000099999999999999989999999899999999000000000000000100000001
3 * 9 * 11 * 37 * 91 * 101 * 9091 * 9901 * 10001 * 11111 * 90090991 * 99009901 * 99990001 * 109889011 * 9999000099990001 * 10099989899000101 * 100009999999899989999000000010001
3 * 5 * 5 * 29 * 2298850574712643678160919540229885057471264367816091954023 * 199999999999999999999999999999999999999999999999999999999999
9 * 111 * 11111 * 1111111 * 90090991 * 900900990991 * 900009090090909909099991 * 1109988789001111109989898989900111110998878900111
11 * 91 * 9091 * 909091 * 769223077 * 156985855573 * 1099988890111109888900011 * 910009191000909089989898989899909091000919100091
3 * 7 * 7 * 36 * 61 * 167280026764804282368685178989628638340582134493141518903 * 18518518518518518518518518518518518518518518518518518518479
