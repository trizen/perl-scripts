#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 June 2015
# Website: https://github.com/trizen

# The snake game.

use 5.010;
use strict;
use warnings;

use Time::HiRes qw(sleep);
use Term::ReadKey qw(ReadMode ReadLine);

use constant {
              VOID => 0,
              HEAD => 1,
              BODY => 2,
              TAIL => 3,
              FOOD => 4,
             };

use constant {
    UD_HEAD => '@',
    LR_HEAD => '@',

    UD_BODY => '+',
    LR_BODY => '+',

    UD_TAIL => ';',
    LR_TAIL => '~',

    SPACE => ' ',
             };

my $sleep = 0.1;

my $w = `tput cols` - 2;
my $h = `tput lines` - 2;
my $r = "\033[H";

my @grid = map {
    [map { [VOID] } 0 .. $w]
} 0 .. $h;

my %dirs = (
            left  => [0,  -1],
            right => [0,  +1],
            up    => [-1, 0],
            down  => [+1, 0],
           );

my $dir = $dirs{left};

$grid[$h / 2][$w / 2] = [HEAD, $dir];        # head
$grid[$h / 2][$w / 2 + 1] = [TAIL, $dir];    # tail
$grid[rand $h][rand $w] = [FOOD];            # food

sub print_grid {
    print $r;
    foreach my $row (@grid) {
        foreach my $cell (@{$row}) {
            my $t = $cell->[0];
            my $ud = defined($cell->[1]) ? ($cell->[1] eq $dirs{up} || $cell->[1] eq $dirs{down}) : 0;
            print($t == HEAD
                  ? ($ud ? UD_HEAD : LR_HEAD)
                  : $t == FOOD ? q{#}
                  : $t == BODY ? ($ud ? UD_BODY : LR_BODY)
                  : $t == TAIL ? ($ud ? UD_TAIL : LR_TAIL)
                  :              (SPACE)
                 );
        }
        print "\n";
    }
}

sub move {

    my $grow = 0;

  L1: foreach my $y (0 .. $h) {
        foreach my $x (0 .. $w) {

            # Found head
            if ($grid[$y][$x][0] == HEAD) {

                my $new_y = ($y + $dir->[0]) % ($h + 1);
                my $new_x = ($x + $dir->[1]) % ($w + 1);

                my $cell = $grid[$new_y][$new_x];
                my $t    = $cell->[0];

                if ($t == BODY or $t == TAIL) {
                    die "Game over!\n";
                }
                elsif ($t == FOOD) {
                    my ($food_x, $food_y);

                    do {
                        $food_x = rand($w + 1);
                        $food_y = rand($h + 1);
                    } while ($grid[$food_y][$food_x][0] != VOID);

                    $grid[$food_y][$food_x][0] = FOOD;
                    $grow = 1;
                }

                # Make the move
                $grid[$new_y][$new_x] = [HEAD, $dir];

                $grid[$y][$x][0] = BODY;
                $grid[$y][$x][1] = $dir;

                last L1;
            }
        }
    }

  L2: foreach my $y (0 .. $h) {
        foreach my $x (0 .. $w) {

            # Found tail
            if ($grid[$y][$x][0] == TAIL) {
                my $pos = $grid[$y][$x][1];

                my $new_y = ($y + $pos->[0]) % ($h + 1);
                my $new_x = ($x + $pos->[1]) % ($w + 1);

                if ($grow) {
                    $grid[$new_y][$new_x][0] = BODY;
                }
                else {
                    $grid[$y][$x][0]         = VOID;
                    $grid[$new_y][$new_x][0] = TAIL;
                }

                last L2;
            }
        }
    }
}

ReadMode(3);
while (1) {
    my $key;
    while (not defined($key = ReadLine(-1))) {

        move();
        print_grid();

        sleep($sleep);
    }

    # up
    if ($key eq "\e[A") {
        $dir = $dirs{up};
    }

    # down
    elsif ($key eq "\e[B") {
        $dir = $dirs{down};
    }

    # right
    elsif ($key eq "\e[C") {
        $dir = $dirs{right};
    }

    # left
    elsif ($key eq "\e[D") {
        $dir = $dirs{left};
    }
}
