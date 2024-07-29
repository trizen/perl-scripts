#!/usr/bin/perl

# Author: Trizen
# Date: 17 June 2023
# Edit: 25 July 2024
# https://github.com/trizen

# Compress/decompress files using LZ77 compression (LZ4-like) on bits + Huffman coding.

# Good at compressing data where there are patterns on bits, but not at byte boundaries (e.g.: variable-bit encoded data).

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'BLZSS',
    VERSION => '0.01',
    FORMAT  => 'blzss',

    CHUNK_SIZE => 1 << 18,    # higher value = better compression
};

local $Compression::Util::LZ_MIN_LEN       = 8 * 5;      # minimum match length
local $Compression::Util::LZ_MAX_LEN       = 1 << 15;    # maximum match length
local $Compression::Util::LZ_MAX_CHAIN_LEN = 64;         # higher value = better compression

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(1);

sub usage {
    my ($code) = @_;
    print <<"EOH";
usage: $0 [options] [input file] [output file]

options:
        -e            : extract
        -i <filename> : input filename
        -o <filename> : output filename
        -r            : rewrite output

        -v            : version number
        -h            : this message

examples:
         $0 document.txt
         $0 document.txt archive.${\FORMAT}
         $0 archive.${\FORMAT} document.txt
         $0 -e -i archive.${\FORMAT} -o document.txt

EOH

    exit($code // 0);
}

sub version {
    printf("%s %s\n", PKGNAME, VERSION);
    exit;
}

sub valid_archive {
    my ($fh) = @_;

    if (read($fh, (my $sig), length(SIGNATURE), 0) == length(SIGNATURE)) {
        $sig eq SIGNATURE || return;
    }

    return 1;
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

        decompress_file($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        compress_file($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

# Compress file
sub compress_file ($input, $output) {

    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    my $header = SIGNATURE;

    # Open the output file for writing
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for write: $!";

    # Print the header
    print $out_fh $header;

    # Compress data
    while (read($fh, (my $chunk), CHUNK_SIZE)) {
        my $bits = unpack('B*', $chunk);
        my ($uncompressed, $lengths, $matches, $distances) = lz77_encode($bits);
        my $ubits = pack('C*', @$uncompressed);
        my $rem   = length($ubits) % 8;
        my $str   = pack('B*', $ubits);
        print $out_fh chr($rem);
        print $out_fh create_huffman_entry(string2symbols $str);
        print $out_fh create_huffman_entry($lengths);
        print $out_fh create_huffman_entry($matches);
        print $out_fh obh_encode($distances, \&mrl_compress_symbolic);
    }

    # Close the file
    close $out_fh;
}

# Decompress file
sub decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for writing: $!";

    while (!eof($fh)) {
        my $rem   = ord getc $fh;
        my $str   = symbols2string decode_huffman_entry($fh);
        my $ubits = unpack('B*', $str);
        if ($rem != 0) {
            $ubits = substr($ubits, 0, -(8 - $rem));
        }
        my $uncompressed = [unpack('C*', $ubits)];
        my $lengths      = decode_huffman_entry($fh);
        my $matches      = decode_huffman_entry($fh);
        my $distances    = obh_decode($fh, \&mrl_decompress_symbolic);
        my $bits         = lz77_decode($uncompressed, $lengths, $matches, $distances);
        print $out_fh pack('B*', $bits);
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
