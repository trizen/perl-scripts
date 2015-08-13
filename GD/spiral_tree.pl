#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 August 2015
# http://github.com/trizen

# Generate a spiral tree with branches
# Inspired from: https://www.youtube.com/watch?v=RWAcbV4X7C8

use GD::Simple;
my $img = GD::Simple->new(1000, 700);

$img->moveTo(500, 650);
$img->turn(-90);

sub branch {
    my ($len) = @_;

    $img->line($len);
    $len *= 0.64;

    if ($len > 2) {

        my @pos1   = $img->curPos;
        my $angle1 = $img->angle;

        $img->turn(45);
        branch($len);
        $img->moveTo(@pos1);
        $img->angle($angle1);

        my @pos2   = $img->curPos;
        my $angle2 = $img->angle;

        $img->turn(-90);
        branch($len);
        $img->moveTo(@pos2);
        $img->angle($angle2);
    }
}

branch(250);

open my $fh, '>:raw', 'spiral_tree.png';
print $fh $img->png;
close $fh;
