#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib qw(.);
use LSystem;

my %rules = (
             S => 'S--S--S--T',
             T => 'TT',
            );

my $lsys = LSystem->new(
    width  => 1000,
    height => 1000,

    scale => 0.4,
    xoff  => -280,
    yoff  => 400,

    len   => 30,
    angle => 120,
    turn  => 30,
    color => 'dark red',
                       );

$lsys->execute('S--S--S', 7, "sierpinski_triangle.png", %rules);
