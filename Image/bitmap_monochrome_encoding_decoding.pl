#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 August 2018
# https://github.com/trizen

# Encode an image into an integer in monochrome bitmap format.
# Decode an integer back into a monochrome image, by specifying XSIZE and YSIZE.

# Usage:
#   perl bitmap_monochrome_encoding_decoding.pl [image|integer] [xsize] [ysize]

# See also:
#   https://www.youtube.com/watch?v=_s5RFgd59ao
#   https://en.wikipedia.org/wiki/Tupper's_self-referential_formula

# For example, try:
#   perl bitmap_monochrome_encoding_decoding.pl 960939379918958884971672962127852754715004339660129306651505519271702802395266424689642842174350718121267153782770623355993237280874144307891325963941337723487857735749823926629715517173716995165232890538221612403238855866184013235585136048828693337902491454229288667081096184496091705183454067827731551705405381627380967602565625016981482083418783163849115590225610003652351370343874461848378737238198224849863465033159410054974700593138339226497249461751545728366702369745461014655997933798537483143786841806593422227898388722980000748404719
#   perl bitmap_monochrome_encoding_decoding.pl 4858487700955227269310810743279699920059071665868862676453015679577225782068321715691954329017884722389385550282344094325110559671706720456802995614421319713836803680439230203857023532236791776607932309358505788694249724093972434433440785815336774291945612106058206332142360075310011570794409292417648253014388444262569443218615514272957841814202800720702726236206242071675013681230087031878381452808096784548757607453284867359002454455428928632983954826623474612688372970630260114784068636783069647343475295488391045284413477645076796807315439

use 5.020;
use strict;
use warnings;

my $XSIZE = 106;
my $YSIZE = 17;

use Imager;
use Math::AnyNum;
use experimental qw(signatures);

sub bitmap_monochrome_encoding ($file) {

    my $img = Imager->new(file => $file)
      or die "Can't open file `$file`: $!";

    $XSIZE = $img->getwidth;
    $YSIZE = $img->getheight;

    say "XSIZE = $XSIZE";
    say "YSIZE = $YSIZE";

    my $bin = '';

    foreach my $x (0 .. $XSIZE - 1) {
        foreach my $y (0 .. $YSIZE - 1) {
            my ($R, $G, $B) = $img->getpixel(x => $x, y => $YSIZE - $y - 1)->rgba;

            if ($R + $G + $B >= 3 * 128) {
                $bin .= '1';
            }
            else {
                $bin .= '0';
            }
        }
    }

    Math::AnyNum->new($bin, 2) * $YSIZE;
}

sub bitmap_monochrome_decoding ($k) {

    my $red = Imager::Color->new('#FFFFFF');
    my $img = Imager->new(xsize => $XSIZE,
                          ysize => $YSIZE);

    my @bin = split(//, reverse(($k / $YSIZE)->floor->as_bin));

    for (my $y = 0 ; @bin ; ++$y) {
        my @row = splice(@bin, 0, $YSIZE);
        foreach my $i (0 .. $XSIZE - 1) {
            $img->setpixel(x => $XSIZE - $y - 1, y => $i, color => $red) if $row[$i];
        }
    }

    $img->write(file => 'monochrome_image.png');
}

@ARGV || die "usage: $0 [image|integer] [xsize] [ysize]\n";

$XSIZE = $ARGV[1] if defined($ARGV[1]);
$YSIZE = $ARGV[2] if defined($ARGV[2]);

my $k = 0;

if ($ARGV[0] =~ /^[0-9]+\z/) {
    say "[*] Decoding...";
    $k = Math::AnyNum->new($ARGV[0]);
}
else {
    say "[*] Encoding...";
    my $img_file = $ARGV[0];
    $k = bitmap_monochrome_encoding($img_file);
    say "k = $k";
}

bitmap_monochrome_decoding($k);

say "[*] Done!"
