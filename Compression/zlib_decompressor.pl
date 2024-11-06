#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 06 November 2024
# https://github.com/trizen

# Basic decompressor for the ZLIB Compressed Data Format.

# Reference:
#   https://datatracker.ietf.org/doc/html/rfc1950

# Usage:
#   zlib-flate -compress=9 < /usr/bin/fdf | perl zlib_decompressor.pl

use 5.036;
use Compression::Util qw(:all);

local $Compression::Util::LZ_MIN_LEN  = 4;                # minimum match length in LZ parsing
local $Compression::Util::LZ_MAX_LEN  = 258;              # maximum match length in LZ parsing
local $Compression::Util::LZ_MAX_DIST = (1 << 15) - 1;    # maximum allowed back-reference distance in LZ parsing

local $Compression::Util::VERBOSE = 1;

binmode(STDIN,  ':raw');
binmode(STDOUT, ':raw');

sub zlib_decompress ($in_fh, $out_fh) {

    my $adler32 = 1;

    my $CMF = ord(getc($in_fh));
    my $FLG = ord(getc($in_fh));

    if (($CMF * 256 + $FLG) % 31 != 0) {
        die "Invalid header checksum!\n";
    }

    my $CINFO = $CMF >> 4;

    if ($CINFO > 7) {
        die "Values of CINFO above 7 are not supported!\n";
    }

    my $method = $CMF & 0b1111;

    if ($method != 8) {
        die "Only method 8 (DEFLATE) is supported!\n";
    }

    my $buffer        = '';
    my $search_window = '';

    while (1) {

        my $is_last = read_bit_lsb($in_fh, \$buffer);
        my $chunk   = deflate_extract_next_block($in_fh, \$buffer, \$search_window);

        print $out_fh $chunk;
        $adler32 = adler32($chunk, $adler32);

        last if $is_last;
    }

    my $stored_adler32 = bytes2int($in_fh, 4);

    if ($adler32 != $stored_adler32) {
        die "Adler32 checksum does not match: $adler32 (actual) != $stored_adler32 (stored)\n";
    }

    if (eof($in_fh)) {
        print STDERR "\n:: Reached the end of the file.\n";
    }
    else {
        print STDERR "\n:: There is something else in the container! Trying to recurse!\n\n";
        __SUB__->($in_fh, $out_fh);
    }
}

zlib_decompress(\*STDIN, \*STDOUT);
