#!/usr/bin/perl

# Author: Trizen
# Date: 17 December 2023
# https://github.com/trizen

# Change the encoding of a text file.

use 5.010;
use strict;
use warnings;

use Encode       qw(encode decode);
use Getopt::Long qw(GetOptions);

my $input_encoding  = 'iso-8859-2';
my $output_encoding = 'utf-8';

sub help {
    my ($exit_code) = @_;
    $exit_code //= 0;
    print <<"EOT";
usage: $0 [options] [input.txt] [output.txt]

    --from=s  : input encoding (default: $input_encoding)
    --to=s    : output encoding (default: $output_encoding)
EOT

    exit($exit_code);
}

GetOptions(
           "from=s" => \$input_encoding,
           "to=s"   => \$output_encoding,
           "h|help" => sub { help(0) }
          )
  or do {
    warn("Error in command line arguments\n");
    help(1);
  };

my $input  = $ARGV[0] // help(1);
my $output = $ARGV[1] // $input;

my $raw = do {
    open my $fh, '<:raw', $input or die "Can't open <<$input>> for reading: $!";
    local $/;
    <$fh>;
};

my $dec = decode($input_encoding, $raw, Encode::FB_CROAK);
my $enc = encode($output_encoding, $dec, Encode::FB_CROAK);

open my $fh, '>:raw', $output or die "Can't open <<$output>> for writing: $!";
print $fh $enc;
close $fh;
