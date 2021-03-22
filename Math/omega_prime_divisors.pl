#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 21 March 2021
# https://github.com/trizen

# Generate all the k-omega prime divisors of n.

# Definition:
#   k-omega primes are numbers n such that omega(n) == k.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Prime_omega_function

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub omega_prime_divisors ($n, $k) {

    if ($k == 0) {
        return (1);
    }

    my @factor_exp  = factor_exp($n);
    my @factors     = map { $_->[0] } @factor_exp;
    my %valuations  = map { @$_ } @factor_exp;
    my $factors_end = $#factors;

    if ($k > scalar(@factor_exp)) {
        return;
    }

    my @list;

    sub ($m, $k, $i = 0) {

        my $L = rootint(divint($n, $m), $k);

        foreach my $j ($i .. $factors_end) {

            my $q = $factors[$j];
            $q > $L and last;

            my $t = mulint($m, $q);

            foreach (1 .. $valuations{$q}) {

                if ($k == 1) {
                    push @list, $t;
                }
                elsif ($j < $factors_end) {
                    __SUB__->($t, $k - 1, $j + 1);
                }

                $t = mulint($t, $q);
            }
        }
    }->(1, $k);

    sort { $a <=> $b } @list;
}

my $n = factorial(10);

foreach my $k (0 .. prime_omega($n)) {
    my @divisors = omega_prime_divisors($n, $k);
    printf("%2d-omega prime divisors of %s: [%s]\n", $k, $n, join(', ', @divisors));
}

__END__
 0-omega prime divisors of 3628800: [1]
 1-omega prime divisors of 3628800: [2, 3, 4, 5, 7, 8, 9, 16, 25, 27, 32, 64, 81, 128, 256]
 2-omega prime divisors of 3628800: [6, 10, 12, 14, 15, 18, 20, 21, 24, 28, 35, 36, 40, 45, 48, 50, 54, 56, 63, 72, 75, 80, 96, 100, 108, 112, 135, 144, 160, 162, 175, 189, 192, 200, 216, 224, 225, 288, 320, 324, 384, 400, 405, 432, 448, 567, 576, 640, 648, 675, 768, 800, 864, 896, 1152, 1280, 1296, 1600, 1728, 1792, 2025, 2304, 2592, 3200, 3456, 5184, 6400, 6912, 10368, 20736]
 3-omega prime divisors of 3628800: [30, 42, 60, 70, 84, 90, 105, 120, 126, 140, 150, 168, 180, 240, 252, 270, 280, 300, 315, 336, 350, 360, 378, 450, 480, 504, 525, 540, 560, 600, 672, 700, 720, 756, 810, 900, 945, 960, 1008, 1080, 1120, 1134, 1200, 1344, 1350, 1400, 1440, 1512, 1575, 1620, 1800, 1920, 2016, 2160, 2240, 2268, 2400, 2688, 2700, 2800, 2835, 2880, 3024, 3240, 3600, 3840, 4032, 4050, 4320, 4480, 4536, 4725, 4800, 5376, 5400, 5600, 5760, 6048, 6480, 7200, 8064, 8100, 8640, 8960, 9072, 9600, 10800, 11200, 11520, 12096, 12960, 14175, 14400, 16128, 16200, 17280, 18144, 19200, 21600, 22400, 24192, 25920, 28800, 32400, 34560, 36288, 43200, 44800, 48384, 51840, 57600, 64800, 72576, 86400, 103680, 129600, 145152, 172800, 259200, 518400]
 4-omega prime divisors of 3628800: [210, 420, 630, 840, 1050, 1260, 1680, 1890, 2100, 2520, 3150, 3360, 3780, 4200, 5040, 5670, 6300, 6720, 7560, 8400, 9450, 10080, 11340, 12600, 13440, 15120, 16800, 18900, 20160, 22680, 25200, 26880, 28350, 30240, 33600, 37800, 40320, 45360, 50400, 56700, 60480, 67200, 75600, 80640, 90720, 100800, 113400, 120960, 134400, 151200, 181440, 201600, 226800, 241920, 302400, 362880, 403200, 453600, 604800, 725760, 907200, 1209600, 1814400, 3628800]
