#!/usr/bin/perl

# Author: Trizen
# Date: 21 December 2023
# https://github.com/trizen

# Apply the reversible PNG transform on arbitrary data.

# The transformation can be made irreversible by lossy
# compressing the PNG file with a tool like "pngquant".

use 5.020;
use strict;
use warnings;

use GD           qw();
use Getopt::Long qw(GetOptions);
use experimental qw(signatures);

GD::Image->trueColor(1);

binmode(STDIN,  ':raw');
binmode(STDOUT, ':raw');

sub encode_data ($data) {

    my @bytes = unpack("C*", $data);

    my $c      = 1 + int(scalar(@bytes) / 3);
    my $width  = int(sqrt($c));
    my $height = int($c / $width) + 1;

    say STDERR ":: File size: ", scalar(@bytes);
    say STDERR ":: Image size: $width x $height";

    my $image = GD::Image->new($width, $height)
      or die "Can't create image";

    my $size = scalar(@bytes);

  OUTER: foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            if ($size > 0) {
                my $index = $image->colorResolve(shift(@bytes) // 0, shift(@bytes) // 0, shift(@bytes) // 0);
                $image->setPixel($x, $y, $index);
                $size -= 3;
            }
            else {
                last OUTER;
            }
        }
    }

    return $image;
}

sub decode_data ($img_data, $length) {

    my $image = GD::Image->new($img_data)
      or die "Can't read image: $!";

    my ($width, $height) = $image->getBounds();

    my $data = '';
    my $size = 0;

  OUTER: foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $index = $image->getPixel($x, $y);
            if ($size < $length) {
                my ($red, $green, $blue) = $image->rgb($index);
                $data .= pack('C3', $red, $green, $blue);
                $size += 3;
            }
            else {
                last OUTER;
            }
        }
    }

    while (length($data) > $length) {
        chop $data;
    }

    return $data;
}

my $compression = 9;
my $decode_size = undef;

sub help ($exit_code = 0) {
    print <<"EOT";
usage: $0 [options] [input] [output]

options:

    -d --decode=size : how many bytes to decode

example:

    # Encode
    perl $0 input.txt encoded.png

    # Decode
    perl $0 -d=size encoded.png decoded.txt

EOT

    exit($exit_code);
}

GetOptions('d|decode=s' => \$decode_size,
           "h|help"     => sub { help(0) },)
  or die("Error in command line arguments\n");

my $data_file   = shift(@ARGV) // help(2);
my $output_file = shift(@ARGV);

my $data = do {
    open my $fh, '<:raw', $data_file
      or die "Can't open file <<$data_file>> for reading: $!";
    local $/;
    <$fh>;
};

if (defined($decode_size)) {

    my $decoded = decode_data($data, $decode_size);

    if (length($decoded) != $decode_size) {
        warn sprintf("Incorrect size: len(T) = %d != len(D) = %d\n", length($decoded), length($data));
    }

    if (defined($output_file)) {
        open my $fh, '>:raw', $output_file
          or die "Can't open file <<$output_file>> for writing: $!";
        print $fh $decoded;
        close $fh;
    }
    else {
        print $decoded;
    }
}
else {

    my $img = encode_data($data);
    my $png = $img->png($compression);

    if (defined($output_file)) {
        open my $fh, '>:raw', $output_file
          or die "Can't open file <<$output_file>> for writing: $!";
        print $fh $png;
        close $fh;
    }
    else {
        print $png;
    }
}
