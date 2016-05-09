#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use LSystem;
use Math::Trig qw(deg2rad);

my %rules = (
             'S' => 'S--S--S--T',
             'T' => 'TT',
            );

my $scale    = 0.4;
my $x_offset = -280;
my $y_offset = 400;

my %stemchanges = (
    distance  => 30,
    dtheta    => deg2rad(120),
    motionsub => sub {
        my ($self, $m, $n, $o, $p) = @_;
        $self->draw(
               primitive => 'line',
               points =>
                 join(' ', $m * $scale + $x_offset, $n * $scale + $y_offset, $o * $scale + $x_offset, $p * $scale + $y_offset),
               stroke      => 'dark green',
               strokewidth => 1
        );
    }
);

my $lsys = LSystem->new(1000, \%stemchanges);

$lsys->turtle->turn(deg2rad(30));
$lsys->execute('S--S--S', 7, "sierpinski_triangle.png", %rules);
