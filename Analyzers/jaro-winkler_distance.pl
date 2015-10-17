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

sub jaro_distance {
    my ($string1, $string2) = @_;

    my $len1 = length($string1);
    my $len2 = length($string2);

    ($string1, $len1, $string2, $len2) = ($string2, $len2, $string1, $len1)
      if $len1 > $len2;

    $len1 || return 0;

    my $match_window = $len2 > 3 ? int($len2 / 2) - 1 : 0;

    my @string1_matches;
    my @string2_matches;

    my @chars1 = split(//, $string1);
    my @chars2 = split(//, $string2);

    foreach my $i (0 .. $#chars1) {

        my $window_start = max(0, $i - $match_window);
        my $window_end = min($i + $match_window + 1, $len2);

        foreach my $j ($window_start .. $window_end - 1) {
            if (not exists($string2_matches[$j]) and $chars1[$i] eq $chars2[$j]) {
                $string1_matches[$i] = $chars1[$i];
                $string2_matches[$j] = $chars2[$j];
                last;
            }
        }
    }

    (@string1_matches = grep { defined } @string1_matches) || return 0;
    @string2_matches = grep { defined } @string2_matches;

    my $transpositions = 0;
    foreach my $i (0 .. $#string1_matches) {
        $string1_matches[$i] eq $string2_matches[$i] or ++$transpositions;
    }

    my $num_matches = @string1_matches;
    my $jaro =
      (($num_matches / $len1) + ($num_matches / $len2) + ($num_matches - int($transpositions / 2)) / $num_matches) / 3;

    # return $jaro;     # to return the Jaro distance instead of Jaro-Winkle

    my $prefix = 0;
    foreach my $i (0 .. $#chars1) {
        $chars1[$i] eq $chars2[$i] ? ++$prefix : last;
    }

    $jaro + min($prefix, 4) * 0.1 * (1 - $jaro);
}

say jaro_distance("DIXON",  "DICKSONX");    # 0.813333
say jaro_distance("MARTHA", "MARHTA");      # 0.961111
say jaro_distance("CRATE",  "TRACE");       # 0.733333
say jaro_distance("DWAYNE", "DUANE");       # 0.84
