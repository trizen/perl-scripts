#!/usr/bin/perl

# Simple implementation of Dirichlet's hyperbola method.

# Useful to compute partial sums of in sublinear time:
#   Sum_{d|n} g(d) * h(n/d)

# See also:
#   https://en.wikipedia.org/wiki/Dirichlet_hyperbola_method

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use Math::AnyNum qw(faulhaber_sum);
use experimental qw(signatures);

sub dirichlet_hyperbola_method ($n, $g, $h, $G, $H) {

    my $s = sqrtint($n);

    my $A = 0;
    my $B = 0;
    my $C = 0;

    foreach my $k (1 .. $s) {

        my $gk = $g->($k);
        my $hk = $h->($k);

        $A += $gk * $H->(divint($n, $k));
        $A += $hk * $G->(divint($n, $k));

        $B += $gk;
        $C += $hk;
    }

    $A - $B * $C;
}

sub g ($n) { $n }
sub h ($n) { moebius($n) }

sub G ($n) { faulhaber_sum($n, 1) }    # partial sums of g(n): Sum_{k=1..n} g(k)
sub H ($n) { mertens($n) }             # partial sums of h(n): Sum_{k=1..n} h(k)

foreach my $n (1 .. 8) {
    say "S(10^$n) = ", dirichlet_hyperbola_method(powint(10, $n), \&g, \&h, \&G, \&H);
}

__END__
S(10^1) = 32
S(10^2) = 3044
S(10^3) = 304192
S(10^4) = 30397486
S(10^5) = 3039650754
S(10^6) = 303963552392
S(10^7) = 30396356427242
S(10^8) = 3039635516365908
