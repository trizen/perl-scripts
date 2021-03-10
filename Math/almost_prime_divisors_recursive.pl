#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 March 2021
# https://github.com/trizen

# Generate all the k-almost prime divisors of n.

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub almost_prime_divisors ($n, $k) {

    my @factor_exp = factor_exp($n);
    my @factors    = map { $_->[0] } @factor_exp;
    my %valuations = map { @$_ } @factor_exp;

    if ($k == 0) {
        return (1);
    }

    if ($k == 1) {
        return @factors;
    }

    my @list;

    sub ($m, $p, $k) {

        if ($k == 1) {

            my $L = divint($n, $m);

            foreach my $q (@factors) {

                $q < $p and next;
                $q > $L and last;

                valuation($m, $q) < $valuations{$q} or next;

                push @list, mulint($m, $q);
            }

            return;
        }

        my $s = rootint(divint($n, $m), $k);

        foreach my $q (@factors) {

            $q < $p and next;
            $q > $s and last;

            valuation($m, $q) < $valuations{$q} or next;

            __SUB__->(mulint($m, $q), $q, $k - 1);
        }
    }->(1, $factors[0], $k);

    sort { $a <=> $b } @list;
}

my $n = factorial(10);

foreach my $k (0 .. factor($n)) {
    my @divisors = almost_prime_divisors($n, $k);
    printf("%2d-almost prime divisors of %s: [%s]\n", $k, $n, join(', ', @divisors));
}

__END__
 0-almost prime divisors of 3628800: [1]
 1-almost prime divisors of 3628800: [2, 3, 5, 7]
 2-almost prime divisors of 3628800: [4, 6, 9, 10, 14, 15, 21, 25, 35]
 3-almost prime divisors of 3628800: [8, 12, 18, 20, 27, 28, 30, 42, 45, 50, 63, 70, 75, 105, 175]
 4-almost prime divisors of 3628800: [16, 24, 36, 40, 54, 56, 60, 81, 84, 90, 100, 126, 135, 140, 150, 189, 210, 225, 315, 350, 525]
 5-almost prime divisors of 3628800: [32, 48, 72, 80, 108, 112, 120, 162, 168, 180, 200, 252, 270, 280, 300, 378, 405, 420, 450, 567, 630, 675, 700, 945, 1050, 1575]
 6-almost prime divisors of 3628800: [64, 96, 144, 160, 216, 224, 240, 324, 336, 360, 400, 504, 540, 560, 600, 756, 810, 840, 900, 1134, 1260, 1350, 1400, 1890, 2025, 2100, 2835, 3150, 4725]
 7-almost prime divisors of 3628800: [128, 192, 288, 320, 432, 448, 480, 648, 672, 720, 800, 1008, 1080, 1120, 1200, 1512, 1620, 1680, 1800, 2268, 2520, 2700, 2800, 3780, 4050, 4200, 5670, 6300, 9450, 14175]
 8-almost prime divisors of 3628800: [256, 384, 576, 640, 864, 896, 960, 1296, 1344, 1440, 1600, 2016, 2160, 2240, 2400, 3024, 3240, 3360, 3600, 4536, 5040, 5400, 5600, 7560, 8100, 8400, 11340, 12600, 18900, 28350]
 9-almost prime divisors of 3628800: [768, 1152, 1280, 1728, 1792, 1920, 2592, 2688, 2880, 3200, 4032, 4320, 4480, 4800, 6048, 6480, 6720, 7200, 9072, 10080, 10800, 11200, 15120, 16200, 16800, 22680, 25200, 37800, 56700]
10-almost prime divisors of 3628800: [2304, 3456, 3840, 5184, 5376, 5760, 6400, 8064, 8640, 8960, 9600, 12096, 12960, 13440, 14400, 18144, 20160, 21600, 22400, 30240, 32400, 33600, 45360, 50400, 75600, 113400]
11-almost prime divisors of 3628800: [6912, 10368, 11520, 16128, 17280, 19200, 24192, 25920, 26880, 28800, 36288, 40320, 43200, 44800, 60480, 64800, 67200, 90720, 100800, 151200, 226800]
12-almost prime divisors of 3628800: [20736, 34560, 48384, 51840, 57600, 72576, 80640, 86400, 120960, 129600, 134400, 181440, 201600, 302400, 453600]
13-almost prime divisors of 3628800: [103680, 145152, 172800, 241920, 259200, 362880, 403200, 604800, 907200]
14-almost prime divisors of 3628800: [518400, 725760, 1209600, 1814400]
15-almost prime divisors of 3628800: [3628800]
