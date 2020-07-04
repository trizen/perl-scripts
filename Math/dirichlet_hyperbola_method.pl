#!/usr/bin/perl

# Simple implementation of Dirichlet's hyperbola method.

# Useful to compute partial sums of in sublinear time:
#   Sum_{d|n} g(d) * h(n/d)

# See also:
#   https://en.wikipedia.org/wiki/Dirichlet_hyperbola_method

use 5.020;
use strict;
use warnings;

use ntheory qw(sqrtint moebius);
use experimental qw(signatures);

sub dirichlet_hyperbola_method ($n, $g, $h) {

    my $s = sqrtint($n);

    my $A = 0;
    my $B = 0;
    my $C = 0;

    foreach my $k (1 .. $s) {

        my $H = 0;
        my $G = 0;

        foreach my $j (1 .. int($n / $k)) {
            $H += $h->($j);
            $G += $g->($j);
        }

        my $gk = $g->($k);
        my $hk = $h->($k);

        $A += $gk * $H;
        $A += $hk * $G;

        $B += $gk;
        $C += $hk;
    }

    $A - $B * $C;
}

sub g($n) { $n }
sub h($n) { moebius($n) }

say join(', ', map { dirichlet_hyperbola_method($_, \&g, \&h) } 0 .. 20);

__END__
0, 1, 2, 4, 6, 10, 12, 18, 22, 28, 32, 42, 46, 58, 64, 72, 80, 96, 102, 120, 128
