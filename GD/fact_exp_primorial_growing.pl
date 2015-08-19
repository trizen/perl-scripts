#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 19 August 2015
# Website: https://github.com/trizen

# Plot the growing of exponentiation, factorial and primorial.

# blue is n!
# green is n^n
# red is n-primorial

# The plot is logarithmic in base e.

use 5.010;
use strict;
use warnings;

use Imager qw();
use ntheory qw(nth_prime);

my $xsize = 250;
my $ysize = 600;

my $img = Imager->new(xsize => $xsize, ysize => $ysize);

my $white = Imager::Color->new('#ffffff');
my $red   = Imager::Color->new('#ff0000');
my $blue  = Imager::Color->new('#0000ff');
my $green = Imager::Color->new('#00ff00');

$img->box(filled => 1, color => $white);

my $x = 0;

{
    use bigint (try => 'GMP');

    my $f = 1;
    my $p = 1;

    for (my $i = 1 ; $i <= 100 ; $i->binc) {

        $f->bmul($i + 1);
        $p->bmul(nth_prime($i->bstr));

        $img->setpixel(x => $x, y => $p->copy->blog->bsub($ysize)->babs->bstr,           color => $red);
        $img->setpixel(x => $x, y => $f->copy->blog->bsub($ysize)->babs->bstr,           color => $blue);
        $img->setpixel(x => $x, y => $i->copy->bpow($i)->blog->bsub($ysize)->babs->bstr, color => $green);

        $x++;
    }
}

$img->write(file => 'grow.png');
