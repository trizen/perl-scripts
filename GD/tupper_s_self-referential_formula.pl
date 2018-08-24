#!/usr/bin/perl

# Tupper's self-referential formula.

# Plot the inequality:
#   1/2 < floor(mod(floor(y/17)*2^(-17*floor(x)-mod(floor(y), 17)),2))

# See also:
#   https://www.youtube.com/watch?v=_s5RFgd59ao
#   https://en.wikipedia.org/wiki/Tupper's_self-referential_formula

use 5.010;
use strict;
use warnings;

use Imager;
use Math::AnyNum qw(PREC 2048 :overload floor mod);

my $red = Imager::Color->new('#ff0000');

my $img = Imager->new(xsize => 111,
                      ysize => 17);

my $k = Math::AnyNum->new('960939379918958884971672962127852754715004339660129306651505519271702802395266424689642842174350718121267153782770623355993237280874144307891325963941337723487857735749823926629715517173716995165232890538221612403238855866184013235585136048828693337902491454229288667081096184496091705183454067827731551705405381627380967602565625016981482083418783163849115590225610003652351370343874461848378737238198224849863465033159410054974700593138339226497249461751545728366702369745461014655997933798537483143786841806593422227898388722980000748404719');

foreach my $x (0 .. 110) {
    foreach my $y (0 .. 16) {
        if (1/2 < floor(mod(exp(log(floor(($y + $k) / 17)) + log(2) * (-17 * $x - mod($y + $k, 17))), 2))) {
            $img->setpixel(x => '110' - $x - '2', y => $y, color => $red);
        }
    }
}

$img->write(file => 'tupper_formula.png');
