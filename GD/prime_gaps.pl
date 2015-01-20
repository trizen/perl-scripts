#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 January 2015
# https://github.com/trizen

use 5.010;
use strict;
use warnings;

use List::Util qw(shuffle);

my $i = 10_000;

# Init the GD::Simple module
require GD::Simple;
my $img = GD::Simple->new($i, $i / 2);

my @colors = shuffle(GD::Simple->color_names);

my $imgFile = 'graph.png';

sub l {
    $img->line(shift);
}

sub t {
    $img->turn(shift);
}

sub c {
    $img->fgcolor(shift);
}

sub mv {
    $img->moveTo(@_);
}

my $x = 0;
my $y = int($i / 2 / (4 / 3));
mv($x, $y);
t(-90);

my $last_prime = 2;
OUTER: for (my $i = 3 ; $i <= 100_000 ; $i += 2) {
    foreach my $j (2 .. sqrt($i)) {
        $i % $j || next OUTER;
    }

    my $diff = $i - $last_prime;
    $img->fgcolor($colors[$diff % @colors]);

    l($diff * 40);
    if ($diff > 20) {
        $img->string($diff);
    }
    t(360);
    $x += 2;
    mv($x, $y);

    $last_prime = $i;
}

open my $fh, '>:raw', 'prime_gaps.png';
print $fh $img->png;
close $fh;
system 'geeqie', 'prime_gaps.png';
