#!/usr/bin/perl

# Author: Trizen
# Date: 01 December 2022
# https://github.com/trizen

# Compress/decompress files using Huffman coding.

# Huffman coding algorithm from:
#   https://rosettacode.org/wiki/Huffman_coding#Perl

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use List::Util     qw(min);
use Getopt::Std    qw(getopts);
use File::Basename qw(basename);

use constant {
              PKGNAME => 'huffman-simple',
              VERSION => '0.01',
              FORMAT  => 'hfm',
             };

use constant {SIGNATURE => uc(FORMAT) . chr(1)};

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

        decompress($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        compress($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0];
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for (0, 1) }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

# make a tree, and return resulting dictionaries
sub mktree ($bytes) {
    my (%freq, @nodes);

    $freq{$_}++ for @$bytes;
    @nodes = map { [$_, $freq{$_}] } keys %freq;

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice(@nodes, 0, 2);
        push @nodes, [[$x, $y], $x->[1] + $y->[1]];
    } while (@nodes > 1);

    walk($nodes[0], '', {}, {});
}

sub huffman_encode ($bytes, $dict) {
    my $enc = '';
    for (@$bytes) {
        $enc .= $dict->{$_} // die "bad char: $_";
    }
    return $enc;
}

sub huffman_decode ($bits, $hash) {
    local $" = '|';
    $bits =~ s/(@{[sort { length($a) <=> length($b) } keys %{$hash}]})/$hash->{$1}/gr;  # very fast
}

sub valid_archive {
    my ($fh) = @_;

    if (read($fh, (my $sig), length(SIGNATURE), 0) == length(SIGNATURE)) {
        $sig eq SIGNATURE || return;
    }

    return 1;
}

sub compress ($input, $output) {

    # Open the input file
    open my $fh, '<:raw', $input;

    # Open the output file and write the archive signature
    open my $out_fh, '>:raw', $output;
    print $out_fh SIGNATURE;

    my $chars = do {
        local $/;
        <$fh>;
    };

    close $fh;

    my @bytes = unpack('C*', $chars);
    my ($h, $rev_h) = mktree(\@bytes);

    my $enc   = huffman_encode(\@bytes, $h);
    my $codes = join('', map { $h->{$_} // '' } 0 .. 255);

    my $dict = '';

    foreach my $i (0 .. 255) {
        exists($h->{$i}) or next;
        $dict .= chr($i);
        $dict .= chr(length($h->{$i}) - 1);
    }

    print $out_fh chr((length($dict) >> 1) - 1);
    print $out_fh $dict;

    print $out_fh pack("N",  length($codes));
    print $out_fh pack("B*", $codes);

    print $out_fh pack("N",  length($enc));
    print $out_fh pack("B*", $enc);

    return 1;
}

sub decompress ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input;
    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output;

    my $dict_len = ord(getc($fh)) + 1;

    my %code_lens;
    for (1 .. $dict_len) {
        my $c = ord(getc($fh));
        my $l = ord(getc($fh)) + 1;
        $code_lens{$c} = $l;
    }

    my $codes     = '';
    my $codes_len = unpack('N', join('', map { getc($fh) } 1 .. 4));

    while (length($codes) < $codes_len) {
        $codes .= unpack('B*', getc($fh));
    }

    my %rev_hash;
    foreach my $i (sort { $a <=> $b } keys %code_lens) {
        my $code = substr($codes, 0, $code_lens{$i}, '');
        $rev_hash{$code} = chr($i);
    }

    my $enc_len = unpack('N', join('', map { getc($fh) } 1 .. 4));
    print $out_fh huffman_decode(unpack("B" . $enc_len, do { local $/; <$fh> }), \%rev_hash);
    return 1;
}

main();
exit(0);
