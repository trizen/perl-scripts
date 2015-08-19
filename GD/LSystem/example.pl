#!/usr/bin/perl

# Translation of: https://github.com/shiffman/The-Nature-of-Code-Examples/blob/master/chp08_fractals/NOC_8_09_LSystem/NOC_8_09_LSystem.pde

use 5.014;
use strict;
use warnings;

use Turtle;
use LSystem;

my @ruleset = ({'F' => "FF+[+F-F-F-F]-[-F+F+F]"});
my $lsys = LSystem->new("F", \@ruleset);

my $width = 1920;
my $heigh = 1080;

my $turtle = Turtle->new(
                         seq    => $lsys->seq,
                         len    => $heigh / 8,
                         width  => $width,
                         height => $heigh,
                         angle  => 30,
                        );

$turtle->move_to($width / 4, $heigh / 1.5);
$turtle->rotate(-90);

foreach my $i (1 .. 4) {
    $lsys->generate;
    $turtle->set_seq($lsys->seq);
    $turtle->scale_len(0.5);
    $turtle->draw;
}

$turtle->render_as('l-system.png');
