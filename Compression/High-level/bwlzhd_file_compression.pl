#!/usr/bin/perl

# Author: Trizen
# Date: 15 December 2022
# Edit: 19 March 2024
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler transform (BWT) + Run-length Encoding (RLE) + LZ77 compression (LZHD variant) + Huffman coding.

# Encoding the distances/indices using a DEFLATE-like approach.

use 5.036;

use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'BWLZHD',
    VERSION => '0.02',
    FORMAT  => 'bwlzhd',

    CHUNK_SIZE => 1 << 17,    # higher value = better compression
};

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(2);

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

    my $rle4 = rle4_encode([unpack('C*', $chunk)]);
    my ($bwt, $idx) = bwt_encode(pack('C*', @$rle4));

    $bwt = pack('C*', @{rle4_encode([unpack('C*', $bwt)])});

    say "BWT index = $idx";

    my ($uncompressed, $distances, $lengths, $matches) = lz77_encode($bwt);
    my $est_ratio = length($chunk) / (4 * scalar(@$uncompressed));

    say(scalar(@$uncompressed), ' -> ', $est_ratio);

    print $out_fh pack('N', $idx);
    print $out_fh mrl_compress_symbolic($uncompressed);
    print $out_fh create_huffman_entry($lengths);
    print $out_fh create_huffman_entry($matches);
    print $out_fh obh_encode($distances);
}

sub decompression ($fh, $out_fh) {

    my $idx          = unpack('N', join('', map { getc($fh) // return undef } 1 .. 4));
    my $uncompressed = mrl_decompress_symbolic($fh);
    my $lengths      = decode_huffman_entry($fh);
    my $matches      = decode_huffman_entry($fh);
    my $distances    = obh_decode($fh);

    my $rle4 = lz77_decode($uncompressed, $distances, $lengths, $matches);
    my $bwt  = symbols2string(rle4_decode(string2symbols($rle4)));
    my @rle4 = unpack('C*', bwt_decode($bwt, $idx));
    print $out_fh symbols2string(rle4_decode(\@rle4));
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
        decompression($fh, $out_fh);
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
