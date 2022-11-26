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

sub zuper_encoder ($img) {

    my $width      = $img->getwidth;
    my $height     = $img->getheight;
    my $channels   = $img->getchannels;
    my $colorspace = 0;

    say "[$width, $height, $channels, $colorspace]";

    my $compressed = 'zprf';

    $compressed .= pack('N', $width);
    $compressed .= pack('N', $height);

    $compressed .= chr($channels);
    $compressed .= chr($colorspace);

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

    my $all_channels = '';

    foreach my $channel (@channels) {
        $all_channels .= $channel;
    }

    zstd(\$all_channels, \my $z)
      or die "zstd failed: $ZstdError\n";

    my $before = length($all_channels);
    my $after  = length($z);

    say "Compression: $before -> $after (saved ", sprintf("%.2f%%", 100 - $after / $before * 100), ")";

    $compressed .= pack('N', $after);
    $compressed .= $z;

    for (1 .. 7) {
        $compressed .= chr(0x00);
    }

    $compressed .= chr(0x01);

    return \$compressed;
}

@ARGV || do {
    say STDERR "usage: $0 [input.png] [output.zpr]";
    exit(2);
};

my $in_file  = $ARGV[0];
my $out_file = $ARGV[1] // "$in_file.zpr";

my $img = 'Imager'->new(file => $in_file);

my $ref = zuper_encoder($img);

open(my $fh, '>:raw', $out_file)
  or die "Can't open file <<$out_file>> for writing: $!";

print $fh $$ref;
close $fh;
