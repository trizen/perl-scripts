#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 August 2016
# License: GPLv3
# https://github.com/trizen

# Generalized implementation of Knuth's up-arrow hyperoperation (modulo some n).

# See also:
#   https://en.wikipedia.org/wiki/Knuth%27s_up-arrow_notation

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

use ntheory qw(powmod);
use Memoize qw(memoize);

memoize('knuth');
memoize('hyper1');
memoize('hyper2');
memoize('hyper3');
memoize('hyper4');

my $mod = 10**3;

sub hyper1 {
    my ($n, $k) = @_;
    powmod($n, $k, $mod);
}

sub hyper2 {
    my ($n, $k) = @_;
    $k <= 1 && return $n;
    hyper1($n, hyper2($n, $k - 1));
}

sub hyper3 {
    my ($n, $k) = @_;
    $k <= 1 && return $n;
    hyper2($n, hyper3($n, $k - 1));
}

sub hyper4 {
    my ($n, $k) = @_;
    $k <= 1 && return $n;
    hyper3($n, hyper4($n, $k - 1));
}

sub knuth {
    my ($k, $n, $g) = @_;

    $k %= $mod;
    $g %= $mod;

    $n >= 1 && $g == 0 && return 1;

    $n == 0 && return (($k * $g) % $mod);
    $n == 1 && return (hyper1($k, $g));
    $n == 2 && return (hyper2($k, $g));
    $n == 3 && return (hyper3($k, $g));
    $n == 4 && return (hyper4($k, $g));

    knuth($k, $n - 1, knuth($k, $n, $g - 1));
}

foreach my $i (0 .. 6) {
    my $x = 1 + int(rand(100));
    my $y = 1 + int(rand(100));

    my $n = knuth($x, $i, $y);
    printf("%5s %10s %5s = %5s   (mod %s)\n", $x, '^' x $i, $y, $n, $mod);
}
