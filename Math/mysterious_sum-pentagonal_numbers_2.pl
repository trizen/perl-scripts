#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 14 August 2016
# License: GPLv3
# Website: https://github.com/trizen

# Mysterious sum-pentagonal numbers of second order.
# A strange fact: at this very moment, nothing is known about this numbers...

use 5.010;
use strict;
use warnings;

use Memoize qw(memoize);

memoize('sum_pentagonal');

# Tip: square numbers also produce a nice sequence.

sub p {
    $_[0] * (3 * $_[0] - 1) / 2;
}

sub f1 {
    my ($n, $i) = @_;

    my $p = p($i);

    return $n if $n - $p == 0;
    return 0  if $n - $p < 0;

    (-1)**($i + 1) * f1($n - $p, $i - 1) + sum_pentagonal($n - 1);
}

sub f2 {
    my ($n, $i) = @_;

    my $p = p($i);

    return $n if $n - $p == 0;
    return 0  if $n - $p < 0;

    (-1)**($i + 1) * f2($n - $p, $i - 1) + sum_pentagonal($n - 1);
}

sub sum_pentagonal {
    my ($n) = @_;
    f1($n, 1) + f2($n, -1);
}

foreach my $n (1 .. 50) {
    say "s($n) = ", sum_pentagonal($n);
}

__END__
s(1) = 1
s(2) = 3
s(3) = 5
s(4) = 10
s(5) = 20
s(6) = 40
s(7) = 80
s(8) = 160
s(9) = 327
s(10) = 727
s(11) = 1534
s(12) = 3235
s(13) = 6870
s(14) = 14547
s(15) = 30795
s(16) = 65225
s(17) = 138127
s(18) = 292502
s(19) = 619434
s(20) = 1311770
s(21) = 2777915
s(22) = 5882762
s(23) = 12457860
s(24) = 26381850
s(25) = 55837767
s(26) = 118216202
s(27) = 250283492
s(28) = 529868526
s(29) = 1121788555
s(30) = 2374952064
