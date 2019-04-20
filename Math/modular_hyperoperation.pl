#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 August 2016
# Edit: 20 April 2019
# https://github.com/trizen

# Generalized implementation of Knuth's up-arrow hyperoperation (modulo some m).

# See also:
#   https://en.wikipedia.org/wiki/Knuth%27s_up-arrow_notation

use 5.020;
use strict;
use warnings;

no warnings 'recursion';
use experimental qw(signatures);

use ntheory qw(powmod euler_phi forprimes);
use Memoize qw(memoize);

memoize('knuth');
memoize('hyper1');
memoize('hyper2');
memoize('hyper3');
memoize('hyper4');

sub hyper1 ($n, $k, $m) {
    powmod($n, $k, $m);
}

sub hyper2 ($n, $k, $m) {

    return 0 if ($m == 1);
    return 1 if ($k == 0);

    hyper1($n, hyper2($n, $k-1, euler_phi($m)), $m);
}

sub hyper3 ($n, $k, $m) {

    return 0 if ($m == 1);
    return 1 if ($k == 0);

    hyper2($n, hyper3($n, $k-1, euler_phi($m)), $m);
}

sub hyper4 ($n, $k, $m) {

    return 0 if ($m == 1);
    return 1 if ($k == 0);

    hyper3($n, hyper4($n, $k-1, euler_phi($m)), $m);
}

sub knuth ($k, $n, $g, $m) {

    $n >= 1 and $g == 0 and return 1;

    $n == 0 and return (($k * $g) % $m);
    $n == 1 and return hyper1($k, $g, $m);
    $n == 2 and return hyper2($k, $g, $m);
    $n == 3 and return hyper3($k, $g, $m);
    $n == 4 and return hyper4($k, $g, $m);

    knuth($k, $n - 1, knuth($k, $n, $g - 1, $m), $m);
}

my $m = 10**3;

foreach my $i (0 .. 6) {

    my $x = 1 + int(rand(100));
    my $y = 1 + int(rand(100));

    my $n = knuth($x, $i, $y, $m);
    printf("%5s %10s %5s = %5s   (mod %s)\n", $x, '^' x $i, $y, $n, $m);
}

say "\n=> Finding prime factors of 10∆10 + 23:";

forprimes {
    if (((knuth(10, 2, 10, $_) + 23) % $_) == 0) {
        printf("%6s | (10∆10 + 23)\n", $_);
    }
} 1e6;

__END__
   50               33 =   650   (mod 1000)
   94          ^    91 =   144   (mod 1000)
   14         ^^    36 =   336   (mod 1000)
   55        ^^^     5 =   375   (mod 1000)
   85       ^^^^    67 =   125   (mod 1000)
   32      ^^^^^    39 =   176   (mod 1000)
   84     ^^^^^^     4 =   816   (mod 1000)

=> Finding prime factors of 10∆10 + 23:
     2 | (10∆10 + 23)
     3 | (10∆10 + 23)
    13 | (10∆10 + 23)
   673 | (10∆10 + 23)
 18301 | (10∆10 + 23)
400109 | (10∆10 + 23)
