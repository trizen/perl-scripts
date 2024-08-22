#!/usr/bin/perl

# Author: Trizen
# Date: 13 January 2024
# Edit: 09 April 2024
# https://github.com/trizen

# Create a valid Gzip container, using DEFLATE's Block Type 2 with dynamic prefix codes only, without LZSS.

# Reference:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;
use File::Basename    qw(basename);
use Compression::Util qw(:all);
use List::Util        qw(uniq);

use constant {
              CHUNK_SIZE => (1 << 15) - 1,    # 2^15 - 1
             };

my $MAGIC  = pack('C*', 0x1f, 0x8b);    # magic MIME type
my $CM     = chr(0x08);                 # 0x08 = DEFLATE
my $FLAGS  = chr(0x00);                 # flags
my $MTIME  = pack('C*', (0x00) x 4);    # modification time
my $XFLAGS = chr(0x00);                 # extra flags
my $OS     = chr(0x03);                 # 0x03 = Unix

my $input  = $ARGV[0] // die "usage: $0 [input] [output.gz]\n";
my $output = $ARGV[1] // (basename($input) . '.gz');

open my $in_fh, '<:raw', $input
  or die "Can't open file <<$input>> for reading: $!";

open my $out_fh, '>:raw', $output
  or die "Can't open file <<$output>> for writing: $!";

print $out_fh $MAGIC, $CM, $FLAGS, $MTIME, $XFLAGS, $OS;

my $total_length = 0;
my $crc32        = 0;

my $bitstring  = '';
my $block_type = '01';                                                                 # 00 = store; 10 = LZSS + Fixed codes; 01 = LZSS + Dynamic codes
my @CL_order   = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

if (eof($in_fh)) {    # empty file
    $bitstring = '1' . '10' . '0000000';
}

while (read($in_fh, (my $chunk), CHUNK_SIZE)) {

    my $chunk_len    = length($chunk);
    my $is_last      = eof($in_fh) ? '1' : '0';
    my $block_header = join('', $is_last, $block_type);

    my @symbols = (unpack('C*', $chunk), 256);
    my ($dict, $rev_dict) = huffman_from_symbols(\@symbols);

    my @LL_code_lengths;
    foreach my $symbol (0 .. 285) {
        if (exists($dict->{$symbol})) {
            push @LL_code_lengths, length($dict->{$symbol});
        }
        else {
            push @LL_code_lengths, 0;
        }
    }

    while (scalar(@LL_code_lengths) > 1 and $LL_code_lengths[-1] == 0) {
        pop @LL_code_lengths;
    }

    my @distance_code_lengths;
    foreach my $symbol (0 .. 29) {
        push @distance_code_lengths, 0;
    }

    while (scalar(@distance_code_lengths) > 1 and $distance_code_lengths[-1] == 0) {
        pop @distance_code_lengths;
    }

    my @CL_code;
    foreach my $length (uniq(@LL_code_lengths, @distance_code_lengths)) {
        push @CL_code, $length;
    }

    my ($cl_dict) = huffman_from_symbols(\@CL_code);

    my @CL_code_lenghts;
    foreach my $symbol (0 .. 18) {
        if (exists($cl_dict->{$symbol})) {
            push @CL_code_lenghts, length($cl_dict->{$symbol});
        }
        else {
            push @CL_code_lenghts, 0;
        }
    }

    # Put the CL codes in the required order
    @CL_code_lenghts = @CL_code_lenghts[@CL_order];

    while (scalar(@CL_code_lenghts) > 4 and $CL_code_lenghts[-1] == 0) {
        pop @CL_code_lenghts;
    }

    my $CL_code_lengths_bitstring       = join('', map { int2bits_lsb($_, 3) } @CL_code_lenghts);
    my $LL_code_lengths_bitstring       = join('', map { $cl_dict->{$_} } @LL_code_lengths);
    my $distance_code_lengths_bitstring = join('', map { $cl_dict->{$_} } @distance_code_lengths);

    # (5 bits) HLIT = (number of LL code entries present) - 257
    my $HLIT = scalar(@LL_code_lengths) - 257;

    # (5 bits) HDIST = (number of distance code entries present) - 1
    my $HDIST = scalar(@distance_code_lengths) - 1;

    # (4 bits) HCLEN = (number of CL code entries present) - 4
    my $HCLEN = scalar(@CL_code_lenghts) - 4;

    $block_header .= int2bits_lsb($HLIT,  5);
    $block_header .= int2bits_lsb($HDIST, 5);
    $block_header .= int2bits_lsb($HCLEN, 4);

    $block_header .= $CL_code_lengths_bitstring;
    $block_header .= $LL_code_lengths_bitstring;
    $block_header .= $distance_code_lengths_bitstring;

    $bitstring .= $block_header;
    $bitstring .= huffman_encode(\@symbols, $dict);

    print $out_fh pack('b*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));

    $crc32 = crc32($chunk, $crc32);
    $total_length += $chunk_len;
}

if ($bitstring ne '') {
    print $out_fh pack('b*', $bitstring);
}

print $out_fh pack('b*', int2bits_lsb($crc32,        32));
print $out_fh pack('b*', int2bits_lsb($total_length, 32));

close $in_fh;
close $out_fh;
