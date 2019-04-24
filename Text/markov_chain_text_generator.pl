#!/usr/bin/perl

# A very simple text generator, using Markov chains.

# See also:
#   https://en.wikipedia.org/wiki/Markov_chain
#   https://rosettacode.org/wiki/Markov_chain_text_generator

use 5.014;
use strict;
use warnings;

use Encode qw(decode_utf8);
use Text::Unidecode qw(unidecode);
use List::Util qw(first shuffle);

my $n   = 2;
my $max = 200-$n;

sub build_dict {
    my ($n, @words) = @_;
    my %dict;
    for my $i (0 .. @words - $n) {
        my @prefix = @words[$i .. $i + $n - 1];
        push @{$dict{join ' ', @prefix}}, $words[$i + $n];
    }
    return %dict;
}

my $text = do {
    local $/;
    <>;
};

$text = decode_utf8($text);
$text = unidecode($text);
$text = lc($text);

$text =~ s/[^\w-]+/ /g;

my @words = split ' ', $text;
push @words, @words[0..$n-1];   # close the loop

my %dict  = build_dict($n, @words);
my $idx   = int(rand(@words - $n));
my @rotor = @words[$idx .. $idx + $n - 1];
my @chain = @rotor;

sub pick_next {
    my (@prefix) = @_;
    my $key = join(' ', @prefix);
    shift(@prefix);
    my @arr = @{$dict{$key}};
    first { exists($dict{join(' ', @prefix, $_)}) } shuffle(@arr);
}

for (1 .. $max) {
    my $new = pick_next(@rotor);
    shift @rotor;
    push @rotor, $new;
    push @chain, $new;
}

while (@chain) {
    say join(' ', splice(@chain, 0, 8));
}
