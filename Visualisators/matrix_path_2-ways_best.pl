#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 08 August 2016
# Website: https://github.com/trizen

# Visualization for the best minimum path-sum in a matrix.
# Inspired by: https://projecteuler.net/problem=81

# The path moves only right and down.

use 5.010;
use strict;
use warnings;

use List::Util qw(min);
use Time::HiRes qw(sleep);
use Term::ANSIColor qw(colored);

my @matrix = (
              [131, 673, 234, 103, 18],
              [201, 96,  342, 965, 150],
              [630, 803, 746, 422, 111],
              [537, 699, 497, 121, 956],
              [805, 732, 524, 37,  331],
             );

my $end = $#matrix;

my @path;

sub draw {
    print "\e[H\e[J\e[H";
    my @screen = map {
        [map { sprintf "%3s", $_ } @{$_}]
    } @matrix;

    foreach my $path (@path) {
        my ($i, $j) = @$path;
        $screen[$i][$j] = colored($screen[$i][$j], 'red');
    }

    foreach my $row (@screen) {
        say join(' ', @{$row});
    }

    sleep(0.05);
}

sub path {
    my ($i, $j) = @_;

    push @path, [$i, $j];
    draw();
    pop @path;

    if ($i < $end and $j < $end) {
        push @path, [$i, $j];
        my $sum = $matrix[$i][$j] + min(path($i + 1, $j), path($i, $j + 1));
        pop @path;
        return $sum;
    }

    if ($i < $end) {
        push @path, [$i, $j];
        my $sum = $matrix[$i][$j] + path($i + 1, $j);
        pop @path;
        return $sum;
    }

    if ($j < $end) {
        push @path, [$i, $j];
        my $sum = $matrix[$i][$j] + path($i, $j + 1);
        pop @path;
        return $sum;
    }

    $matrix[$i][$j];
}

my $min_pathsum = path(0, 0);
say "\nMinimum path sum is: $min_pathsum\n";
