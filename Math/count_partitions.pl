#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 August 2016
# Website: https://github.com/trizen

# A very fast algorithm for counting the number of partitions of a given number.
# See the sequence at: http://oeis.org/A000041

use 5.014;
use POSIX qw(floor ceil);
use Memoize qw(memoize);

memoize('partitions_count');

#
## 3b^2 - b - 2n <= 0
#
sub b1 {
    my ($n) = @_;

    my $x = 3;
    my $y = -1;
    my $z = -2 * $n;

    floor((-$y + sqrt($y**2 - 4 * $x * $z)) / (2 * $x));
}

#
## 3b^2 + 7b - 2n+4 >= 0
#
sub b2 {
    my ($n) = @_;

    my $x = 3;
    my $y = 7;
    my $z = -2 * $n + 4;

    ceil((-$y + sqrt($y**2 - 4 * $x * $z)) / (2 * $x));
}

sub p {
    (3 * $_[0]**2 - $_[0]) / 2;
}

# Based on the recursive function described bellow:
# http://numberworld.blogspot.ro/2013/09/sum-of-divisors-function-eulers.html

sub partitions_count {
    my ($n) = @_;

    return $n if ($n <= 1);

    my $sum_1 = 0;
    foreach my $i (1 .. b1($n)) {
        $sum_1 += (-1)**($i - 1) * partitions_count($n - p($i));
    }

    my $sum_2 = 0;
    foreach my $i (1 .. b2($n)) {
        $sum_2 += (-1)**($i - 1) * partitions_count($n - p(-$i));
    }

    $sum_1 + $sum_2;
}

foreach my $n (1 .. 100) {
    say "p($n) = ", partitions_count($n);
}
