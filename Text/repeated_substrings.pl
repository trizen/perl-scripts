#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 27 April 2015
# website: http://github.com/trizen

# Find repeated substrings of a string. (fast solution)

# usage: perl repeated_substrings.pl < file.txt

use 5.010;
use strict;
use warnings;

sub rep_substrings {
    my ($str, $min, $max) = @_;

    my $limit = length($str);

    $min //= 4;
    $max //= int($limit) / 2;

    my @reps;
    my $cur_pos = $min;
    my $old_pos = 0;
    my $old_n   = 0;

    while ($cur_pos < $limit) {

        my $n   = 2;
        my $pos = 0;
        my $matched;

        while (   $pos != $old_pos + 1
               && $cur_pos + $n <= $limit
               && $n <= $max
               && (my $p = index(substr($str, 0, $cur_pos), substr($str, $cur_pos, $n), $pos)) >= 0) {
            ++$n;
            $pos = $p;
            !$matched && $n > $min && ($matched = 1);
        }

        if ($pos == $old_pos + 1) {
            $cur_pos += $old_n - 1;
        }
        else {
            push @reps, [$cur_pos, $pos, $n - 1, substr($str, $cur_pos, $n - 1)] if $matched;
            $cur_pos += 1;
        }

        $old_pos = $pos;
        $old_n   = $n - 1;
    }

    return \@reps;
}

my $text = @ARGV ? do { local $/; <> } : 'TOBEORNOTTOBEORTOBEORNOT#';
my $positions = rep_substrings($text);

my $total_len = 0;
foreach my $group (@{$positions}) {
    $total_len += length($group->[-1]);
}

eval {
    require Data::Dump;
    say Data::Dump::pp($positions);
};

say "\n** A total of $total_len characters!\n";
