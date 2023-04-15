#!/usr/bin/perl

# Author: Trizen
# Date: 03 April 2023
# https://github.com/trizen

# Convert a GDBM database to a Berkeley database.

use 5.036;
use DB_File;
use GDBM_File;

scalar(@ARGV) == 2 or die "usage: $0 [input.dbm] [output.dbm]";

my $input_file  = $ARGV[0];
my $output_file = $ARGV[1];

if (not -f $input_file) {
    die "Input file <<$input_file>> does not exist!\n";
}

if (-e $output_file) {
    die "Output file <<$output_file>> already exists!\n";
}

tie(my %input, 'GDBM_File', $input_file, &GDBM_READER, 0555)
  or die "Can't access database <<$input_file>>: $!";

tie(my %output, 'DB_File', $output_file, O_CREAT | O_RDWR, 0666, $DB_HASH)
  or die "Can't create database <<$output_file>>: $!";

while (my ($key, $value) = each %input) {
    $output{$key} = $value;
}

untie(%input);
untie(%output);
