#!/usr/bin/perl

# Author: Trizen
# Date: 06 April 2024
# Edit: 09 April 2024
# https://github.com/trizen

# Scramble the pixels in each column inside an image, using the Move-to-front transform (MTF).

use 5.036;
use GD;
use Getopt::Std       qw(getopts);
use Compression::Util qw(mtf_encode mtf_decode);

GD::Image->trueColor(1);

sub scramble_image ($file, $function) {

    my $image = GD::Image->new($file) || die "Can't open file <<$file>>: $!";
    my ($width, $height) = $image->getBounds();

    my $new_image = GD::Image->new($width, $height);
    my @alphabet  = (0 .. 255);

    foreach my $x (0 .. $width - 1) {

        my @column;
        foreach my $y (0 .. $height - 1) {
            push @column, $image->rgb($image->getPixel($x, $y));
        }

        @column = @{$function->(\@column, \@alphabet)};

        foreach my $y (0 .. $height - 1) {
            $new_image->setPixel($x, $y, $new_image->colorAllocate(splice(@column, 0, 3)));
        }
    }

    return $new_image;
}

sub usage ($exit_code = 0) {

    print <<"EOT";
usage: $0 [options] [input.png] [output.png]

options:

    -d : decode the image
    -h : print this message and exit

EOT

    exit($exit_code);
}

getopts('dh', \my %opts);

my $input_file  = $ARGV[0] // usage(2);
my $output_file = $ARGV[1] // "output.png";

if (not -f $input_file) {
    die "Input file <<$input_file>> does not exist!\n";
}

my $img = $opts{d} ? scramble_image($input_file, \&mtf_decode) : scramble_image($input_file, \&mtf_encode);
open(my $out_fh, '>:raw', $output_file) or die "can't create output file <<$output_file>>: $!";
print $out_fh $img->png(9);
close $out_fh;
