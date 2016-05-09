#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use LSystem;
use Math::Trig qw(grad2rad);

my %rules = (
             S => 'T-[[S]+S]+T[+TS]-S',
             T => 'TT',         # or: 'T[S]T'
            );

my $scale    = 0.7;
my $x_offset = -200;
my $y_offset = 300;

my %stemchanges = (
    distance  => 8,
    dtheta    => grad2rad(25),
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
$lsys->execute('S', 6, "plant_2.png", %rules);
