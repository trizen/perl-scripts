#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 21 February 2013
# https://github.com/trizen

# Zequals and estimations
# http://www.youtube.com/watch?v=aOJOfh2_4PE

# Example: 722 * 49 ~~ 700 * 50

use 5.010;
use strict;
use warnings;

sub round {    # doesn't work as you expect!
    my ($num) = @_;

    my $i = 10;
    while ($i < $num) {
        if ($num % $i >= $i / 2) {
            $num += $i - $num % $i;
        }
        else {
            $num -= $num % $i;
        }
        $i *= 10;
    }

    return $num;
}

sub round_right {    # this works as expected.
    my ($num) = @_;

    my $i    = 10**int(log($num) / log(10));
    my $base = $i * int($num / $i);

    if ($num - $base >= $i / 2) {
        return $num + ($i - ($num - $base));
    }
    else {
        return $num - ($num - $base);
    }
}

sub zequal {
    my ($x, $y) = @_;
    return (round($x) * round($y));
}

sub zequal_right {
    my ($x, $y) = @_;
    return (round_right($x) * round_right($y));
}

{
    my ($x, $y) = (shift || 345, shift || 342);

    say "Zequal simple ($x, $y) ~~ ", zequal($x, $y);
    say "Zequal right  ($x, $y) ~~ ", zequal_right($x, $y);
    say "Reality       ($x, $y) == ", $x * $y;
}
