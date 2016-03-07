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

    my $s_len = length($s);
    my $t_len = length($t);

    return 1 if ($s_len == 0 and $t_len == 0);

    my $match_distance = int(max($s_len, $t_len) / 2) - 1;

    my @s_matches;
    my @t_matches;

    my @s = split(//, $s);
    my @t = split(//, $t);

    my $matches = 0;
    foreach my $i (0 .. $s_len - 1) {

        my $start = max(0, $i - $match_distance);
        my $end = min($i + $match_distance + 1, $t_len);

        foreach my $j ($start .. $end - 1) {
            $t_matches[$j] and next;
            $s[$i] eq $t[$j] or next;
            $s_matches[$i] = 1;
            $t_matches[$j] = 1;
            $matches++;
            last;
        }
    }

    return 0 if $matches == 0;

    my $k     = 0;
    my $trans = 0;

    foreach my $i (0 .. $s_len - 1) {
        $s_matches[$i] or next;
        until ($t_matches[$k]) { ++$k }
        $s[$i] eq $t[$k] or ++$trans;
        ++$k;
    }

#<<<
    (($matches / $s_len) + ($matches / $t_len)
        + (($matches - $trans / 2) / $matches)) / 3;
#>>>
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
