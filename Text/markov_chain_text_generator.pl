#!/usr/bin/perl

# A very simple text generator, using Markov chains.

# This version uses prefixes of variable lengths, between `n_min` and `n_max`.

# See also:
#   https://en.wikipedia.org/wiki/Markov_chain
#   https://rosettacode.org/wiki/Markov_chain_text_generator

use 5.014;
use strict;
use warnings;

use Encode qw(decode_utf8);
use Text::Unidecode qw(unidecode);
use List::Util qw(uniq);

my $n_min = 2;
my $n_max = 4;
my $max   = 200 - $n_max;

sub build_dict {
    my (@orig_words) = @_;

    my %dict;

    foreach my $n ($n_min .. $n_max) {

        my @words = (@orig_words, @orig_words[0 .. $n - 1]);

        for my $i (0 .. $#words - $n) {
            my @prefix = @words[$i .. $i + $n - 1];
            push @{$dict{join ' ', @prefix}}, $words[$i + $n];
        }
    }

    foreach my $key(keys %dict) {
        $dict{$key} = [uniq(@{$dict{$key}})];
    }

    return %dict;
}

my $text = do {
    if (-t STDIN) {
        my $content = '';
        foreach my $file (@ARGV) {
            open my $fh, '<', $file;
            local $/;
            $content .= <$fh>;
            $content .= "\n";
        }
        $content;
    }
    else {
        local $/;
        <>;
    }
};

$text = decode_utf8($text);
$text = unidecode($text);
$text = lc($text);

$text =~ s/[^\w'-]+/ /g;

my @words = grep { /^[a-z]/ } split ' ', $text;

my %dict  = build_dict(@words);
my $idx   = int(rand(@words - $n_max));
my @rotor = @words[$idx .. $idx + $n_min - 1];
my @chain = @rotor;

sub pick_next {
    my (@prefix) = @_;

    my $key = join(' ', @prefix);
    my @arr = @{$dict{$key}};

    $arr[rand @arr];
}

for (1 .. $max) {

    my $new = pick_next(@rotor);
    my $idx = int(rand($n_max - $n_min + 1) + $n_min - 1);

    if ($idx > $#rotor) {
        #shift(@rotor) if rand() < 0.5;
    }
    else {
        @rotor = @rotor[$#rotor - $idx + 1 .. $#rotor];
    }

    push @rotor, $new;
    push @chain, $new;
}

while (@chain) {
    say join(' ', splice(@chain, 0, 8));
}
