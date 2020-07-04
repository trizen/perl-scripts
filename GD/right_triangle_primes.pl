#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11 April 2015
# http://github.com/trizen

# A number triangle, with the primes highlighted in blue
# (there are some lines that have more primes than others)

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(is_prime);

my $n = 1000000;    # duration: about 5 seconds

sub limit {
    my ($n) = @_;
    (sqrt(8 * $n + 1) - 1) / 2;
}

sub round {
    my ($n) = @_;
    ($n**2 + $n) / 2;
}

my $lim = int(limit($n));
my $num = round($lim);

# create a new image
my $img = GD::Simple->new($lim, $lim);

my $counter = 1;
my $white   = 1;
$img->fgcolor('white');

foreach my $i (0 .. $lim - 1) {
    $img->moveTo(0, $i);
    foreach my $j (0 .. $i) {
        ##print $counter, ' ';
        if (is_prime($counter)) {
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
        ++$counter;
    }
    ##print "\n";
}

open my $fh, '>:raw', 'right_triangle_primes.png';
print $fh $img->png;
close $fh;
