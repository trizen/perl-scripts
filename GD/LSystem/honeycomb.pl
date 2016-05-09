#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use LSystem;
use Math::Trig qw(deg2rad);

my %rules = (
             A => '-A-B+B+B+B+',
             B => '-A+B+A+B+A+B+A-',
            );

my $scale    = 1;
my $x_offset = -500;
my $y_offset = -400;

my %stemchanges = (
    distance  => 20,
    dtheta    => deg2rad(60),
    motionsub => sub {
        my ($self, $m, $n, $o, $p) = @_;
        $self->draw(
               primitive => 'line',
               points =>
                 join(' ', $m * $scale + $x_offset, $n * $scale + $y_offset, $o * $scale + $x_offset, $p * $scale + $y_offset),
               stroke      => 'orange',
               strokewidth => 1
        );
    }
);

my $lsys = LSystem->new(1000, \%stemchanges);
$lsys->execute('A', 6, "honeycomb.png", %rules);
