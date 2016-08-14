#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 14 August 2016
# License: GPLv3
# Website: https://github.com/trizen

# Mysterious sum-pentagonal numbers.

# A strange fact: at this very moment, as far as
# I searched, nothing is known about this numbers...

use 5.010;
use strict;
use warnings;

use Memoize qw(memoize);

memoize('sum_pentagonal');

sub p {
    $_[0] * (3 * $_[0] - 1) / 2;
}

sub sum_pentagonal {
    my ($n) = @_;

    my $i   = 1;
    my $sum = 0;

    while (1) {
        my $p1 = p($i);

        if ($n - $p1 == 0) {
            return $sum + $n;
        }
        elsif ($n - $p1 < 0) {
            last;
        }

        $sum += (-1)**($i - 1) * sum_pentagonal($n - $p1);

        my $p2 = p(-$i);

        if ($n - $p2 == 0) {
            return $sum + $n;
        }
        elsif ($n - $p2 < 0) {
            last;
        }

        $sum += (-1)**($i - 1) * sum_pentagonal($n - $p2);

        ++$i;
    }

    $sum;
}

foreach my $n (1 .. 100) {
    say "s($n) = ", sum_pentagonal($n);
}

__END__
s(1) = 1
s(2) = 3
s(3) = 4
s(4) = 7
s(5) = 16
s(6) = 22
s(7) = 42
s(8) = 59
s(9) = 91
s(10) = 130
s(11) = 192
s(12) = 276
s(13) = 388
s(14) = 534
s(15) = 752
s(16) = 1011
s(17) = 1376
s(18) = 1833
s(19) = 2448
s(20) = 3216
s(21) = 4232
s(22) = 5514
s(23) = 7152
s(24) = 9206
s(25) = 11823
s(26) = 15094
s(27) = 19198
s(28) = 24282
s(29) = 30624
s(30) = 38450
