#!/usr/bin/perl

# Author: Trizen
# Date: 05 April 2024
# https://github.com/trizen

# Scramble the pixels in each column inside an image, using a deterministic method.

use 5.036;
use GD;
use Getopt::Std qw(getopts);

GD::Image->trueColor(1);

sub scramble ($str) {
    my $i = length($str);
    $str =~ s/(.{$i})(.)/$2$1/gs while (--$i > 0);
    return $str;
}

sub unscramble ($str) {
    my $i = 0;
    my $l = length($str);
    $str =~ s/(.)(.{$i})/$2$1/gs while (++$i < $l);
    return $str;
}

sub scramble_image ($file, $function) {

    my $image = GD::Image->new($file) || die "Can't open file <<$file>>: $!";
    my ($width, $height) = $image->getBounds();

    my $new_image = GD::Image->new($width, $height);

    foreach my $x (0 .. $width - 1) {

        my (@R, @G, @B);
        foreach my $y (0 .. $height - 1) {
            my ($R, $G, $B) = $image->rgb($image->getPixel($x, $y));
            push @R, $R;
            push @G, $G;
            push @B, $B;
        }

        @R = unpack('C*', $function->(pack('C*', @R)));
        @G = unpack('C*', $function->(pack('C*', @G)));
        @B = unpack('C*', $function->(pack('C*', @B)));

        foreach my $y (0 .. $height - 1) {
            $new_image->setPixel($x, $y, $new_image->colorAllocate($R[$y], $G[$y], $B[$y]));
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

my $img = $opts{d} ? scramble_image($input_file, \&unscramble) : scramble_image($input_file, \&scramble);
open(my $out_fh, '>:raw', $output_file) or die "can't create output file <<$output_file>>: $!";
print $out_fh $img->png(9);
close $out_fh;
