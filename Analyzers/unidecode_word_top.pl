#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11 March 2013
# https://github.com/trizen

# usage: perl unidecode_word_top.pl [file]

use 5.010;
use strict;
use autodie;
use warnings;
use Text::Unidecode qw(unidecode);

open my $fh, '<:encoding(UTF-8)', shift;

my %table;
while (<$fh>) {
    my @words = split(' ', unidecode(lc $_));
    s{^[[:punct:]]+}{}, s{[[:punct:]]+\z}{} for @words;
    /^\w/ && /\w\z/ && $table{$_}++ for @words;
}

foreach my $key (sort { $table{$b} <=> $table{$a} || $a cmp $b } keys %table) {
    printf "%-50s%4s\n", $key, $table{$key};
}
