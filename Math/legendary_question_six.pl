#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 August 2016
# Website: https://github.com/trizen

# The problem:
#   Let "a" and "b" be positive integers such that a*b + 1 divides a^2 + b^2.
#   Show that (a^2 + b^2) / (a*b + 1) is the square of an integer.

# See also: https://www.youtube.com/watch?v=Y30VF3cSIYQ

# This program naively generates solutions for "a" and "b".

use 5.010;
use strict;
use warnings;

use ntheory qw(is_power);

my $limit = 1e3;

foreach my $x (1 .. $limit) {
    foreach my $y ($x .. $limit) {

        my $k = ($x**2 + $y**2);
        my $j = ($x * $y + 1);

        if ($k % $j == 0) {
            if (is_power($k / $j, 2)) {
                printf("a = %-10s b = %-10s => %10s / %-10s = %s\n", $x, $y, $k, $j, $k / $j);
            }
            else {
                die "error: found a counter-example...";
            }
        }
    }
}

__END__
a = 1          b = 1          =>          2 / 2          = 1
a = 2          b = 8          =>         68 / 17         = 4
a = 3          b = 27         =>        738 / 82         = 9
a = 4          b = 64         =>       4112 / 257        = 16
a = 5          b = 125        =>      15650 / 626        = 25
a = 6          b = 216        =>      46692 / 1297       = 36
a = 7          b = 343        =>     117698 / 2402       = 49
a = 8          b = 30         =>        964 / 241        = 4
a = 8          b = 512        =>     262208 / 4097       = 64
a = 9          b = 729        =>     531522 / 6562       = 81
a = 10         b = 1000       =>    1000100 / 10001      = 100
a = 27         b = 240        =>      58329 / 6481       = 9
a = 30         b = 112        =>      13444 / 3361       = 4
a = 112        b = 418        =>     187268 / 46817      = 4
