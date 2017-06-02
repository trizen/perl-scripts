#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib qw(.);
use LSystem;

my %rules = (F => 'FF-[-F+F-F]+[+F-F]');

my $lsys = LSystem->new(
    width  => 1000,
    height => 1000,
    xoff   => -350,

    len   => 8,
    angle => 25,
    color => 'dark green',
                       );

$lsys->execute('F', 5, "plant_3.png", %rules);
