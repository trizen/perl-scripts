#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 May 2013
# https://github.com/trizen

# Dice game solver

use 5.010;
use strict;
use warnings;

my $board = [
             [4, 1, 3, 3, 5, 2],
             [3, 4, 1, 2, 0, 3],
             [5, 1, 5, 5, 4, 2],
             [1, 3, 2, 5, 2, 1],
             [6, 2, 4, 1, 5, 4],
             [6, 2, 1, 6, 6, 3],
            ];

my %moves = (
             'up'         => [-1, +0],
             'up-right'   => [-1, +1],
             'up-left'    => [-1, -1],
             'right'      => [+0, +1],
             'left'       => [+0, -1],
             'down'       => [+1, +0],
             'down-left'  => [+1, -1],
             'down-right' => [+1, +1],
            );

my @directions = keys %moves;

sub valid_move {
    my ($row, $col) = @_;

    if ($row < 0 or not exists $board->[$row]) {
        return;
    }

    if ($col < 0 or not exists $board->[$row][$col]) {
        return;
    }

    return 1;
}

while (1) {
    my %map;
    my %seen;
    my @dirs;
    my %spos;

    my $current_pos = [$#{$board}, 0];
    my $current_num = $board->[$current_pos->[0]][$current_pos->[1]];

    $spos{join('|', @{$current_pos})}++;

    foreach my $num (1 .. @{$board}**2) {

        my $dir = (
            exists $map{$current_num}
            ? $map{$current_num}
            : do {

                my %table;
                @table{values %map} = ();

                my $d;

                do {
                    $d = $directions[rand @directions];
                } while (exists($table{$d}));

                $d;
              }
        );

        my $pos = $moves{$dir};
        my $row = $current_pos->[0] + $pos->[0];
        my $col = $current_pos->[1] + $pos->[1];

        valid_move($row, $col) || last;
        if (++$spos{join('|', $row, $col)} > 1) {
            last;
        }

        push @dirs, {dir => $dir, num => $current_num, pos => $current_pos};

        $map{$current_num} //= $dir;
        $current_pos = [$row, $col];
        $current_num = $board->[$current_pos->[0]][$current_pos->[1]];
        $seen{$current_num}++;

        if ($current_num == 0) {
            if ($seen{$board->[$current_pos->[0] - $pos->[0]][$current_pos->[1] - $pos->[1]]} > 1) {
                use Data::Dump qw(pp);
                pp \@dirs;
                exit;
            }
            last;
        }
    }
}
