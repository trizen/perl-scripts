#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 August 2016
# Website: https://github.com/trizen

# Problem from: https://projecteuler.net/problem=83

# (this algorithm is scalable up to matrices of size 80x80)

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

use List::Util qw(min max);
use Term::ANSIColor qw(colored);

my @matrix = map {
    [map { int rand 10_000 } 1 .. 15]
} 1 .. 15;

sub draw {
    my ($path) = @_;

    print "\e[H\e[J\e[H";
    my @screen = map {
        [map { sprintf "%4s", $_ } @{$_}]
    } @matrix;

    foreach my $p (@$path) {
        my ($i, $j) = @$p;
        $screen[$i][$j] = colored($screen[$i][$j], 'red');
    }

    foreach my $row (@screen) {
        say join(' ', @{$row});
    }
}

my %seen;

sub valid {
    not exists $seen{"@_"};
}

my %two_way_cache;
my $end = $#matrix;

sub two_way_path {
    my ($i, $j, $k, $l) = @_;

    my $key = "$i $j $k $l";
    if (exists $two_way_cache{$key}) {
        return $two_way_cache{$key};
    }

    my @paths;

    if ($i < $k) {
        push @paths, two_way_path($i + 1, $j, $k, $l);
    }

    if ($j < $l) {
        push @paths, two_way_path($i, $j + 1, $k, $l);
    }

    $two_way_cache{$key} = $matrix[$i][$j] + (min(@paths) || 0);
}

my @stack;
my $sum = 0;
my ($i, $j) = (0, 0);
my $limit = two_way_path(0, 0, $end, $end);
my $max = max(map { @$_ } @matrix);

my %min = (sum => 'inf');

while (1) {
    undef $seen{"$i $j"};
    $sum += $matrix[$i][$j];

    my @points;

    if ($i >= $end and $j >= $end) {
        if ($sum < $min{sum}) {
            $min{sum}  = $sum;
            $min{path} = [keys %seen];
        }
        @stack ? goto STACK: last;
    }

    # Skip invalid starting paths
    if (not($sum <= $limit) or not($sum <= two_way_path(0, 0, $i, $j))) {
        goto STACK if @stack;
    }

    # Skip invalid ending paths (this is a HUGE optimization)
    if (not($sum - $matrix[$i][$j] + two_way_path($i, $j, $end, $end) <= $limit + $max)) {
        goto STACK if @stack;
    }

    if ($i > 0 and valid($i - 1, $j)) {
        push @points, [$i - 1, $j];
    }

    if ($j > 0 and valid($i, $j - 1)) {
        push @points, [$i, $j - 1];
    }

    if ($i < $end and valid($i + 1, $j)) {
        push @points, [$i + 1, $j];
    }

    if ($j < $end and valid($i, $j + 1)) {
        push @points, [$i, $j + 1];
    }

  STACK: if (!@points) {
        if (@stack) {
            my ($s_sum, $s_seen, $s_pos, $s_points) = @{pop @stack};
            $sum = $s_sum;
            undef %seen;
            @seen{@$s_seen} = ();
            @points = @$s_points;
            ($i, $j) = @$s_pos;
        }
        else {
            last;
        }
    }

    my $min = splice(@points, int(rand(@points)), 1);

    if (@points) {

        my @ok = (
            grep {
                my $s = ($sum + $matrix[$_->[0]][$_->[1]]);
                $s <= $limit
                  and ($s <= two_way_path(0, 0, $_->[0], $_->[1]))
                  and ($sum + two_way_path($_->[0], $_->[1], $end, $end) <= $limit + $max)
              } @points
        );

        if (@ok) {
            push @stack, [$sum, [keys %seen], [$i, $j], \@ok];
        }
    }

    ($i, $j) = @$min;
}

my @path = map { [split ' '] } @{$min{path}};
draw(\@path);

say "\nMinimum path-sum is: $min{sum}\n";
