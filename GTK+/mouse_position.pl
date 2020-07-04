#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 November 2017
# https://github.com/trizen

# Get the current location of the mouse cursor.

use 5.010;
use strict;
use warnings;

use Gtk2 ('-init');

my (undef, $x, $y) = 'Gtk2::Window'->new->get_screen->get_display->get_pointer;

say "x=$x y=$y";
