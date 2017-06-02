#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib qw(.);
use LSystem;

my %rules = (S => 'SS+[+S-S-S]-[-S+S+S]');

my $lsys = LSystem->new(
    width  => 1000,
    height => 1000,
    xoff   => -600,

    len   => 8,
    angle => 25,
    color => 'dark green',
                       );

$lsys->execute('S', 5, "plant.png", %rules);
