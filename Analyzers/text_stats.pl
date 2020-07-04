#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 June 2013
# https://github.com/trizen

#
## This script will compare the repetition of words from different authors.
#
## Example:
#       perl text_stats.pl shake_1.txt shake_2.txt - twain_1.txt twain_2.txt
#
# The above example compares the files from two authors.
# If the first author written more words than the second one,
# the script will estimate the repetition of words from the second author
# as if it wrote the same amounts of words as the first author.
#
# You can provide as many authors as you want, separated by a dash argument (-).

use 5.010;
use strict;
use autodie;
use warnings;

use open IO => 'utf8';
use Text::Unidecode qw(unidecode);

my @authors = [];

while (@ARGV) {
    my $file = shift @ARGV;

    if ($file eq '-') {
        push @authors, [];
        next;
    }

    -f $file or do { warn "$0: '$file' is not a file!\n"; next };

    push @{$authors[-1]}, $file;
}

my %table;
foreach my $author_files (@authors) {
    foreach my $file (@{$author_files}) {

        open my $fh, '<', $file;

        while (<$fh>) {

            s{[^\-'[:^punct:]]+}{ }g;   # try to comment out this line
            my @words = split(' ', unidecode(lc));

            s{^[[:punct:]]+}{}, s{[[:punct:]]+\z}{} for @words;
            /^\w/ && /\w\z/ && $table{$author_files}{$_}++ for @words;
        }
    }
}

my %data;
my @lens;
foreach my $i (0 .. $#authors) {

    my $author = $authors[$i];
    my $words  = $table{$author};

    while (my ($word, $cnt) = each %{$words}) {
        $data{$word} //= [(0) x $i];
        push @{$data{$word}}, $cnt;
    }

    push @lens, scalar keys %{$words};
}

my @ratios = (1);
foreach my $i (1 .. $#lens) {
    push @ratios, $lens[$i] / $lens[$i-1];
}

print join(',', "WORD", (map { qq["AUTHOR $_"] } 1 .. $#authors + 1)), "\n";

foreach my $key (sort { $data{$b}[0] <=> $data{$a}[0] } keys %data) {
    my @row;
    foreach my $i (0 .. $#authors) {
        push @row, sprintf("%0.f", ($data{$key}[$i] // 0) / $ratios[$i]);
    }
    print join(',', qq["$key"], @row), "\n";
}
