#!/usr/bin/perl

# Author: Trizen
# Date: 04 July 2024
# https://github.com/trizen

# Compress/decompress files using Binary Burrows-Wheeler Transform (BWT) + Binary Variable Run-Length Encoding.

# References:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A
#
#   Data Compression (Summer 2023) - Lecture 5 - Basic Techniques
#   https://youtube.com/watch?v=TdFWb8mL5Gk

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'BBWR',
    VERSION => '0.01',
    FORMAT  => 'bbwr',

    CHUNK_SIZE => 1 << 13,    # larger values == better compression
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

sub compression ($chunk, $out_fh) {

    my $bits  = unpack('B*', $chunk);
    my $vrle1 = binary_vrl_encode($bits);

    if (length($vrle1) < length($bits)) {
        printf "Doing early VLR, saving %s bits\n", length($bits) - length($vrle1);
        print $out_fh chr(1);
    }
    else {
        print $out_fh chr(0);
        $vrle1 = $bits;
    }

    my ($bwt, $idx) = bwt_encode($vrle1);
    my $vrle2 = binary_vrl_encode($bwt);

    say "BWT index: $idx";

    print $out_fh pack('N',  $idx);
    print $out_fh pack('N',  length($vrle2));
    print $out_fh pack('B*', $vrle2);
}

sub decompression ($fh, $out_fh) {

    my $compressed_byte = ord(getc($fh) // die "error");

    my $idx      = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));
    my $bits_len = unpack('N', join('', map { getc($fh) // die "error" } 1 .. 4));

    say "BWT index = $idx";

    my $bwt  = binary_vrl_decode(read_bits($fh, $bits_len));
    my $data = bwt_decode($bwt, $idx);

    if ($compressed_byte == 1) {
        $data = binary_vrl_decode($data);
    }

    print $out_fh pack('B*', $data);
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
