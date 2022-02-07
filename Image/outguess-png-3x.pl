#!/usr/bin/perl

# Author: Trizen
# Date: 07 February 2022
# https://github.com/trizen

# Hide arbitrary data into the pixels of a PNG image, storing 3 bits in each pixel color.

# Concept inspired by outguess:
#   https://github.com/resurrecting-open-source-projects/outguess
#   https://uncovering-cicada.fandom.com/wiki/OutGuess

# Q: How does it work?
# A: The script uses the Imager library to read the RGB color values of each pixel.
#    Then it changes the last bit of each value to one bit from the data to be encoded.

# Q: How does the decoding work?
# A: The first 32 bits form the length of the encoded data.
#    Then the remaining bits (3 bits from each pixels) are collected to form the encoded data.

use 5.020;
use strict;
use warnings;

no warnings 'once';

use Imager;
use Getopt::Long qw(GetOptions);
use experimental qw(signatures);

binmode(STDIN,  ':raw');
binmode(STDOUT, ':raw');

sub encode_data ($data, $img_file) {

    my $image = Imager->new(file => $img_file)
      or die Imager->errstr();

    require IO::Compress::RawDeflate;
    IO::Compress::RawDeflate::rawdeflate(\$data, \my $compressed_data)
      or die "rawdeflate failed: $IO::Compress::RawDeflate::RawDeflateError\n";

    $data = $compressed_data;

    my $bin    = unpack("B*", $data);
    my $width  = $image->getwidth();
    my $height = $image->getheight();

    my $maximum_data_size = 3 * (($width * $height - 32) >> 3);
    my $data_size         = length($bin) >> 3;

    if ($data_size == 0) {
        die sprintf("No data was given!\n");
    }

    if ($data_size > $maximum_data_size) {
        die sprintf(
                    "Data is too large (%s bytes) for this image (exceeded by %.2f%%).\n"
                      . "Maximum data size for this image is %s bytes.\n",
                    $data_size, 100 - ($maximum_data_size / $data_size * 100),
                    $maximum_data_size
                   );
    }

    warn sprintf("Compressed data size: %s bytes (%.2f%% out of max %s bytes)\n",
                 $data_size, $data_size / $maximum_data_size * 100,
                 $maximum_data_size);

    my $length_bin = unpack("B*", pack("N*", $data_size));

    $bin = reverse($length_bin . $bin);

    my $size = length($bin);

  OUTER: foreach my $y (0 .. $height - 1) {
        my $x = 0;
        foreach my $color ($image->getscanline(x => 0, y => $y, width => $width)) {
            my ($red, $green, $blue, $alpha) = $color->rgba();

            if ($size > 0) {
                $color->set((map { (($_ >> 1) << 1) | (chop($bin) || 0) } ($red, $green, $blue)), $alpha);
                $size -= 3;
            }
            else {
                last OUTER;
            }

            $image->setpixel(x => $x++, y => $y, color => $color);
        }
    }

    return $image;
}

sub decode_data ($img_file) {

    my $image = Imager->new(file => $img_file)
      or die Imager->errstr();

    my $width  = $image->getwidth;
    my $height = $image->getheight;

    my $bin  = '';
    my $size = 0;

    my $length        = $width * $height;
    my $find_length   = 1;
    my $max_data_size = 3 * ($length - 4);

  OUTER: foreach my $y (0 .. $height - 1) {
        foreach my $color ($image->getscanline(x => 0, y => $y, width => $width)) {
            my ($red, $green, $blue) = $color->rgba();

            if ($size < $length) {

                $bin .= join('', map { $_ & 1 } ($red, $green, $blue));
                $size += 3;

                if ($find_length and $size >= 32) {

                    $length      = unpack("N*", pack("B*", substr($bin, 0, 32)));
                    $find_length = 0;
                    $size        = length($bin) - 32;
                    $bin         = substr($bin, 32);

                    if ($length > $max_data_size or $length == 0) {
                        die "No hidden data was found in this image!\n";
                    }

                    warn sprintf("Compressed data size: %s bytes\n", $length);
                    $length <<= 3;
                }
            }
            else {
                last OUTER;
            }
        }
    }

    my $data = pack("B*", substr($bin, 0, $length));

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

GetOptions("z|f|encode=s" => \$data_file,
           "h|help"       => sub { help(0) },)
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

        $img->write(file => $output_image)
          or die $img->errstr;
    }
    else {
        $img->write(fh => \*STDOUT, type => 'png')
          or die $img->errstr;
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
