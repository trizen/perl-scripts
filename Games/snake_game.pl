#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 June 2015
# Website: https://github.com/trizen

# The classic snake game (concept-only).

use 5.010;
use strict;
use warnings;

use Time::HiRes qw(sleep);
use Term::ReadKey qw(ReadMode ReadLine);

my $w = `tput cols` - 2;
my $h = `tput lines` - 2;
my $r = "\033[H";

my @grid = map {
    [map { 0 } 0 .. $w]
} 0 .. $h;

my %dirs = (
            left  => [0,  -1],
            right => [0,  +1],
            up    => [-1, 0],
            down  => [+1, 0],
           );

$grid[$h / 2][$w / 2] = 1;      # head
$grid[rand $h][rand $w] = 3;    # food

sub print_grid {
    print $r;
    foreach my $row (@grid) {
        foreach my $cell (@{$row}) {
            print $cell == 1 ? '@' : $cell == 2 ? '*' : $cell == 3 ? '#' : ' ';
        }
        print "\n";
    }
}

sub move {
    my ($pos) = @_;

  L1: foreach my $y (0 .. $#grid) {
        foreach my $x (0 .. $#{$grid[0]}) {

            # Found head
            if ($grid[$y][$x] == 1) {

                my $new_y = ($y + $pos->[0]) % @grid;
                my $new_x = ($x + $pos->[1]) % @{$grid[0]};

                my $spot = $grid[$new_y][$new_x];

                # Its own body
                if ($spot == 2) {
                    die "Game over!";
                }

                # Food
                elsif ($spot == 3) {
                    $grid[rand($h + 1)][rand($w + 1)] = 3;
                }

                # Make the move
                $grid[$new_y][$new_x] = 1;
                $grid[$y][$x]         = 0;
                last L1;
            }
        }
    }

    # ...
}

my $last = $dirs{right};

ReadMode(3);
while (1) {
    my $key;
    while (not defined($key = ReadLine(-1))) {

        move($last);
        print_grid();

        sleep(
              $last eq $dirs{up} || $last eq $dirs{down}
              ? 0.15
              : 0.1
             );
    }

    # up
    if ($key eq "\e[A") {
        $last = $dirs{up};
    }

    # down
    elsif ($key eq "\e[B") {
        $last = $dirs{down};
    }

    # right
    elsif ($key eq "\e[C") {
        $last = $dirs{right};
    }

    # left
    elsif ($key eq "\e[D") {
        $last = $dirs{left};
    }
}
