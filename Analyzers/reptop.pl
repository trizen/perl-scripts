#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 November 2011
# Edit: 03 November 2012
# https://github.com/trizen

# Find how many times each word exists in a file.

use 5.010;
use strict;
use warnings;

use open IO => ':utf8', ':std';
use Getopt::Long qw(GetOptions :config no_ignore_case);

my $word;         # count for a particular word
my $regex;        # split by regex
my $lowercase;    # lowercase words

my $top    = 0;   # top of repeated words
my $length = 1;   # mimimum length of a word

sub usage {
    print <<"HELP";
usage: $0: [options] <file>
\nOptions:
        -B   : deactivate word match boundary (default: on)
        -L   : lowercase every word (default: off)
        -w=s : show how many times a word repeats in the list
        -t=i : show a top list of 'i' words (default: $top)
        -l=i : minimum length of a valid word (default: $length)
        -r=s : split by a regular expression (default: \\W+)\n
HELP
    exit 0;
}

usage() unless @ARGV;

my $no_boundary;

GetOptions(
           'word|w=s'      => \$word,
           'top|t=i'       => \$top,
           'regex|r=s'     => \$regex,
           'no-boundary|B' => \$no_boundary,
           'L|lowercase!'  => \$lowercase,
           'length|l=i'    => \$length,
           'help|h|usage'  => \&usage,
          );

my $boundary = $no_boundary ? '' : '\\b';
$regex = defined $regex ? qr/$regex/ : qr/\W+/;

foreach my $file (grep { -f } @ARGV) {

    my $file_content;
    open my $fh, '<:encoding(UTF-8)', $file or die "Unable to open file '$file': $!\n";
    read $fh, $file_content, -s $file;
    close $fh;

    if ($lowercase) {
        $file_content = lc $file_content;
    }

    study $file_content;

    if (defined($word)) {
        my $i = 0;
        ++$i while $file_content =~ /$boundary\Q$word\E$boundary/go;
        printf "Word '%s' repeats %d time%s in the list.\n", $word, $i, ($i == 1 ? '' : 's');
        next;
    }

    my %uniq;
    @uniq{split($regex, $file_content)} = ();

    my @out;
    foreach my $word (keys %uniq) {
        next unless length $word >= $length;
        my $i = 0;
        ++$i while $file_content =~ /$boundary\Q$word\E$boundary/g;
        push @out, [$i, $word];
    }

    my $i      = 0;
    my @sorted = sort { $b->[0] <=> $a->[0] } @out;
    my $max    = length $sorted[0][0];
    print "> $file\n";

    foreach my $out (@sorted) {
        printf "%*s -> %s\n", $max, $out->[0], $out->[1];
        last if $top and ++$i == $top;
    }
}
