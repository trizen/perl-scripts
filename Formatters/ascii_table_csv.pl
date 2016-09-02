#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 March 2013
# https://github.com/trizen

# Print a CSV file to standard output as an ASCII table.

use 5.010;
use strict;
use autodie;
use warnings;
use open IO => ':utf8';

use Text::CSV qw();
use Text::ASCIITable qw();
use Encode qw(encode_utf8);
use Getopt::Std qw(getopts);

my %opt = (
           s => 0,
           d => ',',
          );

getopts('sw:d:', \%opt);

my $csv_file = shift() // die <<"USAGE";
usage: $0 [options] [csv_file]

options:
        -s    : allow whitespace in CSV (default: $opt{s})
        -d <> : separator character (default: '$opt{d}')
        -w <> : maximum width for table (default: no limit)

example: $0 -s -d ';' -w 80 file.csv
USAGE

my %esc = (
           a => "\a",
           t => "\t",
           r => "\r",
           n => "\n",
           e => "\e",
           b => "\b",
           f => "\f",
          );

$opt{d} =~ s{(?<!\\)(?:\\\\)*\\([@{[keys %esc]}])}{$esc{$1}}g;

## Parse the CSV file
sub parse_file {
    my ($file) = @_;

    my %record;
    open my $fh, '<', $file;

    my $csv = Text::CSV->new(
                             {
                              binary           => 1,
                              allow_whitespace => $opt{s},
                              sep_char         => $opt{d},
                             }
                            )
      or die "Cannot use CSV: " . Text::CSV->error_diag();

    my $columns = $csv->getline($fh);

    my $lines = 0;
    while (my $row = $csv->getline($fh)) {
        foreach my $i (0 .. $#{$columns}) {
            push @{$record{$columns->[$i]}}, $row->[$i];
        }
        ++$lines;
    }
    $csv->eof() or die "CSV ERROR: " . $csv->error_diag(), "\n";
    close $fh;

    return ($columns, \%record, $lines);
}

## Create the ASCII table
sub create_ascii_table {
    my ($columns, $record, $lines) = @_;

    my $table = Text::ASCIITable->new();
    $table->setCols(@{$columns});

    if ($opt{w}) {
        foreach my $column (@{$columns}) {
            $table->setColWidth($column, $opt{w} / @{$columns});
        }
    }

    foreach my $i (0 .. $lines - 1) {
        $table->addRow(map { encode_utf8($_->[$i]) } @{$record}{@{$columns}});
    }

    return $table;
}

{
    local $| = 1;
    print create_ascii_table(parse_file($csv_file));
}
