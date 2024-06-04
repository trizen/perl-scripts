#!/usr/bin/perl

# Author: Trizen
# Date: 04 June 2024
# https://github.com/trizen

# Mirror a given list of images (horizontal flip).

use 5.036;
use Imager       qw();
use File::Find   qw(find);
use Getopt::Long qw(GetOptions);

my $img_formats = '';

my @img_formats = qw(
  jpeg
  jpg
  png
);

sub usage ($code) {
    local $" = ",";
    print <<"EOT";
usage: $0 [options] [dirs | files]

options:
    -f  --formats=s,s   : specify more image formats (default: @img_formats)

example:
    perl $0 ~/Pictures
EOT

    exit($code);
}

GetOptions('f|formats=s' => \$img_formats,
           'help'        => sub { usage(0) },)
  or die("Error in command line arguments");

push @img_formats, map { quotemeta } split(/\s*,\s*/, $img_formats);

my $img_formats_re = do {
    local $" = '|';
    qr/\.(@img_formats)\z/i;
};

sub mirror_image ($image) {

    my $img = Imager->new(file => $image) or do {
        warn "Failed to load <<$image>>: ", Imager->errstr();
        return;
    };

    $img->flip(dir => "h");
    $img->write(file => $image);
}

@ARGV || usage(1);

find {
    no_chdir => 1,
    wanted   => sub {
        (/$img_formats_re/o && -f) || return;
        say "Mirroring: $_";
        mirror_image($_);
    }
} => @ARGV;
