#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 August 2019
# https://github.com/trizen

# A simple program to cheat in the "Reaction time test".
# https://www.humanbenchmark.com/tests/reactiontime

use 5.014;
use strict;
use warnings;

use GD;
use Time::HiRes qw(sleep);

say "Starting...";
sleep 5;
system("xdotool", "click", "1");    # click to start

my $count = 0;

while (1) {

    my $gd = GD::Image->new(scalar `maim --geometry '20x20+1+300' --format=jpg /dev/stdout`);

    my $pixel = $gd->getPixel(0, 0);    # test first pixel
    my ($r, $g, $b) = $gd->rgb($pixel);

    if ($g > 100) {                     # test for greenness
        say "Detected green...";

        system("xdotool", "click", "1");    # green detected
        last if ++$count == 5;

        sleep(2);
        system("xdotool", "click", "1");    # click to continue
        sleep 2;
    }

    sleep 0.0001;
}
