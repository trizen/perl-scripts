#!/usr/bin/perl

# Author: Trizen
# Date: 13 January 2024
# https://github.com/trizen

# Create a valid Gzip container, with uncompressed data.

# Reference:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;
use Digest::CRC    qw();
use File::Basename qw(basename);

use constant {
              CHUNK_SIZE => 0xffff,    # 2^16 - 1
             };

my $MAGIC  = pack('C*', 0x1f, 0x8b);    # magic MIME type
my $CM     = chr(0x08);                 # 0x08 = DEFLATE
my $FLAGS  = chr(0x00);                 # flags
my $MTIME  = pack('C*', (0x00) x 4);    # modification time
my $XFLAGS = chr(0x00);                 # extra flags
my $OS     = chr(0x03);                 # 0x03 = Unix

my $input  = $ARGV[0] // die "usage: $0 [input] [output.gz]\n";
my $output = $ARGV[1] // (basename($input) . '.gz');

sub int2bits ($value, $size = 32) {
    scalar reverse sprintf("%0*b", $size, $value);
}

open my $in_fh, '<:raw', $input
  or die "Can't open file <<$input>> for reading: $!";

open my $out_fh, '>:raw', $output
  or die "Can't open file <<$output>> for writing: $!";

print $out_fh $MAGIC, $CM, $FLAGS, $MTIME, $XFLAGS, $OS;

my $total_length = 0;
my $crc32        = Digest::CRC->new(type => "crc32");

while (read($in_fh, (my $chunk), CHUNK_SIZE)) {

    my $chunk_len = length($chunk);
    my $len       = int2bits($chunk_len, 16);
    my $nlen      = $len =~ s{(.)}{$1 ^ 1}ger;

    my $is_last      = eof($in_fh) ? 1 : 0;
    my $block_type   = '00';                                                            # 0 = store; 1 = LZSS + Fixed codes; 2 = LZSS + Dynamic codes
    my $block_header = pack('b*', $is_last . $block_type . ('0' x 5) . $len . $nlen);

    print $out_fh $block_header;
    print $out_fh $chunk;

    $crc32->add($chunk);
    $total_length += $chunk_len;
}

print $out_fh pack('b*', int2bits($crc32->digest, 32));
print $out_fh pack('b*', int2bits($total_length,  32));

close $in_fh;
close $out_fh;
