#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2016
# Website: https://github.com/trizen

# The minimal path sum in the 5 by 5 matrix below, by starting in any cell
# in the left column and finishing in any cell in the right column, and only
# moving up, down, and right; the sum is equal to 994.

# This algorithm finds the best possible path. (visual version)
# The problem was taken from: https://projecteuler.net/problem=82

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

use List::Util qw(min);
use Time::HiRes qw(sleep);
use Term::ANSIColor qw(colored);

my @matrix = (
    map {
        [map { int(rand(1000)) } 1 .. 6]
      } 1 .. 6
);

sub draw {
    my ($path) = @_;

    print "\e[H\e[J\e[H";
    my @screen = map {
        [map { sprintf "%3s", $_ } @{$_}]
    } @matrix;

    foreach my $p (@$path) {
        my ($i, $j) = @$p;
        $screen[$i][$j] = colored($screen[$i][$j], 'red');
    }

    foreach my $row (@screen) {
        say join(' ', @{$row});
    }
}

my $end = $#matrix;

sub path {
    my ($i, $j, $prev, $path) = @_;

    push @$path, [$i, $j];

    $j >= $end && do {
        return [$matrix[$i][$j], [@$path]];
    };

    my @paths;
    if ($i > 0 and $prev ne 'down') {
        push @paths, path($i - 1, $j, 'up', [@$path]);
    }

    push @paths, path($i, $j + 1, 'ok', [@$path]);

    if ($i < $end and $prev ne 'up') {
        push @paths, path($i + 1, $j, 'down', [@$path]);
    }

    my $min = ['inf', []];

    foreach my $sum (@paths) {
        $min = $sum if $sum->[0] < $min->[0];
    }

    pop @$path;
    [$min->[0] + $matrix[$i][$j], $min->[1]];
}

my @sums;
foreach my $i (0 .. $end) {
    push @sums, path($i, 0, 'ok', []);
}

my $min = (map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, $_->[0]] } @sums)[0];

draw($min->[1]);
say "Minimum path-sum is: $min->[0]";
