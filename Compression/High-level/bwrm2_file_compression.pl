#!/usr/bin/perl

# Author: Trizen
# Date: 10 September 2023
# Edit: 13 April 2024
# https://github.com/trizen

# Compress/decompress files using Burrows-Wheeler Transform (BWT) + Run-Length encoding + MTF + ZRLE + Bzip2 on lengths.

# Reference:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'BWRM2',
    VERSION => '0.01',
    FORMAT  => 'bwrm2',

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

    my @lengths;
    my @uncompressed;

    my $rle = run_length($bytes, 256);

    foreach my $cv (@$rle) {
        my ($c, $v) = @$cv;
        push @uncompressed, $c;
        push @lengths,      $v - 1;
    }

    return (\@uncompressed, \@lengths);
}

sub VLR_decoding ($uncompressed, $lengths) {

    my $decoded = '';

    foreach my $i (0 .. $#{$uncompressed}) {

        my $c   = $uncompressed->[$i];
        my $len = $lengths->[$i];

        if ($len > 0) {
            $decoded .= chr($c) x ($len + 1);
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
        my ($uncompressed, $lengths) = VLR_encoding(string2symbols($bwt));

        print $out_fh pack('N', $idx);

        print $out_fh mrl_compress_symbolic($uncompressed);
        print $out_fh bz2_compress(pack('C*', @$lengths));
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

        my $uncompressed = mrl_decompress_symbolic($fh);
        my $lengths      = bz2_decompress($fh);
        my $dec          = VLR_decoding($uncompressed, string2symbols($lengths));
        print $out_fh bwt_decode($dec, $idx);
    }

    close $fh;
    close $out_fh;
}

main();
exit(0);
