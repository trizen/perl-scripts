#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 18 Novermber 2012
# Website: http://trizen.googlecode.com

# For a stronger encryption, use very long keys, but
# avoid keys which contains spaces or null byte characters.

use 5.010;
use strict;
use warnings;

use Getopt::Std qw(getopts);

my %opts;
getopts('k:o:i:h', \%opts);

sub usage {
    warn "\n[ERROR]: ", @_, "\n\n" if @_;
    die <<"USAGE";
usage: $0 [options]

options:
        -k KEY    : your key (can be a file)
        -i INPUT  : input file (must exists)
        -o OUTPUT : output file (default: STDOUT)
        -h        : print this message and exit

example: $0 -k test -i input.txt -o output.txt
USAGE
}

$opts{h} && usage();

encode_file(
            file => defined($opts{i}) && -f $opts{i} ? $opts{i} : usage("No input file specified!"),
            out_fh => defined($opts{o}) ? open_file('>', $opts{o}) : *STDOUT,
            key => defined($opts{k}) ? -f $opts{k} ? read_file($opts{k}) : $opts{k} : usage("No key specified!"),
           );

sub open_file {
    my ($mode, $file) = @_;
    open my $fh, $mode, $file
      or die "Can't open file '$file' in mode '$mode': $!";
    return $fh;
}

sub read_file {
    my ($file) = @_;
    local $/ = undef;
    my $fh = open_file('<', $file);
    return <$fh>;
}

sub encode_file {
    my %args = @_;

    # Available keys:
    # file      => 'file.txt',
    # fh        => GLOB ref,
    # out_fh    => where to print,
    # key       => your KEY,
    # file_size => size of the file,

    my $fh = ref $args{fh} eq 'GLOB' ? $args{fh} : open_file('<', $args{file});
    my $file_size = $args{file_size} // (-s $fh) // (-s $args{file}) // do {
        warn "Can't get the file size!\n";
        return;
    };

    my $key = substr($args{key}, 0, $file_size) // return;
    my $key_len = length $key;

    while (1) {
        my $chunk_len = read($fh, my ($chunk), $key_len);

        if ($chunk_len == $key_len) {
            print {$args{out_fh}} $chunk ^ $key;
        }
        else {
            print {$args{out_fh}} $chunk ^ substr($key, 0, $chunk_len);
            last;
        }
    }

    return 1;
}
