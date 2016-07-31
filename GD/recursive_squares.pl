#!/usr/bin/perl

# A nice recursive pattern, using the following rule:

#           ---               |---|
# | goes to  |  which goes to   |   and so on.
#           ---               |---|

use 5.014;
use Imager;

my $xsize = 800;
my $ysize = 800;

my $img = Imager->new(xsize => $xsize, ysize => $ysize, channels => 3);
my $color = Imager::Color->new('#ff0000');

sub a {
    my ($x, $y, $len, $rep) = @_;

    $img->line(
               x1    => $x,
               x2    => $x,
               y1    => $y,
               y2    => $y + $len,
               color => $color,
              );

    f($x, $y, $len, $rep);
}

sub f {
    my ($x, $y, $len, $rep) = @_;

    $rep <= 0 and return;

    $img->line(
               x1    => $x - $len / 2,
               x2    => $x + $len / 2,
               y1    => $y,
               y2    => $y,
               color => $color,
              );

    g($x - $len / 2, $y, $len, $rep - 1);

    $img->line(
               x1    => $x - $len / 2,
               x2    => $x + $len / 2,
               y1    => $y + $len,
               y2    => $y + $len,
               color => $color,
              );

    g($x - $len / 2, $y + $len, $len, $rep - 1);
}

sub g {
    my ($x, $y, $len, $rep) = @_;

    $rep <= 0 and return;

    $img->line(
               x1    => $x,
               x2    => $x,
               y1    => $y - $len / 2,
               y2    => $y + $len / 2,
               color => $color,
              );

    f($x, $y - $len / 2, $len, $rep - 1);

    $img->line(
               x1    => $x + $len,
               x2    => $x + $len,
               y1    => $y - $len / 2,
               y2    => $y + $len / 2,
               color => $color,
              );

    f($x + $len, $y - $len / 2, $len, $rep - 1);
}

a($xsize / 2, $ysize / 2, sqrt($xsize + $ysize), 12);

$img->write(file => "recursive_squares.png");
