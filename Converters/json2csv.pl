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
getopts('k:i:o:p:d:', \%opt);

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
    -d delimiter separator for csv (default: ",")
    -p print csv header row

example:
    $0 -k user.name,list.0,remote_ip -i input.json -o output.csv

EOT
    exit($code);
}

$opt{k} // usage(1);

sub unescape {
    my ($str) = @_;

    my %esc = (
               a => "\a",
               t => "\t",
               r => "\r",
               n => "\n",
               e => "\e",
               b => "\b",
               f => "\f",
              );

    $str =~ s{(?<!\\)(?:\\\\)*\\([@{[keys %esc]}])}{$esc{$1}}g;
    $str;
}

my @fields = map { [quotewords(qr/\./, 0, $_)] } quotewords(qr/\s*,\s*/, 1, $opt{k});

say($opt{p}) if defined($opt{p});

my $csv = Text::CSV->new(
                         {
                          eol      => "\n",
                          sep_char => defined($opt{d}) ? unescape($opt{d}) : ",",
                         }
                        )
  or die "Cannot use CSV: " . Text::CSV->error_diag();

sub extract {
    my ($json, $fields) = @_;

    my @row;
    foreach my $field (@{$fields}) {
        my $ref = $json;

        foreach my $key (@{$field}) {
            if (    ref($ref) eq 'ARRAY'
                and $key =~ /^[-+]?[0-9]+\z/
                and exists($ref->[$key])) {
                $ref = $ref->[$key];
            }
            elsif (ref($ref) eq 'HASH'
                   and exists($ref->{$key})) {
                $ref = $ref->{$key};
            }
            else {
                local $" = ' -> ';
                warn "[!] Field `$key' (from `@{$field}') does not exists in JSON.\n";
                $ref = undef;
                last;
            }
        }

        push @row, $ref;
    }

    \@row;
}

while (defined(my $line = <$in>)) {
    my $data = extract(from_json($line), \@fields);
    $csv->print($out, $data);
}
