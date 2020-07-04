#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 June 2016
# Website: https://github.com/trizen

# Make a top with the first letters of each word in a given text.

# usage: cat file.txt | perl first_letter_top.pl

use 5.014;
use strict;
use warnings;

use List::Util qw(sum);
use open IO => ':utf8', ':std';

my %table;

foreach my $word (split(' ', do { local $/; <> })) {
    if ($word =~ /^[^\pL]*(\pL)/) {
        $table{lc($1)}++;
    }
}

my $max = sum(values %table);

foreach my $key (sort { $table{$b} <=> $table{$a} } keys %table) {
    printf("%s -> %3d (%5.2f%%)\n", $key, $table{$key}, $table{$key} / $max * 100);
}
