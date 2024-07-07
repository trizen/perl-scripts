#!/usr/bin/perl

# Author: Trizen
# Date: 09 May 2024
# Edit: 07 July 2024
# https://github.com/trizen

# A simple LZ4 decompressor.

# References:
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md

use 5.036;
use Compression::Util qw(:all);

my $file = $ARGV[0] // die "usage: $0 [file.lz4]\n";

open my $fh, '<:raw', $file
  or die "Can't open file <<$file>> for reading: $!";

my $buffer = '';
bits2int_lsb($fh, 32, \$buffer) == 0x184D2204 or die "Not an LZ4 file\n";

my $FLG = ord(getc($fh));
my $BD  = ord(getc($fh));

my $version    = $FLG & 0b11_00_00_00;
my $B_indep    = $FLG & 0b00_10_00_00;
my $B_checksum = $FLG & 0b00_01_00_00;
my $C_size     = $FLG & 0b00_00_10_00;
my $C_checksum = $FLG & 0b00_00_01_00;
my $DictID     = $FLG & 0b00_00_00_01;

my $Block_MaxSize = $BD & 0b0_111_0000;

if ($version != 0b01_00_00_00) {
    die "Error: Invalid version number";
}

if ($C_size) {
    my $content_size = bits2int_lsb($fh, 64, \$buffer);
    say STDERR "Content size: ", $content_size;
}

if ($DictID) {
    my $dict_id = bits2int_lsb($fh, 32, \$buffer);
    say STDERR "Dictionary ID: ", $dict_id;
}

my $header_checksum = ord(getc($fh));

my $decoded = '';

BLOCK_LOOP: while (!eof($fh)) {

    my $block_size = bits2int_lsb($fh, 32, \$buffer);

    if ($block_size == 0x00000000) {    # signifies an EndMark
        say STDERR "Block size == 0";
        last;
    }

    say STDERR "Block size: $block_size";

    if ($block_size >> 31) {
        say STDERR "Highest bit set: ", $block_size;
        $block_size &= ((1 << 31) - 1);
        say STDERR "Block size: ", $block_size;
        my $uncompressed = '';
        read($fh, $uncompressed, $block_size);
        $decoded .= $uncompressed;
    }
    else {

        my $compressed = '';
        read($fh, $compressed, $block_size);
        open my $block_fh, '<:raw', \$compressed;

        while (!eof($block_fh)) {
            my $len_byte = ord(getc($block_fh));

            my $literals_length = $len_byte >> 4;
            my $match_len       = $len_byte & 0b1111;

            say STDERR "Literal: ",   $literals_length;
            say STDERR "Match len: ", $match_len;

            if ($literals_length == 15) {
                while (1) {
                    my $byte_len = ord(getc($block_fh));
                    $literals_length += $byte_len;
                    last if $byte_len != 255;
                }
            }

            say STDERR "Total literals length: ", $literals_length;

            my $literals = '';

            if ($literals_length > 0) {
                read($block_fh, $literals, $literals_length);
            }

            if (eof($block_fh)) {    # end of block
                $decoded .= $literals;
                next BLOCK_LOOP;
            }

            my $offset = bits2int_lsb($block_fh, 16, \$buffer);

            if ($offset == 0) {
                die "Corrupted block";
            }

            if ($match_len == 15) {
                while (1) {
                    my $byte_len = ord(getc($block_fh));
                    $match_len += $byte_len;
                    last if $byte_len != 255;
                }
            }

            $decoded .= $literals;

            foreach my $i (1 .. $match_len + 4) {
                $decoded .= substr($decoded, length($decoded) - $offset, 1);
            }
        }
    }

    if ($B_checksum) {
        my $content_checksum = bits2int_lsb($fh, 32, \$buffer);
        say STDERR "Checksum: $content_checksum";
    }
}

if ($C_checksum) {
    my $content_checksum = bits2int_lsb($fh, 32, \$buffer);
    say STDERR "Checksum: $content_checksum";
}

local $| = 1;
print $decoded;
