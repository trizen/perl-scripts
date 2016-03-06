#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 October 2015
# Website: https://github.com/trizen

# Implementation of the Jaro-Winkler distance algorithm
# See: https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance

use 5.010;
use strict;
use warnings;

use List::Util qw(min max);

sub jaro {
    my ($s, $t) = @_;

    my $len1 = length($s);
    my $len2 = length($t);

    ($s, $len1, $t, $len2) = ($t, $len2, $s, $len1)
      if $len1 > $len2;

    $len1 || return 0;

    my $match_window = $len2 > 3 ? int($len2 / 2) - 1 : 0;

    my @s_matches;
    my @t_matches;

    my @s = split(//, $s);
    my @t = split(//, $t);

    foreach my $i (0 .. $#s) {

        my $window_start = max(0, $i - $match_window);
        my $window_end = min($i + $match_window + 1, $len2);

        foreach my $j ($window_start .. $window_end - 1) {
            if (not exists($t_matches[$j]) and $s[$i] eq $t[$j]) {
                $s_matches[$i] = $s[$i];
                $t_matches[$j] = $t[$j];
                last;
            }
        }
    }

    (@s_matches = grep { defined } @s_matches) || return 0;
    @t_matches = grep { defined } @t_matches;

    my $transpositions = 0;
    foreach my $i (0 .. $#s_matches) {
        $s_matches[$i] eq $t_matches[$i] or ++$transpositions;
    }

    my $num_matches = @s_matches;
    (($num_matches / $len1) + ($num_matches / $len2) + ($num_matches - int($transpositions / 2)) / $num_matches) / 3;
}

sub jaro_winkler {
    my ($s, $t) = @_;

    my $distance = jaro($s, $t);

    my $prefix = 0;
    foreach my $i (0 .. min(3, length($s), length($t))) {
        substr($s, $i, 1) eq substr($t, $i, 1) ? ++$prefix : last;
    }

    $distance + $prefix * 0.1 * (1 - $distance);
}

printf("%f\n", jaro_winkler("MARTHA",      "MARHTA"));
printf("%f\n", jaro_winkler("DWAYNE",      "DUANE"));
printf("%f\n", jaro_winkler("DIXON",       "DICKSONX"));
printf("%f\n", jaro_winkler("ROSETTACODE", "ROSETTASTONE"));
