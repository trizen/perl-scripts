#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11 April 2015
# http://github.com/trizen

# A zig-zag matrix with the primes highlighted in blue

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(is_prime);

sub zig_zag {
    my ($w, $h) = @_;

    #
    ## Code from: http://rosettacode.org/wiki/Zig-zag_matrix#Perl
    #

    my (@r, $n);
    $r[$_->[1]][$_->[0]] = $n++
      for
      sort { $a->[0] + $a->[1] <=> $b->[0] + $b->[1] or ($a->[0] + $a->[1]) % 2 ? $a->[1] <=> $b->[1] : $a->[0] <=> $b->[0] }
      map {
        my $e = $_;
        map { [$e, $_] } 0 .. $w - 1
      } 0 .. $h - 1;

    return \@r;
}

my $x = 1000;
my $y = 1000;

my $matrix = zig_zag($x, $y);

# create a new image
my $img = GD::Simple->new($x, $y);

my $white = 1;
$img->fgcolor('white');

foreach my $i (0 .. $x - 1) {
    $img->moveTo(0, $i);
    foreach my $j (0 .. $y - 1) {
        if (is_prime($matrix->[$i][$j])) {
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

open my $fh, '>:raw', 'zig-zag_primes.png';
print $fh $img->png;
close $fh;
