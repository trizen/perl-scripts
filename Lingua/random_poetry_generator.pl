#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 February 2017
# https://github.com/trizen

# An experimental random poetry generator.

use 5.010;
use strict;
use warnings;

use File::Find qw(find);

my $dir     = "$ENV{HOME}/Other/Grouped files";    # directory of grouped files
my $min_len = 20;                                  # minimum length of each verse

# Rhyme template
my @template = ('A', 'A', 'B', 'B');

my %words;

find {
    no_chdir => 1,
    wanted   => sub {
        if ((-f $_) and m{.*/(.*?)\.txt\z}i) {
            push @{$words{$1}}, do {
                open my $fh, '<', $_;
                chomp(my @words = <$fh>);
                @words;
            };
        }
    },
} => $dir;

my @keys = keys(%words);

my %endings;
my %used_ending;
my %used_word;

foreach my $r (@template) {
    my $ending;

    if (exists $endings{$r}) {
        $ending = $endings{$r};
    }
    else {
        my $try = 0;
        do {
            $ending = $keys[rand @keys];
        } while (exists($used_ending{$ending}) and ++$try < 100);
        $endings{$r}          = $ending;
        $used_ending{$ending} = 1;
    }

    my @row;

    for (my $length = 0; ;) {

        my $word;
        my $try = 0;
        do {
            my $key = ($length > $min_len) ? $ending : $keys[rand @keys];
            my $words = $words{$key};
            $word = $words->[rand @$words];
        } while (exists($used_word{$word}) and ++$try < 100);

        $used_word{$word} = 1;

        push @row, $word;
        last if $length > $min_len;
        $length += length($word) + 1;
    }

    say "@row";
}
