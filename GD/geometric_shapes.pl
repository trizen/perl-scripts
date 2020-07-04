#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 02th December 2013
# Website: http://trizenx.blgospot.com

# This script tries to generate geometric shapes with a consistent internal angle size

use 5.010;
use strict;
use autodie;
use warnings;
use GD::Simple;

my $width  = 3000;
my $height = 3000;

my $step      = 1;
my $len       = 500;
my $sides     = 360;
my $max_angle = 160;

my $dir = 'Geometric shapes';

(-d $dir) || (mkdir($dir));
chdir($dir);

for (my $angle = 30 ; $angle <= $max_angle ; $angle += $step) {

    my $p = GD::Simple->new($width, $height);

    $p->fgcolor('blue');
    $p->moveTo(1500, 1000);

    my %seen;
    my $text  = '';
    my $valid = 0;

    foreach my $i (1 .. $sides) {
        if ($seen{join $;, $p->curPos}++) {
            $text = sprintf "%d degrees internal angle with %d sides", 180 - $angle, $i - 1;
            $valid = 1;
            last;
        }

        $p->turn($angle);
        $p->line($len);
    }

    $valid || next;

    say $text;

    # $p->moveTo($width / 2 - length($text) * 3, $height - 100);
    # $p->string($text);

    open my $fh, '>', sprintf("%05d.png", 180 - $angle);
    print {$fh} $p->png;
    close $fh;

    #system "geeqie", $img_file;
    #$? && exit $? << 8;
}
