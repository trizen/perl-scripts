#!/usr/bin/perl

# Author: Trizen
# Date: 05 April 2024
# https://github.com/trizen

# Apply the Burrows-Wheeler transform on each row of an image.

use 5.036;
use GD;
use Getopt::Std       qw(getopts);
use Compression::Util qw(bwt_encode_symbolic bwt_decode_symbolic);

GD::Image->trueColor(1);

sub apply_bwt ($file) {

    my $image = GD::Image->new($file) || die "Can't open file <<$file>>: $!";
    my ($width, $height) = $image->getBounds();

    my $new_image = GD::Image->new($width + 1, $height);

    foreach my $y (0 .. $height - 1) {

        my @row;
        foreach my $x (0 .. $width - 1) {
            push @row, scalar $new_image->colorAllocate($image->rgb($image->getPixel($x, $y)));
        }

        my ($encoded, $idx) = bwt_encode_symbolic(\@row);
        $new_image->setPixel(0, $y, $idx);

        foreach my $x (1 .. $width) {
            $new_image->setPixel($x, $y, $encoded->[$x - 1]);
        }
    }

    return $new_image;
}

sub undo_bwt ($file) {

    my $image = GD::Image->new($file) || die "Can't open file <<$file>>: $!";
    my ($width, $height) = $image->getBounds();

    my $new_image = GD::Image->new($width - 1, $height);

    foreach my $y (0 .. $height - 1) {

        my @row;
        my $idx = $image->getPixel(0, $y);

        foreach my $x (1 .. $width - 1) {
            push @row, scalar $image->getPixel($x, $y);
        }

        my $decoded = bwt_decode_symbolic(\@row, $idx);

        foreach my $x (0 .. $width - 2) {
            $new_image->setPixel($x, $y, $decoded->[$x]);
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

my $img = $opts{d} ? undo_bwt($input_file) : apply_bwt($input_file);
open(my $out_fh, '>:raw', $output_file) or die "can't create output file <<$output_file>>: $!";
print $out_fh $img->png(9);
close $out_fh;
