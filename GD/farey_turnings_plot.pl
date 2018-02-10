#!/usr/bin/perl

# Plot the turnings in the Farey approximation process.

# See also:
#   https://en.wikipedia.org/wiki/Farey_sequence
#   https://en.wikipedia.org/wiki/Stern%E2%80%93Brocot_tree

use 5.020;
use strict;
use warnings;

use GD::Simple;
use Math::AnyNum qw(abs);
use experimental qw(signatures);

sub farey_approximation ($r) {

    my ($m, $n) = abs($r)->rat_approx->nude;

    my $enc = '';

    for (; ;) {
        if ((($m <=> $n) || last) < 0) {
            $enc .= '0';
            $n -= $m;
        }
        else {
            $enc .= '1';
            $m -= $n;
        }
    }

    return $enc;
}

my $turns = do {
    local $Math::AnyNum::PREC = 30000;
    farey_approximation(Math::AnyNum::tau());
};

say substr($turns, 0, 50);

my $width  = 2000;
my $height = 2000;

my $img = 'GD::Simple'->new($width, $height);

$img->moveTo($width / 1.75, $height / 1.25);

my $angle = 60;

foreach my $t (split(//, $turns)) {

    $t
      ? $img->turn($angle)
      : $img->turn(-$angle);

    $img->line(5);
}

open my $fh, '>:raw', 'farey_plot.png' or die $!;
print {$fh} $img->png;
close $fh;
