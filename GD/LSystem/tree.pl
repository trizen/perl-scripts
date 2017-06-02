#!/usr/bin/perl

use strict;
use warnings;

use lib qw(.);
use LSystem;

my %rules = (
             a => 'S[---l:a][++++b]',
             b => 'S[++lb][--c]',
             c => 'S[-----lb]gS[+:c]',
             l => '[{S+S+S+S+S+S}]'
            );

my $lsys = LSystem->new(
    width  => 800,
    height => 800,
    xoff   => -400,

    len   => 35,
    angle => 5,
    color => 'dark green',
                       );

$lsys->execute('a', 10, "tree.png", %rules);
