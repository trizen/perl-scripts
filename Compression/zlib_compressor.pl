#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 05 November 2024
# https://github.com/trizen

# Basic implementation of the ZLIB Compressed Data Format.

# Reference:
#   https://datatracker.ietf.org/doc/html/rfc1950

# Usage:
#   perl zlib_compressor.pl < input_file.txt | zlib-flate -uncompress

use 5.036;
use Compression::Util qw(:all);

local $Compression::Util::LZ_MIN_LEN  = 4;                # minimum match length in LZ parsing
local $Compression::Util::LZ_MAX_LEN  = 258;              # maximum match length in LZ parsing
local $Compression::Util::LZ_MAX_DIST = (1 << 15) - 1;    # maximum allowed back-reference distance in LZ parsing

binmode(STDIN,  ':raw');
binmode(STDOUT, ':raw');

my $CMF = (7 << 4) | 8;
my $FLG = 2 << 6;

while (($CMF * 256 + $FLG) % 31 != 0) {
    ++$FLG;
}

state $CHUNK_SIZE = (1 << 15) - 1;

my $in_fh  = \*STDIN;
my $out_fh = \*STDOUT;

my $bitstring = '';
my $adler32   = 1;

print $out_fh chr($CMF);
print $out_fh chr($FLG);

while (read($in_fh, (my $chunk), $CHUNK_SIZE)) {

    my ($literals, $distances, $lengths) = lzss_encode($chunk);

    $adler32 = adler32($chunk, $adler32);
    $bitstring .= eof($in_fh) ? '1' : '0';
    $bitstring .= Compression::Util::_create_block_type_2($literals, $distances, $lengths);

    print $out_fh pack('b*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));
}

if ($bitstring ne '') {
    print $out_fh pack('b*', $bitstring);
}

print int2bytes($adler32, 32);
