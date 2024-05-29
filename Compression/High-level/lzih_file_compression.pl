#!/usr/bin/perl

# Author: Trizen
# Date: 15 December 2022
# Edit: 13 June 2023
# https://github.com/trizen

# Compress/decompress files using LZ77 compression + fixed-width integers encoding + Huffman coding.

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'LZIH',
    VERSION => '0.04',
    FORMAT  => 'lzih',

    COMPRESSED_BYTE       => chr(1),
    UNCOMPRESSED_BYTE     => chr(0),
    CHUNK_SIZE            => 1 << 16,    # higher value = better compression
    RANDOM_DATA_THRESHOLD => 1,          # in ratio
};

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(4);

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

        my ($uncompressed, $lengths, $matches, $distances) = lz77_encode($chunk);

        my $est_ratio = length($chunk) / (4 * scalar(@$uncompressed));
        say(scalar(@$uncompressed), ' -> ', $est_ratio);

        if ($est_ratio > RANDOM_DATA_THRESHOLD) {
            print $out_fh COMPRESSED_BYTE;
            print $out_fh create_huffman_entry($uncompressed);
            print $out_fh create_huffman_entry($lengths);
            print $out_fh create_huffman_entry($matches);
            print $out_fh abc_encode($distances);
        }
        else {
            print $out_fh UNCOMPRESSED_BYTE;
            print $out_fh create_huffman_entry($chunk);
        }
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

        my $compression_byte = getc($fh) // die "decompression error";

        if ($compression_byte eq COMPRESSED_BYTE) {

            my $uncompressed = decode_huffman_entry($fh);
            my $lengths      = decode_huffman_entry($fh);
            my $matches      = decode_huffman_entry($fh);
            my $distances    = abc_decode($fh);

            print $out_fh lz77_decode($uncompressed, $lengths, $matches, $distances);
        }
        elsif ($compression_byte eq UNCOMPRESSED_BYTE) {
            print $out_fh pack('C*', @{decode_huffman_entry($fh)});
        }
        else {
            die "Invalid compression...";
        }
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
