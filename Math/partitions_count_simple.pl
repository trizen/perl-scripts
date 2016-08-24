#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 August 2016
# Website: https://github.com/trizen

# A very fast algorithm for counting the number of partitions of a given number.
# See the sequence at: http://oeis.org/A000041

use 5.010;
use strict;
use warnings;

use POSIX qw(floor ceil);

# Based on the recursive function described bellow:
# http://numberworld.blogspot.ro/2013/09/sum-of-divisors-function-eulers.html

sub partitions_count {
    my ($n, $cache) = @_;

    $n <= 1 && return $n;

    if (exists $cache->{$n}) {
        return $cache->{$n};
    }

    my $sum_1 = 0;
    foreach my $i (1 .. floor((sqrt(24 * $n + 1) + 1) / 6)) {
        $sum_1 += (-1)**($i - 1) * partitions_count($n - int($i * (3 * $i - 1) / 2), $cache);
    }

    my $sum_2 = 0;
    foreach my $i (1 .. ceil((sqrt(24 * $n + 1) - 7) / 6)) {
        $sum_2 += (-1)**($i - 1) * partitions_count($n - int(-$i * (-3 * $i - 1) / 2), $cache);
    }

    $cache->{$n} = $sum_1 + $sum_2;
}

my %cache;
foreach my $n (1 .. 100) {
    say "p($n) = ", partitions_count($n + 1, \%cache);
}

__END__
p(1) = 1
p(2) = 2
p(3) = 3
p(4) = 5
p(5) = 7
p(6) = 11
p(7) = 15
p(8) = 22
p(9) = 30
p(10) = 42
p(11) = 56
p(12) = 77
p(13) = 101
p(14) = 135
p(15) = 176
p(16) = 231
p(17) = 297
p(18) = 385
p(19) = 490
p(20) = 627
