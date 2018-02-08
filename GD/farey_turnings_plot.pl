#!/usr/bin/perl

# Plot the turnings in the Farey approximation process.

# See also:
#   https://en.wikipedia.org/wiki/Farey_sequence
#   https://en.wikipedia.org/wiki/Stern%E2%80%93Brocot_tree

use 5.020;
use strict;
use warnings;

use GD::Simple;
use Math::AnyNum;
use experimental qw(signatures);

sub farey_approximation ($r, $rep) {

    use Math::AnyNum qw(:overload);
    my ($a, $b, $c, $d) = (0, 1, 1, 0);

    my $eps = 2.0**-($Math::AnyNum::PREC / '1.5');

    my $turns = '';

    foreach (1 .. $rep) {
        my $m = ($a + $c) / ($b + $d);

        if ($m < $r) {
            ($a, $b) = $m->nude;
            $turns .= '0';
        }
        elsif ($m > $r) {
            ($c, $d) = $m->nude;
            $turns .= '1';
        }
        else {
            last;
        }

        if (abs($m - $r) <= $eps) {
            say "Reached target precision... Breaking...";
            last;
        }
    }

    return $turns;
}

my $turns = do {
    local $Math::AnyNum::PREC = 30000;
    farey_approximation(Math::AnyNum::tau(), 80000);
};

say substr($turns, 0, 50);

my $width  = 2000;
my $height = 2000;

my $img = 'GD::Simple'->new($width, $height);

$img->moveTo($width >> 1, $height >> 2);

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
