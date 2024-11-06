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
              FORMAT     => 'zlib',
              CHUNK_SIZE => (1 << 15) - 1,
             };

local $Compression::Util::LZ_MIN_LEN       = 4;                # minimum match length in LZ parsing
local $Compression::Util::LZ_MAX_LEN       = 258;              # maximum match length in LZ parsing
local $Compression::Util::LZ_MAX_DIST      = (1 << 15) - 1;    # maximum allowed back-reference distance in LZ parsing
local $Compression::Util::LZ_MAX_CHAIN_LEN = 64;               # how many recent positions to remember in LZ parsing

local $Compression::Util::VERBOSE = 1;

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

sub my_zlib_compress ($in_fh, $out_fh) {

    my $CMF = (7 << 4) | 8;
    my $FLG = 2 << 6;

    while (($CMF * 256 + $FLG) % 31 != 0) {
        ++$FLG;
    }

    my $bitstring = '';
    my $adler32   = 1;

    print $out_fh chr($CMF);
    print $out_fh chr($FLG);

    while (read($in_fh, (my $chunk), CHUNK_SIZE)) {

        my ($literals, $distances, $lengths) = lzss_encode($chunk);

        $adler32 = adler32($chunk, $adler32);
        $bitstring .= eof($in_fh) ? '1' : '0';
        $bitstring .= deflate_create_block_type_2($literals, $distances, $lengths);

        print $out_fh pack('b*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));
    }

    if ($bitstring ne '') {
        print $out_fh pack('b*', $bitstring);
    }

    print $out_fh int2bytes($adler32, 4);
}

###################
# GZIP DECOMPRESSOR
###################

sub my_zlib_decompress ($in_fh, $out_fh) {

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

        my_zlib_decompress($in_fh, $out_fh)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;

        open my $in_fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";

        open my $out_fh, '>:raw', $output
          or die "Can't open file <<$output>> for writing: $!";

        my_zlib_compress($in_fh, $out_fh)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

main();
exit(0);
