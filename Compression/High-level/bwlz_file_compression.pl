#!/usr/bin/perl

# Author: Trizen
# Date: 15 June 2023
# Edit: 21 March 2024
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + Move-to-front transform (MTF) + LZ77 compression (LZSS) + Huffman coding.

# References:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ
#
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use List::Util        qw(max uniq);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'BWLZ',
    VERSION => '0.05',
    FORMAT  => 'bwlz',

    CHUNK_SIZE => 1 << 17,    # higher value = better compression
};

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(5);

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

sub compression ($chunk, $out_fh) {

    my @chunk_bytes = unpack('C*', $chunk);
    my $data        = pack('C*', @{rle4_encode(\@chunk_bytes, 254)});

    my ($bwt, $idx) = bwt_encode($data);

    my @bytes    = unpack('C*', $bwt);
    my @alphabet = sort { $a <=> $b } uniq(@bytes);

    my $enc_bytes = mtf_encode(\@bytes, \@alphabet);

    if (max(@$enc_bytes) < 255) {
        print $out_fh chr(1);
        $enc_bytes = zrle_encode($enc_bytes);
    }
    else {
        print $out_fh chr(0);
        $enc_bytes = rle4_encode($enc_bytes);
    }

    print $out_fh pack('N', $idx);
    print $out_fh encode_alphabet(\@alphabet);
    print $out_fh lzss_compress(pack('C*', @$enc_bytes));
}

sub decompression ($fh, $out_fh) {

    my $rle_encoded = ord(getc($fh) // die "error");
    my $idx         = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));
    my $alphabet    = decode_alphabet($fh);

    my $dec   = lzss_decompress($fh);
    my $bytes = [unpack('C*', $dec)];

    if ($rle_encoded) {
        $bytes = zrle_decode($bytes);
    }
    else {
        $bytes = rle4_decode($bytes);
    }

    $bytes = mtf_decode($bytes, $alphabet);

    print $out_fh symbols2string(rle4_decode(string2symbols(bwt_decode(pack('C*', @$bytes), $idx))));
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
        compression($chunk, $out_fh);
    }

    # Close the output file
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
        decompression($fh, $out_fh);
    }

    # Close the files
    close $fh;
    close $out_fh;
}

main();
exit(0);
