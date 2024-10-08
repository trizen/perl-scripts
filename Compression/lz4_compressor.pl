#!/usr/bin/perl

# Author: Trizen
# Date: 23 August 2024
# https://github.com/trizen

# A simple LZ4 compressor.

# References:
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md

# See also:
#   https://github.com/trizen/Compression-Util

use 5.036;
use Compression::Util qw(:all);

use constant {CHUNK_SIZE => 1 << 17};

local $| = 1;

binmode(STDIN,  ":raw");
binmode(STDOUT, ":raw");

my $s = "abcabcabc\n";

my $fh;
if (-t STDIN) {
    open $fh, "<:raw", \$s;
}
else {
    $fh = \*STDIN;
}

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

while (!eof($fh)) {

    read($fh, (my $chunk), CHUNK_SIZE);

    my ($literals, $distances, $lengths) = do {
        local $Compression::Util::LZ_MIN_LEN       = 4;                # minimum match length
        local $Compression::Util::LZ_MAX_LEN       = ~0;               # maximum match length
        local $Compression::Util::LZ_MAX_DIST      = (1 << 16) - 1;    # maximum match distance
        local $Compression::Util::LZ_MAX_CHAIN_LEN = 32;               # higher value = better compression
        lzss_encode(substr($chunk, 0, -5));
    };

    # The last 5 bytes of each block must be literals
    # https://github.com/lz4/lz4/issues/1495
    push @$literals, unpack('C*', substr($chunk, -5));

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

        my $match_len = $lengths->[$i] ? ($lengths->[$i] - 4) : 0;

        my $len_byte = 0;

        $len_byte |= ($literals_length >= 15 ? 15 : $literals_length) << 4;
        $len_byte |= ($match_len >= 15       ? 15 : $match_len);

        $literals_length -= 15;
        $match_len       -= 15;

        $block .= chr($len_byte);

        while ($literals_length >= 0) {
            $block .= ($literals_length >= 255 ? "\xff" : chr($literals_length));
            $literals_length -= 255;
        }

        $block .= $literals_string;

        my $dist = $distances->[$i] // last;
        $block .= pack('b*', scalar reverse sprintf('%016b', $dist));

        while ($match_len >= 0) {
            $block .= ($match_len >= 255 ? "\xff" : chr($match_len));
            $match_len -= 255;
        }
    }

    if ($block ne '') {
        $compressed .= int2bytes_lsb(length($block), 4);
        $compressed .= $block;
    }

    print $compressed;
    $compressed = '';
}

print int2bytes_lsb(0x00000000, 4);    # EndMark
