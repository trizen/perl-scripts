#!/usr/bin/perl

# Simulate the toppling of sandpiles.

# See also:
#   https://en.wikipedia.org/wiki/Abelian_sandpile_model
#   https://www.youtube.com/watch?v=1MtEUErz7Gg -- ‎Sandpiles - Numberphile
#   https://www.youtube.com/watch?v=diGjw5tghYU -- ‎Coding Challenge #107: Sandpiles (by Daniel Shiffman)

use 5.020;
use strict;
use warnings;

use Imager;
use experimental qw(signatures);

package Sandpile {

    sub new ($class, %opt) {

        my $state = {
                     width  => 100,
                     height => 100,
                     %opt,
                    };

        bless $state, $class;
    }

    sub create_plane ($self) {
        [map { [(0) x $self->{width}] } 1 .. $self->{height}];
    }

    sub topple ($self, $plane) {

        my $nextplane = $self->create_plane;

        foreach my $y (0 .. $self->{height} - 1) {
            foreach my $x (0 .. $self->{width} - 1) {
                my $pile = $plane->[$y][$x];

                if ($pile < 4) {
                    $nextplane->[$y][$x] = $pile;
                }
            }
        }

        foreach my $y (1 .. $self->{height} - 2) {
            foreach my $x (1 .. $self->{width} - 2) {
                my $pile = $plane->[$y][$x];

                if ($pile >= 4) {
                    $nextplane->[$y][$x] += $pile - 4;
                    $nextplane->[$y - 1][$x]++;
                    $nextplane->[$y + 1][$x]++;
                    $nextplane->[$y][$x - 1]++;
                    $nextplane->[$y][$x + 1]++;
                }
            }
        }

        return $nextplane;
    }

    sub generate ($self, $pile_of_sand, $topple_times) {

        my $plane = $self->create_plane;
        $plane->[$self->{height} / 2][$self->{width} / 2] = $pile_of_sand;

        for (1 .. $topple_times) {
            $plane = $self->topple($plane);
        }

        my $img    = Imager->new(xsize => $self->{width}, ysize => $self->{height});
        my @colors = map { Imager::Color->new($_) } ('black', 'blue', 'green', 'white');

        foreach my $y (0 .. $self->{height} - 1) {
            foreach my $x (0 .. $self->{width} - 1) {

                my $pile = $plane->[$y][$x];

                if ($pile <= 3) {
                    $img->setpixel(x => $x, y => $y, color => $colors[$pile]);
                }
            }
        }

        return $img;
    }
}

my $obj = Sandpile->new;
my $img = $obj->generate(10**5, 10**4);

$img->write(file => 'sandpiles.png');
