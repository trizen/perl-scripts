#!/usr/bin/perl

# Author: Trizen
# Date: 15 December 2022
# https://github.com/trizen

# Compress/decompress files using LZ77 compression.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);

use constant {
              PKGNAME => 'LZ77',
              VERSION => '0.01',
              FORMAT  => 'lz77',
             };

use constant {SIGNATURE => "LZ77" . chr(1)};

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

        lzw_decompress_file($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        lzw_compress_file($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

sub compression ($str) {

    my @rep;
    my $la = 0;

    while ($la < length($str)) {

        my $n = 1;
        my $p = 0;
        my $tmp;

        while (
               $n < 255
               and $la + $n < length($str)
               and ($tmp = index(substr($str, 0, $la), substr($str, $la, $n), $p)) >= 0) {
            $p = $tmp;
            $n++;
        }

        --$n;
        my $c = substr($str, $la + $n, 1);
        push @rep, [$p, $n, ord($c)];
        $la += $n + 1;
    }

    join('', map { pack 'NCC', @$_ } @rep);
}

sub decompression ($str) {

    my $ret = '';
    while (length($str)) {
        my ($s, $l, $c) = unpack('NCC', substr($str, 0, 6, ''));
        $ret .= substr($ret, $s, $l) . chr($c);
    }

    $ret;
}

# Compress file
sub lzw_compress_file ($input, $output) {

    my $compressed = do {
        open my $fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";
        local $/;
        compression(scalar <$fh>);
    };

    my $header = SIGNATURE;

    # Open the output file for writing
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for write: $!";

    # Print the header
    print $out_fh $header;

    # Print the compressed data
    print $out_fh $compressed;

    # Close the file
    close $out_fh;
}

# Decompress file
sub lzw_decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input;
    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output;

    # Print the decompressed data
    print $out_fh decompression(
        do {
            local $/;
            scalar <$fh>;
        }
    );

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
