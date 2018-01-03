#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 January 2018
# https://github.com/trizen

# Simple implementation of the Lerch zeta function Φ(z, s, t), for real(z) < 1/2.

# Formula due to Guillera and Sondow (2005).

# See also:
#   http://mathworld.wolfram.com/LerchTranscendent.html
#   https://en.wikipedia.org/wiki/Lerch_zeta_function

use 5.020;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload pi binomial factorial);

sub lerch ($z, $s, $t, $reps = 100) {
    my $sum = 0.0;

    my $r = (-$z) / (1 - $z);

    foreach my $n (0 .. $reps) {

        my $temp = 0.0;

        foreach my $k (0 .. $n) {
            $temp += (-1)**$k * binomial($n, $k) * ($t + $k)**(-$s);
        }

        $sum += $r**$n * $temp;
    }

    $sum / (1 - $z);
}

say "zeta(2)/2 =~ ", lerch(-1, 2, 1);        # 0.822467033424113...
say "4*catalan =~ ", lerch(-1, 2, 1 / 2);    # 3.663862376708876...

say '';

sub A281964 ($n) {
    (factorial($n) * (-2 * i * i**$n * (lerch(-1, 1, $n / 2 + 1) - i * lerch(-1, 1, ($n + 1) / 2)) + pi + 2 * i * log(2)) / 4)->real->round;
}

foreach my $n (1 .. 10) {
    printf("a(%2d) = %s\n", $n, A281964($n));
}
