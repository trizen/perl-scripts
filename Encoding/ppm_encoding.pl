#!/usr/bin/perl

# Author: Trizen
# Date: 10 August 2023
# https://github.com/trizen

# Implementation of a PPM (prediction by partial-matching) encoder, using Huffman Coding.

# See also:
#   https://rosettacode.org/wiki/huffman_coding

# Reference:
#   Data Compression (Summer 2023) - Lecture 16 - Adaptive Methods
#   https://youtube.com/watch?v=YKv-w8bXi9c

use 5.036;
use List::Util qw(max uniq);

use constant {
              ESCAPE_SYMBOL => 256,    # escape symbol
              CONTEXTS_NUM  => 4,      # maximum number of contexts
              VERBOSE       => 0,      # verbose/debug mode
             };

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for ('0', '1') }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

# make a tree, and return resulting dictionaries
sub mktree_from_freq ($freq) {

    my @nodes = map { [$_, $freq->{$_}] } sort { $a <=> $b } keys %$freq;

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice(@nodes, 0, 2);
        if (defined($x)) {
            if (defined($y)) {
                push @nodes, [[$x, $y], $x->[1] + $y->[1]];
            }
            else {
                push @nodes, [[$x], $x->[1]];
            }
        }
    } while (@nodes > 1);

    walk($nodes[0], '', {}, {});
}

sub freq ($arr) {
    my %freq;
    ++$freq{$_} for @$arr;
    return \%freq;
}

sub encode ($symbols, $alphabet) {

    my @enc;
    my @prev;

    my @ctx = ({join(' ', @prev) => {freq => freq($alphabet)}},);

    foreach my $i (1 .. CONTEXTS_NUM) {
        push @ctx, {join(' ', @prev) => {freq => freq([ESCAPE_SYMBOL])}};
    }

    foreach my $c (@ctx) {
        $c->{join(' ', @prev)}{tree} = (mktree_from_freq($c->{join(' ', @prev)}{freq}))[0];
    }

    foreach my $symbol (@$symbols) {

        foreach my $k (reverse(0 .. $#ctx)) {
            my $s = join(' ', @prev[max($#prev - $k + 2, 0) .. $#prev]);

            if (!exists($ctx[$k]{$s})) {
                $ctx[$k]{$s}{freq} = freq([ESCAPE_SYMBOL]);
            }

            if (exists($ctx[$k]{$s}{freq}{$symbol})) {

                if ($k != 0) {
                    $ctx[$k]{$s}{tree} = (mktree_from_freq($ctx[$k]{$s}{freq}))[0];
                    ++$ctx[$k]{$s}{freq}{$symbol};
                }

                say STDERR "Encoding $symbol with context=$k using $ctx[$k]{$s}{tree}{$symbol} and prefix ($s)" if VERBOSE;
                push @enc, $ctx[$k]{$s}{tree}{$symbol};

                push @prev, $symbol;
                shift(@prev) if (scalar(@prev) >= CONTEXTS_NUM);
                last;
            }

            $ctx[$k]{$s}{tree} = (mktree_from_freq($ctx[$k]{$s}{freq}))[0];
            push @enc, $ctx[$k]{$s}{tree}{(ESCAPE_SYMBOL)};
            say STDERR "Escaping from context = $k with $ctx[$k]{$s}{tree}{(ESCAPE_SYMBOL)}" if VERBOSE;
            $ctx[$k]{$s}{freq}{$symbol} = 1;
        }
    }

    return join('', @enc);
}

sub decode ($enc, $alphabet) {

    my @out;
    my @prev;
    my $prefix = '';
    my $s      = join(' ', @prev);

    my @ctx = ({$s => {freq => freq($alphabet)}},);

    foreach my $i (1 .. CONTEXTS_NUM) {
        push @ctx, {$s => {freq => freq([ESCAPE_SYMBOL])}},;
    }

    foreach my $c (@ctx) {
        $c->{$s}{tree} = (mktree_from_freq($c->{$s}{freq}))[1];
    }

    my $context = CONTEXTS_NUM;
    my @key     = @prev;

    foreach my $bit (split(//, $enc)) {

        $prefix .= $bit;

        if (!exists($ctx[$context]{$s})) {
            $ctx[$context]{$s}{freq} = freq([ESCAPE_SYMBOL]);
            $ctx[$context]{$s}{tree} = (mktree_from_freq($ctx[$context]{$s}{freq}))[1];
        }

        if (exists($ctx[$context]{$s}{tree}{$prefix})) {
            my $symbol = $ctx[$context]{$s}{tree}{$prefix};
            if ($symbol == ESCAPE_SYMBOL) {
                --$context;
                shift(@key) if (scalar(@key) >= $context);
                $s = join(' ', @key);
            }
            else {
                push @out, $symbol;
                foreach my $k (max($context, 1) .. CONTEXTS_NUM) {
                    my $s = join(' ', @prev[max($#prev - $k + 2, 0) .. $#prev]);
                    $ctx[$k]{$s}{freq} //= freq([ESCAPE_SYMBOL]);
                    ++$ctx[$k]{$s}{freq}{$symbol};
                    $ctx[$k]{$s}{tree} = (mktree_from_freq($ctx[$k]{$s}{freq}))[1];
                }
                $context = CONTEXTS_NUM;
                push @prev, $symbol;
                shift(@prev) if (scalar(@prev) >= CONTEXTS_NUM);
                @key = @prev[max($#prev - $context + 2, 0) .. $#prev];
                $s   = join(' ', @key);
            }
            $prefix = '';
        }
    }

    return \@out;
}

my $text = "A SAD DAD; A SAD SALSA";
##my $text = "this is an example for huffman encoding";

my @bytes = unpack('C*', $text);

my $enc = encode(\@bytes, [uniq(@bytes)]);
my $dec = decode($enc, [uniq(@bytes)]);

say $enc;
say pack('C*', @$dec);

printf("Saved: %.3f%%\n", ((@$dec - length($enc) / 8) / @$dec * 100));

pack('C*', @$dec) eq $text or die "Decoding failed!";
