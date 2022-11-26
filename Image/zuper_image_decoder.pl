#!/usr/bin/perl

# Author: Trizen
# Date: 26 November 2022
# https://github.com/trizen

# A decoder for the Zuper (ZPR) image format, generating PNG images.

use 5.020;
use warnings;

use Imager;
use experimental           qw(signatures);
use IO::Uncompress::UnZstd qw(unzstd $UnZstdError);

sub zpr_decoder ($bytes) {

    my sub decode32 ($a, $b, $c, $d) {
        ($a << 8 * 3) | ($b << 8 * 2) | ($c << 8 * 1) | ($d << 8 * 0);
    }

    my sub invalid() {
        die "Not a ZPR image";
    }

    my $index = 0;
    pack('C4', @{$bytes}[$index .. $index + 3]) eq 'zprf' or invalid();
    $index += 4;

    my $width = decode32(@{$bytes}[$index .. $index + 3]);
    $index += 4;
    my $height = decode32(@{$bytes}[$index .. $index + 3]);
    $index += 4;

    my $channels   = $bytes->[$index++];
    my $colorspace = $bytes->[$index++];

    ($width > 0 and $height > 0) or invalid();
    ($channels == 3   or $channels == 4)   or invalid();
    ($colorspace == 0 or $colorspace == 1) or invalid();

    pop(@$bytes) == 0x01 or invalid();

    for (1 .. 7) {
        pop(@$bytes) == 0x00 or invalid();
    }

    say "[$width, $height, $channels, $colorspace]";

    my $len = decode32(@{$bytes}[$index .. $index + 3]);
    $index += 4;

    scalar(@$bytes) - $index == $len or invalid();

    splice(@$bytes, 0, $index);
    my $z = pack('C' . $len, @$bytes);

    unzstd(\$z, \my $all_channels)
      or die "unzstd failed: $UnZstdError\n";

    my $img = 'Imager'->new(
                            xsize    => $width,
                            ysize    => $height,
                            channels => $channels,
                           );

    my @channels = unpack(sprintf("(a%d)%d", $width * $height, $channels), $all_channels);

    foreach my $y (0 .. $height - 1) {
        my $row = '';
        foreach my $x (1 .. $width) {
            $row .= substr($_, 0, 1, '') for @channels;
            $row .= chr(0) if ($channels == 3);
        }
        $img->setscanline(y => $y, pixels => $row);
    }

    return $img;
}

@ARGV || do {
    say STDERR "usage: $0 [input.zpr] [output.png]";
    exit(2);
};

my $in_file  = $ARGV[0];
my $out_file = $ARGV[1] // "$in_file.png";

my @bytes = do {
    open(my $fh, '<:raw', $in_file)
      or die "Can't open file <<$in_file>> for reading: $!";
    local $/;
    unpack("C*", scalar <$fh>);
};

my $img = zpr_decoder(\@bytes);
$img->write(file => $out_file, type => 'png');
