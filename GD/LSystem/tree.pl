#!/usr/bin/perl

use strict;
use warnings;

use LSystem;

my %rules = (
             'A' => 'S[---LMA][++++B]',
             'B' => 'S[++LB][--C]',
             'C' => 'S[-----LB]GS[+MC]',
             'L' => '[{S+S+S+S+S+S}]'
            );

my $x_offset = -400;

my %stemchanges = (
    distance  => 35,
    dtheta    => 0.1,
    motionsub => sub {
        my ($self, $m, $n, $o, $p) = @_;
        $self->draw(
                    primitive   => 'line',
                    points      => join(' ', $m + $x_offset, $n, $o + $x_offset, $p),
                    stroke      => 'dark green',
                    strokewidth => 1
                   );
    }
);

my %polychanges = (
    distance  => 5,
    dtheta    => 0.4,
    motionsub => sub {
        my ($self, $x, $y) = @_;
        push(@{$self->{poly}}, $x + $x_offset, $y);
    }
);

my $lsys = LSystem->new(800, \%stemchanges, \%polychanges);
$lsys->execute('A', 10, "tree.png", %rules);
