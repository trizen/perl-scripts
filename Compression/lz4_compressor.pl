#!/usr/bin/perl

# Author: Trizen
# Date: 23 August 2024
# https://github.com/trizen

# A simple LZ4 compressor. (WIP)

# References:
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md

# See also:
#   https://github.com/trizen/Compression-Util

use 5.036;
use Compression::Util qw(:all);

binmode(STDOUT, ':raw');

my $file = $ARGV[0] // die "usage: $0 [file.lz4]\n";

open my $fh, '<:raw', $file
  or die "Can't open file <<$file>> for reading: $!";

my $compressed = '';
$compressed .= int2bytes_lsb(0x184D2204, 4);    # LZ4 magic number

my $fd = '';                                    # frame description
$fd .= chr(0b01_10_00_00);                      # flags (FLG)
$fd .= chr(0b0_111_0000);                       # block description (BD)

$compressed .= $fd;

# Header Checksum
if (eval { require Digest::xxHash; 1 }) {
    $compressed .= chr((Digest::xxHash::xxhash32($fd, 0) >> 8) & 0xFF);
}
else {
    $compressed .= chr(115);
}

# Slurp the entire file
my $chunk = do {
    local $/;
    <$fh>;
};

my ($literals, $distances, $lengths) = do {
    local $Compression::Util::LZ_MIN_LEN       = 4;                # minimum match length
    local $Compression::Util::LZ_MAX_LEN       = ~0;               # maximum match length
    local $Compression::Util::LZ_MAX_DIST      = (1 << 16) - 1;    # maximum match distance
    local $Compression::Util::LZ_MAX_CHAIN_LEN = 48;               # higher value = better compression
    lzss_encode($chunk);
};

my $literals_end = $#{$literals};

my $block = '';

for (my $i = 0 ; $i <= $literals_end ; ++$i) {

    my @uncompressed;
    while ($i <= $literals_end and defined($literals->[$i])) {
        push @uncompressed, $literals->[$i];
        ++$i;
    }

    my $literals_string = pack('C*', @uncompressed);
    my $literals_length = scalar(@uncompressed);

    my $dist      = $distances->[$i] // 0;
    my $match_len = $lengths->[$i] ? ($lengths->[$i] - 4) : 0;

    my $len_byte = 0;

    $len_byte |= ($literals_length >= 15 ? 15 : $literals_length) << 4;
    $len_byte |= ($match_len >= 15       ? 15 : $match_len);

    $literals_length -= 15;
    $match_len       -= 15;

    $block .= chr($len_byte);

    while ($literals_length >= 0) {
        $block .= chr($literals_length >= 255 ? 255 : $literals_length);
        $literals_length -= 255;
    }

    $block .= $literals_string;

    if ($dist == 0) {
        last;
    }

    if ($dist >= 1 << 16) {
        die "Too large distance: $dist";
    }

    $block .= pack('b*', scalar reverse sprintf('%016b', $dist));

    while ($match_len >= 0) {
        $block .= chr($match_len >= 255 ? 255 : $match_len);
        $match_len -= 255;
    }
}

$compressed .= int2bytes_lsb(length($block), 4);
$compressed .= $block;
$compressed .= int2bytes_lsb(0x00000000, 4);       # EndMark

print $compressed;
