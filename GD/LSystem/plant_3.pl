#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use LSystem;
use Math::Trig qw(deg2rad);

my %rules = (
             F=>'CFF-[C-F+F]+[C+F-F]',
             X=>'CFF+[C+F]+[C-F]',
            );

my $scale    = 0.5;
my $x_offset = 0;
my $y_offset = 500;

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
$lsys->execute('FX', 5, "snowflake.png", %rules);
