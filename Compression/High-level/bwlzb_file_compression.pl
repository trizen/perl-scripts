#!/usr/bin/perl

# Author: Trizen
# Date: 03 June 2024
# https://github.com/trizen

# Compress/decompress files using byte-aligned LZ77 compression (LZSS) + Burrows-Wheeler Transform (BWT) + Move-to-front transform (MTF) + Huffman coding.

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
    PKGNAME => 'BWLZB',
    VERSION => '0.01',
    FORMAT  => 'bwlzb',

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

    local $Compression::Util::LZ_MIN_LEN = 64;

    my $rle4 = symbols2string(rle4_encode(string2symbols($chunk)));
    my $lzb  = lzb_compress($rle4);
    my ($bwt, $idx) = bwt_encode($lzb);

    my ($mtf, $alphabet) = mtf_encode(string2symbols($bwt));
    my $rle = zrle_encode($mtf);

    my $enc = pack('N', $idx) . encode_alphabet($alphabet) . create_huffman_entry($rle);

    print $out_fh $enc;
}

sub decompression ($fh, $out_fh) {

    my $idx      = bytes2int($fh, 4);
    my $alphabet = decode_alphabet($fh);
    my $rle      = decode_huffman_entry($fh);

    my $mtf = zrle_decode($rle);
    my $bwt = symbols2string(mtf_decode($mtf, $alphabet));
    my $lzb = bwt_decode($bwt, $idx);

    my $rle4 = lzb_decompress($lzb);
    my $data = symbols2string(rle4_decode(string2symbols($rle4)));
    print $out_fh $data;
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
