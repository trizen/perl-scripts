#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 15 December 2013
# Website: http://trizenx.blgospot.com

# Variation of: http://rosettacode.org/wiki/Langton%27s_ant#Perl
# More info about Langton's ant: http://en.wikipedia.org/wiki/Langton%27s_ant

use 5.010;
use strict;
use warnings;
use GD::Simple;

my $width  = 12480;
my $height = 7020;

my $line = 10;     # line length
my $size = 1000;    # pattern size

my $turn_left_color  = 'red';
my $turn_right_color = 'black';

my $img_file = 'random_langton_s_ant.png';

my $p = GD::Simple->new($width, $height);
$p->moveTo($width / 2, $height / 2);

# Using screen coordinates - 0,0 in upper-left, +X right, +Y down -
# these directions (right, up, left, down) are counterclockwise
# so advance through the array to turn left, retreat to turn right
my @dirs = ([1, 0], [0, -1], [-1, 0], [0, 1]);

# we treat any false as white and true as black, so undef is fine for initial all-white grid
my @plane;
for (0 .. $size - 1) { $plane[$_] = [(map {int(rand(2))} 1..rand(100)) x rand(100)] }

# start out in approximate middle
my ($x, $y) = ($size / 2, $size / 2);

# pointing in a random direction
my $dir = int rand @dirs;

# turn in a random direction
$p->turn(90 * $dir);

my $move;
for ($move = 0 ; $x >= 0 && $x < $size && $y >= 0 && $y < $size ; $move++) {

    # toggle cell's value (white->black or black->white)
    if ($plane[$x][$y] = 1 - ($plane[$x][$y] ||= 0)) {

        # if it's now true (black), then it was white, so turn right
        $p->fgcolor($turn_right_color);
        $p->line($line);

        # for more interesting patterns, try multiplying 90 with $dir
        $p->turn(90);

        $dir = ($dir - 1) % @dirs;
    }
    else {

        # otherwise it was black, so turn left
        $p->fgcolor($turn_left_color);
        $p->line($line);
        $p->turn(-90);

        $dir = ($dir + 1) % @dirs;
    }

    $x += $dirs[$dir][0];
    $y += $dirs[$dir][1];
}

open my $fh, '>', $img_file
  or die "$img_file: $!";
print {$fh} $p->png;
close $fh;
