#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 February 2017
# https://github.com/trizen

# An experimental poetry generator, using a given poetry
# as input, replacing words with other similar ending words.

# usage:
#   perl poetry_from_poetry.pl [poetry.txt] [wordlists]

use 5.016;
use strict;
use autodie;
use warnings;

use open IO => ':utf8', ':std';

use File::Find qw(find);

my $poetry_file = shift(@ARGV);

@ARGV
  || die "usage: $0 [poetry.txt] [wordlists]\n";

my $poetry = do {
    open my $fh, '<', $poetry_file;
    local $/;
    <$fh>;
};

my $ending_len = 3;    # word ending length

my %words;
my %seen;

sub collect_words {
    my ($file) = @_;

    open my $fh, '<', $file;

    my $content = do {
        local $/;
        <$fh>;
    };

    close $fh;

    while ($content =~ /([\pL]+)/g) {
        my $word = CORE::fc($1);
        if (length($word) > $ending_len) {
            next if $seen{$word}++;
            push @{$words{substr($word, -$ending_len)}}, $word;
        }
    }
}

find {
    no_chdir => 1,
    wanted   => sub {
        if ((-f $_) and (-T _)) {
            collect_words($_);
        }
    },
} => @ARGV;

$poetry =~ s{([\pL]+)}{
    my $word = $1;
    if (length($word) <= $ending_len) {
        $word;
    }
    else {
        my $ending = CORE::fc(substr($word, -$ending_len));
        exists($words{$ending}) ? $words{$ending}[rand @{$words{$ending}}] : $word;
    }
}ge;

say $poetry;
