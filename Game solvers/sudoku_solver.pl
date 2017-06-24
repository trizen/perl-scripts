#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 January 2017
# https://github.com/trizen

# Recursive brute-force Sudoku solver.

# See also:
#   https://en.wikipedia.org/wiki/Sudoku

use 5.016;
use strict;

sub check {
    my ($i, $j) = @_;

    use integer;

    my ($id, $im) = ($i / 9, $i % 9);
    my ($jd, $jm) = ($j / 9, $j % 9);

    $jd == $id && return 1;
    $jm == $im && return 1;

        $id / 3 == $jd / 3
    and $jm / 3 == $im / 3;
}

my @lookup;
foreach my $i (0 .. 80) {
    foreach my $j (0 .. 80) {
        $lookup[$i][$j] = check($i, $j);
    }
}

sub solve_sudoku {
    my ($callback, @grid) = @_;

    sub {
        foreach my $i (0 .. 80) {
            if (!$grid[$i]) {

                my %t;
                undef @t{@grid[grep { $lookup[$i][$_] } 0 .. 80]};

                foreach my $k (1 .. 9) {
                    if (!exists $t{$k}) {
                        $grid[$i] = $k;
                        __SUB__->();
                    }
                }

                $grid[$i] = 0;
                return;
            }
        }

        $callback->(@grid);
    }->();
}

my @grid = qw(
  5 3 0  0 2 4  7 0 0
  0 0 2  0 0 0  8 0 0
  1 0 0  7 0 3  9 0 2

  0 0 8  0 7 2  0 4 9
  0 2 0  9 8 0  0 7 0
  7 9 0  0 0 0  0 8 0

  0 0 0  0 3 0  5 0 6
  9 6 0  0 1 0  3 0 0
  0 5 0  6 9 0  0 1 0
  );

solve_sudoku(
    sub {
        my (@solution) = @_;
        foreach my $i (0 .. $#solution) {
            print "$solution[$i] ";
            print " "  if ($i + 1) % 3 == 0;
            print "\n" if ($i + 1) % 9 == 0;
            print "\n" if ($i + 1) % 27 == 0;
        }
    }, @grid
);
