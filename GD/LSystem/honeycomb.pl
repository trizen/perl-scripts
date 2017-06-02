#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib qw(.);
use LSystem;

my %rules = (
             A => '-A-B+B+B+B+',
             B => '-A+B+A+B+A+B+A-',
            );

my $lsys = LSystem->new(
    width  => 1000,
    height => 1000,

    scale => 1,
    xoff  => -500,
    yoff  => -400,

    len   => 20,
    angle => 60,
    color => 'orange',
                       );

$lsys->execute('A', 6, "honeycomb.png", %rules);
