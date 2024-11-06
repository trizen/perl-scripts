#!/usr/bin/perl

# Author: Trizen
# Date: 05 May 2024
# Edit: 06 November 2024
# https://github.com/trizen

# A valid Gzip file compressor/decompressor, generating DEFLATE blocks of type 0, 1 or 2, whichever is smaller.

# Reference:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;
use File::Basename    qw(basename);
use Compression::Util qw(:all);
use List::Util        qw(all min max);
use Getopt::Std       qw(getopts);

use constant {
              FORMAT     => 'gz',
              CHUNK_SIZE => (1 << 15) - 1,
             };

local $Compression::Util::LZ_MIN_LEN       = 4;                # minimum match length in LZ parsing
local $Compression::Util::LZ_MAX_LEN       = 258;              # maximum match length in LZ parsing
local $Compression::Util::LZ_MAX_DIST      = (1 << 15) - 1;    # maximum allowed back-reference distance in LZ parsing
local $Compression::Util::LZ_MAX_CHAIN_LEN = 64;               # how many recent positions to remember in LZ parsing

local $Compression::Util::VERBOSE = 1;

my $MAGIC  = pack('C*', 0x1f, 0x8b);                           # magic MIME type
my $CM     = chr(0x08);                                        # 0x08 = DEFLATE
my $FLAGS  = chr(0x00);                                        # flags
my $MTIME  = pack('C*', (0x00) x 4);                           # modification time
my $XFLAGS = chr(0x00);                                        # extra flags
my $OS     = chr(0x03);                                        # 0x03 = Unix

my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables();

sub usage ($code = 0) {
    print <<"EOH";
usage: $0 [options] [input file] [output file]

options:
        -e            : extract
        -i <filename> : input filename
        -o <filename> : output filename
        -r            : rewrite output
        -h            : this message

examples:
         $0 document.txt
         $0 document.txt archive.${\FORMAT}
         $0 archive.${\FORMAT} document.txt
         $0 -e -i archive.${\FORMAT} -o document.txt

EOH

    exit($code // 0);
}

#################
# GZIP COMPRESSOR
#################

sub my_gzip_compress ($in_fh, $out_fh) {

    print $out_fh $MAGIC, $CM, $FLAGS, $MTIME, $XFLAGS, $OS;

    my $total_length = 0;
    my $crc32        = 0;

    my $bitstring = '';

    if (eof($in_fh)) {    # empty file
        $bitstring = '1' . '10' . '0000000';
    }

    while (read($in_fh, (my $chunk), CHUNK_SIZE)) {

        $crc32 = crc32($chunk, $crc32);
        $total_length += length($chunk);

        my ($literals, $distances, $lengths) = lzss_encode($chunk);

        $bitstring .= eof($in_fh) ? '1' : '0';

        my $bt1_bitstring = deflate_create_block_type_1($literals, $distances, $lengths);

        # When block type 1 is larger than the input, then we have random uncompressible data: use block type 0
        if ((length($bt1_bitstring) >> 3) > length($chunk) + 5) {

            say STDERR ":: Using block type: 0";

            $bitstring .= '00';

            print $out_fh pack('b*', $bitstring);                                   # pads to a byte
            print $out_fh pack('b*', deflate_create_block_type_0_header($chunk));
            print $out_fh $chunk;

            $bitstring = '';
            next;
        }

        my $bt2_bitstring = deflate_create_block_type_2($literals, $distances, $lengths);

        # When block type 2 is larger than block type 1, then we may have very small data
        if (length($bt2_bitstring) > length($bt1_bitstring)) {
            say STDERR ":: Using block type: 1";
            $bitstring .= $bt1_bitstring;
        }
        else {
            say STDERR ":: Using block type: 2";
            $bitstring .= $bt2_bitstring;
        }

        print $out_fh pack('b*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));
    }

    if ($bitstring ne '') {
        print $out_fh pack('b*', $bitstring);
    }

    print $out_fh pack('b*', int2bits_lsb($crc32,        32));
    print $out_fh pack('b*', int2bits_lsb($total_length, 32));

    return 1;
}

###################
# GZIP DECOMPRESSOR
###################

sub my_gzip_decompress ($in_fh, $out_fh) {

    my $MAGIC = (getc($in_fh) // die "error") . (getc($in_fh) // die "error");

    if ($MAGIC ne pack('C*', 0x1f, 0x8b)) {
        die "Not a valid Gzip container!\n";
    }

    my $CM     = getc($in_fh) // die "error";                             # 0x08 = DEFLATE
    my $FLAGS  = ord(getc($in_fh) // die "error");                        # flags
    my $MTIME  = join('', map { getc($in_fh) // die "error" } 1 .. 4);    # modification time
    my $XFLAGS = getc($in_fh) // die "error";                             # extra flags
    my $OS     = getc($in_fh) // die "error";                             # 0x03 = Unix

    if ($CM ne chr(0x08)) {
        die "Only DEFLATE compression method is supported (0x08)! Got: 0x", sprintf('%02x', ord($CM));
    }

    # Reference:
    #   https://web.archive.org/web/20240221024029/https://forensics.wiki/gzip/

    my $has_filename        = 0;
    my $has_comment         = 0;
    my $has_header_checksum = 0;
    my $has_extra_fields    = 0;

    if ($FLAGS & 0x08) {
        $has_filename = 1;
    }

    if ($FLAGS & 0x10) {
        $has_comment = 1;
    }

    if ($FLAGS & 0x02) {
        $has_header_checksum = 1;
    }

    if ($FLAGS & 0x04) {
        $has_extra_fields = 1;
    }

    if ($has_extra_fields) {
        my $size = bytes2int_lsb($in_fh, 2);
        read($in_fh, (my $extra_field_data), $size) // die "can't read extra field data: $!";
        say STDERR ":: Extra field data: $extra_field_data";
    }

    if ($has_filename) {
        my $filename = read_null_terminated($in_fh);    # filename
        say STDERR ":: Filename: $filename";
    }

    if ($has_comment) {
        my $comment = read_null_terminated($in_fh);     # comment
        say STDERR ":: Comment: $comment";
    }

    if ($has_header_checksum) {
        my $header_checksum = bytes2int_lsb($in_fh, 2);
        say STDERR ":: Header checksum: $header_checksum";
    }

    my $crc32         = 0;
    my $actual_length = 0;
    my $buffer        = '';
    my $search_window = '';

    while (1) {

        my $is_last = read_bit_lsb($in_fh, \$buffer);
        my $chunk   = deflate_extract_next_block($in_fh, \$buffer, \$search_window);

        print $out_fh $chunk;
        $crc32 = crc32($chunk, $crc32);
        $actual_length += length($chunk);

        last if $is_last;
    }

    $buffer = '';    # discard any padding bits

    my $stored_crc32 = bits2int_lsb($in_fh, 32, \$buffer);
    my $actual_crc32 = $crc32;

    say STDERR '';

    if ($stored_crc32 != $actual_crc32) {
        print STDERR "[!] The CRC32 does not match: $actual_crc32 (actual) != $stored_crc32 (stored)\n";
    }
    else {
        print STDERR ":: CRC32 value: $actual_crc32\n";
    }

    my $stored_length = bits2int_lsb($in_fh, 32, \$buffer);

    if ($stored_length != $actual_length) {
        print STDERR "[!] The length does not match: $actual_length (actual) != $stored_length (stored)\n";
    }
    else {
        print STDERR ":: Total length: $actual_length\n";
    }

    if (eof($in_fh)) {
        print STDERR "\n:: Reached the end of the file.\n";
    }
    else {
        print STDERR "\n:: There is something else in the container! Trying to recurse!\n\n";
        __SUB__->($in_fh, $out_fh);
    }
}

sub main {
    my %opt;
    getopts('ei:o:vhr', \%opt);

    $opt{h} && usage(0);
    $opt{v} && version();

    my ($input, $output) = @ARGV;
    $input  //= $opt{i} // usage(2);
    $output //= $opt{o};

    my $ext = qr{\.${\FORMAT}\z}io;
    if ($opt{e} || $input =~ $ext) {

        if (not defined $output) {
            ($output = basename($input)) =~ s{$ext}{}
              || die "$0: no output file specified!\n";
        }

        if (not $opt{r} and -e $output) {
            print "'$output' already exists! -- Replace? [y/N] ";
            <STDIN> =~ /^y/i || exit 17;
        }

        open my $in_fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";

        open my $out_fh, '>:raw', $output
          or die "Can't open file <<$output>> for writing: $!";

        my_gzip_decompress($in_fh, $out_fh)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;

        open my $in_fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";

        open my $out_fh, '>:raw', $output
          or die "Can't open file <<$output>> for writing: $!";

        my_gzip_compress($in_fh, $out_fh)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

main();
exit(0);
