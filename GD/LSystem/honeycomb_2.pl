#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use LSystem;

my %rules = (F => 'F[-F][+F]');

my $lsys = LSystem->new(
    width  => 1000,
    height => 1000,

    scale => 1,
    xoff  => -500,
    yoff  => -500,

    len   => 20,
    angle => 60,
    color => 'orange',
                       );
$lsys->execute('F', 10, "honeycomb_2.png", %rules);
