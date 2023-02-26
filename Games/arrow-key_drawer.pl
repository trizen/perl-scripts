#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 June 2015
# Edit: 26 February 2023
# Website: https://github.com/trizen

# Draw right-angle abstract-art using the arrow-keys.

use utf8;
use 5.010;
use strict;
use warnings;

use Time::HiRes     qw(sleep);
use Term::ANSIColor qw(colored);
use Term::ReadKey   qw(ReadMode ReadLine);

binmode(STDOUT, ':utf8');

use constant {
              VOID => 0,
              HEAD => 1,
              BODY => 2,
             };

use constant {
              LEFT  => [+0, -1],
              RIGHT => [+0, +1],
              UP    => [-1, +0],
              DOWN  => [+1, +0],
             };

use constant {BG_COLOR  => 'on_black'};
use constant {PEN_COLOR => ('bold green' . ' ' . BG_COLOR)};

use constant {
    U_HEAD => colored('▲', PEN_COLOR),
    D_HEAD => colored('▼', PEN_COLOR),
    L_HEAD => colored('◀', PEN_COLOR),
    R_HEAD => colored('▶', PEN_COLOR),

    U_BODY => colored('■', PEN_COLOR),
    D_BODY => colored('■', PEN_COLOR),
    L_BODY => colored('■', PEN_COLOR),
    R_BODY => colored('■', PEN_COLOR),

    A_VOID => colored(' ', BG_COLOR),
};

my $sleep = 0.07;    # sleep duration between displays

local $| = 1;

my $w = eval { `tput cols` }  || 80;
my $h = eval { `tput lines` } || 24;
my $r = "\033[H";

my @grid = map {
    [map { [VOID] } 1 .. $w]
} 1 .. $h;

my $dir      = LEFT;
my @head_pos = ($h / 2, $w / 2);
my @tail_pos = ($head_pos[0], $head_pos[1] + 1);

$grid[$head_pos[0]][$head_pos[1]] = [HEAD, $dir];    # head

sub display {
    print $r, join(
        "\n",
        map {
            join(
                "",
                map {
                    my $t = $_->[0];
                    my $p = $_->[1] // '';

                    my $i =
                        $p eq UP   ? 0
                      : $p eq DOWN ? 1
                      : $p eq LEFT ? 2
                      :              3;

                        $t == HEAD ? (U_HEAD, D_HEAD, L_HEAD, R_HEAD)[$i]
                      : $t == BODY ? (U_BODY, D_BODY, L_BODY, R_BODY)[$i]
                      :              (A_VOID);

                } @{$_}
            )
          } @grid
    );
}

sub move {

    # Move the pen head
    my ($y, $x) = @head_pos;

    my $new_y = ($y + $dir->[0]) % $h;
    my $new_x = ($x + $dir->[1]) % $w;

    my $cell = $grid[$new_y][$new_x];
    my $t    = $cell->[0];

    # Create a new head
    $grid[$new_y][$new_x] = [HEAD, $dir];

    # Replace the current head with body
    $grid[$y][$x] = [BODY, $dir];

    # Save the position of the head
    @head_pos = ($new_y, $new_x);
}

ReadMode(3);
while (1) {
    my $key;
    until (defined($key = ReadLine(-1))) {
        move();
        display();
        sleep($sleep);
    }

    if    ($key eq "\e[A") { $dir = UP }
    elsif ($key eq "\e[B") { $dir = DOWN }
    elsif ($key eq "\e[C") { $dir = RIGHT }
    elsif ($key eq "\e[D") { $dir = LEFT }
}
