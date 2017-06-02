#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib qw(.);
use LSystem;

my %rules = (
             F => '+F-F-F-F-F-F-F-F-F+',    # or: '+F-F-F-F-F-F-F+'
            );

my $lsys = LSystem->new(
    width  => 1200,
    height => 1000,

    scale => 1,
    xoff  => -600,
    yoff  => -180,

    len   => 20,
    angle => 60,
    color => 'orange',
                       );

$lsys->execute('F', 5, "honeycomb_2.png", %rules);
