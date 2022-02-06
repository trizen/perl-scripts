#!/usr/bin/perl

# Author: Trizen
# Date: 06 February 2022
# https://github.com/trizen

# Hide arbitrary data into the pixels of a PNG image.

# Concept inspired by outguess:
#   https://github.com/resurrecting-open-source-projects/outguess
#   https://uncovering-cicada.fandom.com/wiki/OutGuess

# Q: How does it work?
# A: The script uses the GD library to read the index color of each pixel, which ranges from 0 to 2^24.
#    Then it changes the last bit of this value to one bit from the data to be encoded.

# Q: How does the decoding work?
# A: The first 32 bits from the first 32 pixels of the image, form the length of the encoded data.
#    Then the remaining bits (1 bit from each pixel) are collected to form the encoded data.

use 5.014;
use strict;
use warnings;

no warnings 'once';

use GD qw();
use Getopt::Long qw(GetOptions);
use experimental qw(signatures);

GD::Image->trueColor(1);

sub encode_data ($data, $img_file) {

    my $image = GD::Image->new($img_file)
      or die "Can't open image <<$img_file>>: $!";

    require IO::Compress::RawDeflate;
    IO::Compress::RawDeflate::rawdeflate(\$data, \my $compressed_data)
      or die "rawdeflate failed: $IO::Compress::RawDeflate::RawDeflateError\n";

    $data = $compressed_data;

    my $bin = unpack("B*", $data);
    my ($width, $height) = $image->getBounds();

    my $maximum_data_size = ($width * $height - 32) >> 3;
    my $data_size         = length($bin) >> 3;

    if ($data_size == 0) {
        die sprintf("No data was given!\n");
    }

    if ($data_size > $maximum_data_size) {
        die sprintf("Data is too large (%s bytes) for this image.\nMaximum data size for this image is %s bytes.\n",
                    $data_size, $maximum_data_size);
    }

    warn sprintf("Compressed data size: %s bytes (%.2f%% out of max %s bytes)\n",
                 $data_size, $data_size / $maximum_data_size * 100,
                 $maximum_data_size);

    my $length_bin = unpack("B*", pack("N*", length($bin)));

    $bin = reverse($length_bin . $bin);

    my $size = length($bin);

  OUTER: foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $index = $image->getPixel($x, $y);

            if (--$size >= 0) {
                $index = (($index >> 1) << 1) | chop($bin);
            }
            else {
                last OUTER;
            }

            $image->setPixel($x, $y, $index);
        }
    }

    return $image;
}

sub decode_data ($img_file) {

    my $image = GD::Image->new($img_file)
      or die "Can't open image <<$img_file>>: $!";

    my ($width, $height) = $image->getBounds();

    my $bin  = '';
    my $size = 0;

    my $length        = $width * $height;
    my $find_length   = 1;
    my $max_data_size = $length - 4;

  OUTER: foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $index = $image->getPixel($x, $y);

            if (++$size <= $length) {

                $bin .= $index & 1;

                if ($find_length and $size == 32) {

                    $length      = unpack("N*", pack("B*", $bin));
                    $find_length = 0;
                    $size        = 0;
                    $bin         = '';

                    if (($length >> 3) > $max_data_size or $length == 0) {
                        die "No hidden data was found in this image!\n";
                    }

                    warn sprintf("Compressed data size: %s bytes\n", $length >> 3);
                }
            }
            else {
                last OUTER;
            }
        }
    }

    my $data = pack("B*", $bin);

    require IO::Uncompress::RawInflate;
    IO::Uncompress::RawInflate::rawinflate(\$data, \my $uncompressed)
      or die "rawinflate failed: $IO::Uncompress::RawInflate::RawInflateError\n";

    warn sprintf("Uncompressed data size: %s bytes\n", length($uncompressed));

    return $uncompressed;
}

sub help ($exit_code = 0) {
    print <<"EOT";
usage: $0 [options] [input] [output]

options:

    -z [file] : encode a given data file

example:

    # Encode
    perl $0 -z=data.txt input.jpg encoded.png

    # Decode
    perl $0 encoded.png decoded-data.txt
EOT

    exit($exit_code);
}

my $data_file;

GetOptions("z|encode=s" => \$data_file,
           "h|help"     => sub { help(0) },)
  or die("Error in command line arguments\n");

if (defined($data_file)) {

    my $input_image  = shift(@ARGV) // help(2);
    my $output_image = shift(@ARGV);

    open my $fh, '<:raw', $data_file
      or die "Can't open file <<$data_file>> for reading: $!";

    my $data = do {
        local $/;
        <$fh>;
    };

    close $fh;

    my $img = encode_data($data, $input_image);

    if (defined($output_image)) {

        if ($output_image !~ /\.png\z/i) {
            die "The output image must have the '.png' extension!\n";
        }

        open my $fh, '>:raw', $output_image
          or die "Can't open file <<$output_image>> for writing: $!";
        print $fh $img->png(9);
        close $fh;
    }
    else {
        print $img->png(9);
    }
}
else {
    my $input_image = shift(@ARGV) // help(2);
    my $output_file = shift(@ARGV);

    my $data = decode_data($input_image);

    if (defined($output_file)) {
        open my $fh, '>:raw', $output_file
          or die "Can't open file <<$output_file>> for writing: $!";
        print $fh $data;
        close $fh;
    }
    else {
        print $data;
    }
}
