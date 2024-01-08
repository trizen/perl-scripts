#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 October 2019
# https://github.com/trizen

# Generalization of the elementary cellular automaton, by using `n` color-states and looking at `k` neighbors left-to-right.

# For example, a value of `n = 3` and `k = 2` uses three different color-states and looks at 2 neighbors to the left and 2 neighbors to the right.

# See also:
#   https://en.wikipedia.org/wiki/Cellular_automaton
#   https://en.wikipedia.org/wiki/Elementary_cellular_automaton
#   https://rosettacode.org/wiki/Elementary_cellular_automaton

# YouTube lectures:
#   https://www.youtube.com/watch?v=S3tYzCPuVsA
#   https://www.youtube.com/watch?v=pGGIE5uhPRQ

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);
use Algorithm::Combinatorics qw(variations_with_repetition);

sub automaton ($n, $k, $rule, $callback, $iter = 50, $cells = [1]) {

    my @states = variations_with_repetition([0 .. $n - 1], 2 * $k + 1);
    my @digits = reverse todigits($rule, $n);

    my @lookup;

    foreach my $i (0 .. $#states) {
        $lookup[fromdigits($states[$i], $n)] = $digits[$i] // 0;
    }

    my @padding         = (0) x (($iter - scalar(@$cells)) >> 1);
    my @cells           = (@padding, @$cells, @padding);
    my @neighbors_range = (-$k .. $k);

    my $len = scalar(@cells);

    for (1 .. ($iter >> 1)) {
        $callback->(@cells);
        @cells = @lookup[map {
            my $i = $_; fromdigits([map { $cells[($i + $_) % $len] } @neighbors_range], $n)
        } 0 .. $#cells];
    }

    return @cells;
}

my @chars = (' ', '*', '.', '#');

say "\n=> 2x1 Automaton";

automaton(2, 1, 90, sub (@row) {
    say join '', map { $chars[$_] } @row;
});

say "\n=> 3x1 Automaton";

automaton(3, 1, "843693805713", sub (@row) {
    say join '', map { $chars[$_] } @row;
});

say "\n=> 3x2 Automaton";

automaton(3, 2, "590193390821886729275563552433397050190", sub (@row) {
    say join '', map { $chars[$_] } @row;
}, 80);
