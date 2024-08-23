#!/usr/bin/perl

# Author: Trizen
# Date: 09 May 2024
# Edit: 08 July 2024
# https://github.com/trizen

# A simple LZ4 decompressor.

# References:
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md

use 5.036;

local $| = 1;

binmode(STDIN,  ":raw");
binmode(STDOUT, ":raw");

sub bytes2int_lsb ($fh, $n) {
    my $bytes = '';
    $bytes .= getc($fh) for (1 .. $n);
    oct('0b' . reverse unpack('b*', $bytes));
}

my $s = '';

$s .= "\4\"M\30d@\xA7\16\0\0\x80Hello, World!\n\0\0\0\0\xE8C\xD0\x9E";            # uncompressed
$s .= "\4\"M\30d@\xA7\27\0\0\0\xE5Hello, World! \16\0Prld!\n\0\0\0\0\x9FL\"T";    # compressed

my $fh;
if (-t STDIN) {
    open $fh, "<:raw", \$s;
}
else {
    $fh = \*STDIN;
}

while (!eof($fh)) {

    bytes2int_lsb($fh, 4) == 0x184D2204 or die "Not an LZ4 file\n";

    my $FLG = ord(getc($fh));
    my $BD  = ord(getc($fh));

    my $version    = $FLG & 0b11_00_00_00;
    my $B_indep    = $FLG & 0b00_10_00_00;
    my $B_checksum = $FLG & 0b00_01_00_00;
    my $C_size     = $FLG & 0b00_00_10_00;
    my $C_checksum = $FLG & 0b00_00_01_00;
    my $DictID     = $FLG & 0b00_00_00_01;

    my $Block_MaxSize = $BD & 0b0_111_0000;

    say STDERR "Maximum block size: $Block_MaxSize";

    if ($version != 0b01_00_00_00) {
        die "Error: Invalid version number";
    }

    if ($C_size) {
        my $content_size = bytes2int_lsb($fh, 8);
        say STDERR "Content size: ", $content_size;
    }

    if ($DictID) {
        my $dict_id = bytes2int_lsb($fh, 4);
        say STDERR "Dictionary ID: ", $dict_id;
    }

    my $header_checksum = ord(getc($fh));

    my $decoded = '';

    while (!eof($fh)) {

        my $block_size = bytes2int_lsb($fh, 4);

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

            while ($compressed ne '') {
                my $len_byte = ord(substr($compressed, 0, 1, ''));

                my $literals_length = $len_byte >> 4;
                my $match_len       = $len_byte & 0b1111;

                #say STDERR "Literal: ",   $literals_length;
                #say STDERR "Match len: ", $match_len;

                if ($literals_length == 15) {
                    while (1) {
                        my $byte_len = ord(substr($compressed, 0, 1, ''));
                        $literals_length += $byte_len;
                        last if $byte_len != 255;
                    }
                }

                #say STDERR "Total literals length: ", $literals_length;

                my $literals = '';

                if ($literals_length > 0) {
                    $literals = substr($compressed, 0, $literals_length, '');
                }

                if ($compressed eq '') {    # end of block
                    $decoded .= $literals;
                    last;
                }

                my $offset = oct('0b' . reverse unpack('b16', substr($compressed, 0, 2, '')));

                if ($offset == 0) {
                    die "Corrupted block";
                }

                if ($match_len == 15) {
                    while (1) {
                        my $byte_len = ord(substr($compressed, 0, 1, ''));
                        $match_len += $byte_len;
                        last if $byte_len != 255;
                    }
                }

                $decoded .= $literals;
                $match_len += 4;

                if ($offset >= $match_len) {    # non-overlapping matches
                    $decoded .= substr($decoded, length($decoded) - $offset, $match_len);
                }
                elsif ($offset == 1) {
                    $decoded .= substr($decoded, -1) x $match_len;
                }
                else {                          # overlapping matches
                    foreach my $i (1 .. $match_len) {
                        $decoded .= substr($decoded, length($decoded) - $offset, 1);
                    }
                }
            }
        }

        if ($B_checksum) {
            my $content_checksum = bytes2int_lsb($fh, 4);
            say STDERR "Block checksum: $content_checksum";
        }

        if ($B_indep) {    # blocks are independent of each other
            print $decoded;
            $decoded = '';
        }
        elsif (length($decoded) > 2**16) {    # blocks are dependent
            print substr($decoded, 0, -(2**16), '');
        }
    }

    if ($C_checksum) {
        my $content_checksum = bytes2int_lsb($fh, 4);
        say STDERR "Content checksum: $content_checksum";
    }

    print $decoded;
}
