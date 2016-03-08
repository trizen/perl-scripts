#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 08 March 2016
# License: GPLV3
# Website: https://github.com/trizen

# Converts a stream of newline separated json data to csv format.
# Related to: https://github.com/jehiah/json2csv

use 5.010;
use strict;
use warnings;

use Text::CSV qw();
use JSON qw(from_json);
use Getopt::Std qw(getopts);
use Text::ParseWords qw(quotewords);

use open IO => ':encoding(UTF-8)', ':std';

my %opt;
getopts('k:i:o:p:', \%opt);

my $in  = \*ARGV;
my $out = \*STDOUT;

if (defined($opt{i})) {
    open $in, '<', $opt{i}
      or die "Can't open file `$opt{i}' for reading: $!";
}

if (defined($opt{o})) {
    open $out, '>', $opt{o}
      or die "Can't open file `$opt{o}' for writing: $!";
}

sub usage {
    my ($code) = @_;
    print <<"EOT";
usage: $0 [options] [< input.json] [> output.csv]

options:
    -k fields.0,and,nested.fields,to,output
    -i /path/to/input.json (optional; default is stdin)
    -o /path/to/output.csv (optional; default is stdout)
    -p print csv header row

example:
    $0 -k user.name,list.0,remote_ip -i input.json -o output.csv

EOT
    exit($code);
}

$opt{k} // usage(1);

my @fields = quotewords(qr/\s*,\s*/, 1, $opt{k});

say($opt{p}) if defined($opt{p});

my $csv = Text::CSV->new({eol => "\n"})
  or die "Cannot use CSV: " . Text::CSV->error_diag();

sub json2csv {
    my ($json, $fields) = @_;

    my @row;
    foreach my $field (@{$fields}) {
        my $ref = $json;
        my @keys = quotewords(qr/\./, 0, $field);

        foreach my $key (@keys) {
            if ($key =~ /^[-+]?[0-9]+\z/) {
                $ref = $ref->[$key];
            }
            else {
                $ref = $ref->{$key};
            }
        }

        push @row, $ref;
    }

    $csv->print($out, \@row);
}

while (defined(my $line = <$in>)) {
    json2csv(from_json($line), \@fields);
}
