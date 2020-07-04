#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 February 2017
# https://github.com/trizen

# An experimental poetry generator, using a given poetry as input,
# replacing words with random words from groups of alike ending words.

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
my $group_len  = 0;    # the number of words in a group - 1

my $word_regex = qr/[\pL]+(?:-[\pL]+)?/;

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

    while ($content =~ /($word_regex(?:\h+$word_regex){$group_len})/go) {
        my $word = CORE::fc($1);
        my $len = $ending_len;

        if (length($word) > $len) {
            next if $seen{$word}++;
            push @{$words{substr($word, -$len)}}, $word;
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

my @keys = keys(%words);
my %endings;

$poetry =~ s{($word_regex)}{
    my $word = $1;
    my $len = $ending_len;

    if (length($word) <= $len) {
        $word;
    }
    else {
        my $ending = CORE::fc(substr($word, -$len));
        my $key = ($endings{$ending} //= $keys[rand @keys]);
        exists($words{$key}) ? $words{$key}[rand @{$words{$key}}] : $word;
    }
}ge;

say $poetry;
