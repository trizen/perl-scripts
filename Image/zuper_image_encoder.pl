#!/usr/bin/perl

# Author: Trizen
# Date: 26 November 2022
# https://github.com/trizen

# A very simple lossless image encoder, using Zstandard compression.

# Pretty good at compressing computer-generated images.

use 5.020;
use warnings;

use Imager;
use experimental       qw(signatures);
use IO::Compress::Zstd qw(zstd $ZstdError);

sub zuper_encoder ($img, $out_fh) {

    my $width      = $img->getwidth;
    my $height     = $img->getheight;
    my $channels   = $img->getchannels;
    my $colorspace = 0;

    say "[$width, $height, $channels, $colorspace]";

    my @header = unpack('C*', 'zprf');

    push @header, unpack('C4', pack('N', $width));
    push @header, unpack('C4', pack('N', $height));

    push @header, $channels;
    push @header, $colorspace;

    my $index    = 0;
    my @channels = map { "" } (1 .. $channels);

    foreach my $y (0 .. $height - 1) {

        my @line     = split(//, scalar $img->getscanline(y => $y));
        my $line_len = scalar(@line);

        for (my $i = 0 ; $i < $line_len ; $i += 4) {
            my @px = splice(@line, 0, 4);
            foreach my $j (0 .. $channels - 1) {
                $channels[$j] .= $px[$j];
            }
            ++$index;
        }
    }

    my @footer;
    push(@footer, (0x00) x 7);
    push(@footer, 0x01);

    my $all_channels = '';

    foreach my $channel (@channels) {
        $all_channels .= $channel;
    }

    zstd(\$all_channels, \my $z)
      or die "zstd failed: $ZstdError\n";

    my $before = length($all_channels);
    my $after  = length($z);

    say "Compression: $before -> $after (saved ", sprintf("%.2f%%", 100 - $after / $before * 100), ")";

    # Header
    print $out_fh pack('C*', @header);

    # Compressed data
    print $out_fh pack('N', $after);
    print $out_fh $z;

    # Footer
    print $out_fh pack('C*', @footer);
}

@ARGV || do {
    say STDERR "usage: $0 [input.png] [output.zpr]";
    exit(2);
};

my $in_file  = $ARGV[0];
my $out_file = $ARGV[1] // "$in_file.zpr";

my $img = 'Imager'->new(file => $in_file)
    or die "Can't read image: $in_file";

open(my $out_fh, '>:raw', $out_file)
  or die "Can't open file <<$out_file>> for writing: $!";

zuper_encoder($img, $out_fh);
