#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2016
# Website: https://github.com/trizen

# The minimal path sum in the 5 by 5 matrix below, by starting in any cell
# in the left column and finishing in any cell in the right column, and only
# moving up, down, and right; the sum is equal to 994.

# This is a greedy algorithm (visual version).
# The problem was taken from: https://projecteuler.net/problem=82

use 5.010;
use strict;
use warnings;

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

    sleep(0.2);
}

my $end = $#matrix;
my $min = ['inf', []];

foreach my $i (0 .. $#matrix) {
    my $sum = $matrix[$i][0];

    my $j    = 0;
    my $last = 'ok';
    my @path = [$i, 0];

    while (1) {
        my @ways;

        if ($i > 0 and $last ne 'down') {
            push @ways, [-1, 0, $matrix[$i - 1][$j], 'up'];
        }

        if ($j < $end) {
            push @ways, [0, 1, $matrix[$i][$j + 1], 'ok'];
        }

        if ($i < $end and $last ne 'up') {
            push @ways, [1, 0, $matrix[$i + 1][$j], 'down'];
        }

        my $m = [0, 0, 'inf', 'ok'];

        foreach my $way (@ways) {
            $m = $way if $way->[2] < $m->[2];
        }

        $i   += $m->[0];
        $j   += $m->[1];
        $sum += $m->[2];
        $last = $m->[3];

        push @path, [$i, $j];
        draw(\@path);
        last if $j >= $end;
    }

    $min = [$sum, \@path] if $sum < $min->[0];
}

draw($min->[1]);
say "Minimum path-sum: $min->[0]";
