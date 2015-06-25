#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 June 2015
# Website: https://github.com/trizen

# The snake game. (with colors + Unicode)

use utf8;
use 5.010;
use strict;
use warnings;

use Time::HiRes qw(sleep);
use Term::ANSIColor qw(colored);
use Term::ReadKey qw(ReadMode ReadLine);

binmode(STDOUT, ':utf8');

use constant {
              VOID => 0,
              HEAD => 1,
              BODY => 2,
              TAIL => 3,
              FOOD => 4,
             };

use constant {
              SNAKE_COLOR => 'bold green',
              FOOD_COLOR  => 'red',
              BG_COLOR    => 'on_black',
             };

use constant {
    U_HEAD => colored('▲', join(' ', SNAKE_COLOR, BG_COLOR)),
    D_HEAD => colored('▼', join(' ', SNAKE_COLOR, BG_COLOR)),
    L_HEAD => colored('◀', join(' ', SNAKE_COLOR, BG_COLOR)),
    R_HEAD => colored('▶', join(' ', SNAKE_COLOR, BG_COLOR)),

    U_BODY => colored('╹', join(' ', SNAKE_COLOR, BG_COLOR)),
    D_BODY => colored('╻', join(' ', SNAKE_COLOR, BG_COLOR)),
    L_BODY => colored('╴', join(' ', SNAKE_COLOR, BG_COLOR)),
    R_BODY => colored('╶', join(' ', SNAKE_COLOR, BG_COLOR)),

    U_TAIL => colored('╽', join(' ', SNAKE_COLOR, BG_COLOR)),
    D_TAIL => colored('╿', join(' ', SNAKE_COLOR, BG_COLOR)),
    L_TAIL => colored('╼', join(' ', SNAKE_COLOR, BG_COLOR)),
    R_TAIL => colored('╾', join(' ', SNAKE_COLOR, BG_COLOR)),

    A_VOID => colored(' ', BG_COLOR),
    A_FOOD => colored('❇', join(' ', FOOD_COLOR, BG_COLOR)),
             };

my $sleep    = 0.1;    # sleep duration between displays
my $food_num = 10;     # number of initial food sources

local $| = 1;

my $w = `tput cols` - 1;
my $h = `tput lines` - 1;
my $r = "\033[H";

my @grid = map {
    [map { [VOID] } 0 .. $w]
} 0 .. $h;

my %dirs = (
            left  => [+0, -1],
            right => [+0, +1],
            up    => [-1, +0],
            down  => [+1, +0],
           );

my $dir = $dirs{left};

my $head_pos = [$h / 2, $w / 2];
my $tail_pos = [$head_pos->[0], $head_pos->[1] + 1];

$grid[$head_pos->[0]][$head_pos->[1]] = [HEAD, $dir];    # head
$grid[$tail_pos->[0]][$tail_pos->[1]] = [TAIL, $dir];    # tail

sub create_food {
    my ($food_x, $food_y);

    do {
        $food_x = rand($w + 1);
        $food_y = rand($h + 1);
    } while ($grid[$food_y][$food_x][0] != VOID);

    $grid[$food_y][$food_x][0] = FOOD;
}

create_food() for (1 .. $food_num);

sub display {
    print $r, join(
        "\n",
        map {
            join(
                "",
                map {
                    my $i = 0;
                    my $t = $_->[0];

                    if (defined $_->[1]) {
                        $i =
                            $_->[1] eq $dirs{up}   ? 0
                          : $_->[1] eq $dirs{down} ? 1
                          : $_->[1] eq $dirs{left} ? 2
                          :                          3;
                    }

                        $t == HEAD ? (U_HEAD, D_HEAD, L_HEAD, R_HEAD)[$i]
                      : $t == BODY ? (U_BODY, D_BODY, L_BODY, R_BODY)[$i]
                      : $t == TAIL ? (U_TAIL, D_TAIL, L_TAIL, R_TAIL)[$i]
                      : $t == FOOD ? (A_FOOD)
                      :              (A_VOID);

                  } @{$_}
                )
          } @grid
    );
}

sub move {
    my $grew = 0;

    # Move the head
    {
        my ($y, $x) = @{$head_pos};

        my $new_y = ($y + $dir->[0]) % ($h + 1);
        my $new_x = ($x + $dir->[1]) % ($w + 1);

        my $cell = $grid[$new_y][$new_x];
        my $t    = $cell->[0];

        if ($t == BODY or $t == TAIL) {
            die "Game over!\n";
        }
        elsif ($t == FOOD) {
            create_food();
            $grew = 1;
        }

        # Create a new head
        $grid[$new_y][$new_x] = [HEAD, $dir];

        # Replace the current head with body
        $grid[$y][$x][0] = BODY;
        $grid[$y][$x][1] = $dir;

        @{$head_pos} = ($new_y, $new_x);
    }

    # Move the tail
    if (not $grew) {
        my ($y, $x) = @{$tail_pos};

        my $pos   = $grid[$y][$x][1];
        my $new_y = ($y + $pos->[0]) % ($h + 1);
        my $new_x = ($x + $pos->[1]) % ($w + 1);

        $grid[$y][$x][0]         = VOID;    # erase the current tail
        $grid[$new_y][$new_x][0] = TAIL;    # create a new tail

        @{$tail_pos} = ($new_y, $new_x);
    }
}

ReadMode(3);
while (1) {
    my $key;
    while (not defined($key = ReadLine(-1))) {
        move();
        display();
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
