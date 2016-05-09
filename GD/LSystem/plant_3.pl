#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use LSystem;
use Math::Trig qw(deg2rad);

my %rules = (F => 'FF-[-F+F-F]+[+F-F]');

my $scale    = 1;
my $x_offset = -350;
my $y_offset = 0;

my %stemchanges = (
    distance  => 8,
    dtheta    => deg2rad(25),
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
$lsys->execute('F', 5, "plant_3.png", %rules);
