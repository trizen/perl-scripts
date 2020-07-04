#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 February 2017
# https://github.com/trizen

# An experimental random poetry generator.

# usage:
#   perl random_poetry_generator.pl [wordlist]

use 5.016;
use strict;
use autodie;
use warnings;

use open IO => ':utf8', ':std';

use List::Util qw(max);
use File::Find qw(find);

@ARGV || die "usage: $0 [wordlists]\n";    # wordlists or directories

my $min_len     = 20;                      # minimum length of each verse
my $ending_len  = 3;                       # rhyme ending length
my $strophe_len = 4;                       # number of verses in a strophe

#<<<
# Rhymes template
my @template = (
    'A', 'A', 'B', 'B',
    'A', 'B', 'B', 'A',
    'A', 'B', 'A', 'B',
    'B', 'A', 'A', 'B',
);
#>>>

my $max_endings = do {
    my %count;
    ++$count{$_} for @template;
    max(values %count);
};

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

    my @words =
      grep { length($_) > $ending_len }
      map  { CORE::fc(s/^[^\pL]+//r =~ s/[^\pL]+\z//r) }
      split(' ', $content);

    foreach my $word (@words) {
        next if $seen{$word}++;
        push @{$words{substr($word, -$ending_len)}}, $word;
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
my %used_ending;
my %used_word;

my $strofhe_i = 0;
foreach my $r (@template) {
    my $ending;

    if (exists $endings{$r}) {
        $ending = $endings{$r};
    }
    else {
        my $try = 0;
        do {
            $ending = $keys[rand @keys];
        } while (@{$words{$ending}} < $max_endings and !exists($used_ending{$ending}) and ++$try < 1000);
        $endings{$r}          = $ending;
        $used_ending{$ending} = 1;
    }

    my @row;

    for (my $length = 0 ; ;) {

        my $word;
        my $try = 0;
        do {
            my $key = ($length > $min_len) ? $ending : $keys[rand @keys];
            my $words = $words{$key};
            $word = $words->[rand @$words];
        } while (exists($used_word{$word}) and ++$try < 1000);

        $used_word{$word} = 1;

        push @row, $word;
        last if $length > $min_len;
        $length += length($word) + 1;
    }

    say "@row";
    print "\n" if (++$strofhe_i % $strophe_len == 0);
}
