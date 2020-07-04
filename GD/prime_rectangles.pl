#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 23 May 2016
# Website: https://github.com/trizen

# Draw overlapping prime rectangles.

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(forprimes prev_prime);

my $P = prev_prime(1000) + 1;
my $img = GD::Simple->new($P, $P);

$img->bgcolor(undef);
$img->fgcolor('red');

forprimes {
    my $p = $_;
    forprimes {
        $img->rectangle(1, 1, $_, $p);
    } 0, $P;
} 0, $P;

open my $fh, '>:raw', 'prime_rectangles.png';
print {$fh} $img->png;
close $fh;
