#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 April 2015
# http://github.com/trizen

# A number spiral matrix, with the primes highlighted in blue
# (there are some lines that have more primes than others)

# Inspired by: https://www.youtube.com/watch?v=iFuR97YcSLM

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(is_prime);

my $n = 1847;    # duration: about 22 seconds

sub spiral {
    my ($n, $x, $y, $dx, $dy, @a) = (shift, 0, 0, 1, 0);
    foreach my $i (0 .. $n**2 - 1) {
        $a[$y][$x] = $i;
        my ($nx, $ny) = ($x + $dx, $y + $dy);
        ($dx, $dy) =
            $dx == 1  && ($nx == $n || defined $a[$ny][$nx]) ? (0,  1)
          : $dy == 1  && ($ny == $n || defined $a[$ny][$nx]) ? (-1, 0)
          : $dx == -1 && ($nx < 0   || defined $a[$ny][$nx]) ? (0,  -1)
          : $dy == -1 && ($ny < 0   || defined $a[$ny][$nx]) ? (1,  0)
          :                                                    ($dx, $dy);
        ($x, $y) = ($x + $dx, $y + $dy);
    }
    return \@a;
}

say "** Generating the matrix...";
my $matrix = spiral($n);

say "** Generating the image...";
my $img = GD::Simple->new($n, $n);

my $white = 1;
$img->fgcolor('white');

foreach my $y (0 .. $#{$matrix}) {
    $img->moveTo(0, $y);

    foreach my $num (@{$matrix->[$y]}) {
        if (is_prime($num)) {
            if ($white) {
                $img->fgcolor('blue');
                $white = 0;
            }
        }
        elsif (not $white) {
            $img->fgcolor('white');
            $white = 1;
        }
        $img->line(1);
    }
}

open my $fh, '>:raw', 'spiral_primes.png';
print $fh $img->png;
close $fh;

say "** Done!";
