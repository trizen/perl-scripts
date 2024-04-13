#!/usr/bin/perl

# Author: Trizen
# Date: 10 September 2023
# Edit: 13 April 2024
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + Variable Run-Length encoding + Huffman coding.

# Reference:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'BWRL2',
    VERSION => '0.01',
    FORMAT  => 'bwrl2',

    CHUNK_SIZE => 1 << 17,    # higher value = better compression
};

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

sub VLR_encoding ($bytes) {

    my $uncompressed = '';
    my $bitstream    = '';
    my $rle          = run_length($bytes);

    foreach my $cv (@$rle) {
        my ($c, $v) = @$cv;
        $uncompressed .= chr($c);
        if ($v == 1) {
            $bitstream .= '0';
        }
        else {
            my $t = sprintf('%b', $v);
            $bitstream .= join('', '1' x (length($t) - 1), '0', substr($t, 1));
        }
    }

    return ($uncompressed, pack('B*', $bitstream));
}

sub VLR_decoding ($uncompressed, $bits_fh) {

    my $decoded = '';
    my $buffer  = '';

    foreach my $c (@$uncompressed) {

        my $bl = 0;
        while (read_bit($bits_fh, \$buffer) == 1) {
            ++$bl;
        }

        if ($bl > 0) {
            $decoded .= chr($c) x oct('0b1' . join('', map { read_bit($bits_fh, \$buffer) } 1 .. $bl));
        }
        else {
            $decoded .= chr($c);
        }
    }

    return $decoded;
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

        my ($bwt,          $idx)     = bwt_encode($chunk);
        my ($uncompressed, $lengths) = VLR_encoding([unpack('C*', $bwt)]);

        print $out_fh pack('N', $idx);
        mrl_compress($uncompressed, $out_fh);
        create_huffman_entry(rle4_encode([unpack('C*', $lengths)]), $out_fh);
    }

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

        my $idx = unpack('N', join('', map { getc($fh) // die "decompression error" } 1 .. 4));

        my $uncompressed = mrl_decompress($fh);    # uncompressed

        open my $len_fh, '+>:raw', \my $lengths;
        print $len_fh pack('C*', @{rle4_decode(decode_huffman_entry($fh))});    # lengths
        seek($len_fh, 0, 0);

        my $dec = VLR_decoding($uncompressed, $len_fh);
        print $out_fh bwt_decode($dec, $idx);
    }

    close $fh;
    close $out_fh;
}

main();
exit(0);
