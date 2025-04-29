#!/usr/bin/perl

# Author: Trizen
# Date: 29 April 2025
# https://github.com/trizen

# Extract the {R,G,B} channels of an image, as binary data.

use 5.036;
use GD           qw();
use Getopt::Long qw(GetOptions);

binmode(STDOUT, ':raw');

GD::Image->trueColor(1);

my $size  = 80;
my $red   = 0;
my $green = 0;
my $blue  = 0;

sub help($code = 0) {
    print <<"HELP";
usage: $0 [options] [files]

options:
    -w  --width=i : resize image to this width (default: $size)
    -R  --red     : extract only the RED channel (default: $red)
    -G  --green   : extract only the GREEN channel (default: $green)
    -B  --blue    : extract only the BLUE channel (default: $blue)

example:
    perl $0 --width 200 --red image.png > red_channel.bin
HELP
    exit($code);
}

GetOptions(
           'w|width=s' => \$size,
           'R|red!'    => \$red,
           'G|green!'  => \$green,
           'B|blue!'   => \$blue,
           'h|help'    => sub { help(0) },
          )
  or die "Error in command-line arguments!";

sub img_unpack($image) {

    my $img = GD::Image->new($image) // return;
    my ($width, $height) = $img->getBounds;

    if ($size != 0) {
        my $scale_width  = $size;
        my $scale_height = int($height / ($width / ($size / 2)));

        my $resized = GD::Image->new($scale_width, $scale_height);
        $resized->copyResampled($img, 0, 0, 0, 0, $scale_width, $scale_height, $width, $height);

        ($width, $height) = ($scale_width, $scale_height);
        $img = $resized;
    }

    my @values;

    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $index = $img->getPixel($x, $y);
            my ($R, $G, $B) = $img->rgb($index);

            if ($red) {
                push @values, $R;
            }
            if ($green) {
                push @values, $G;
            }
            if ($blue) {
                push @values, $B;
            }
        }
    }

    my $output_width = $width * ($red + $green + $blue);
    return unpack("(A$output_width)*", pack('C*', @values));
}

print for img_unpack($ARGV[0] // help(1));
