#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib qw(.);
use LSystem;

my %rules = (
             S => 'T-[[S]+S]+T[+TS]-S',
             T => 'TT',                   # or: 'T[S]T'
            );

my $lsys = LSystem->new(
    width  => 1000,
    height => 1000,

    scale => 0.7,
    xoff  => -200,
    yoff  => 300,

    len   => 8,
    angle => 25,
    color => 'dark green',
                       );

$lsys->execute('S', 6, "plant_2.png", %rules);
