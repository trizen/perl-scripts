#!/usr/bin/perl

# Translated by: Trizen
# Date: 27 April 2022
# https://github.com/trizen

# Fast algorithm for computing the binomial coefficient modulo some integer m.

# The implementation is based on Lucas' Theorem and its generalization given in the paper
# Andrew Granville "The Arithmetic Properties of Binomial Coefficients", In Proceedings of
# the Organic Mathematics Workshop, Simon Fraser University, December 12-14, 1995.

# Translation of binomod.gp v1.5 by Max Alekseyev, with some minor optimizations.

# See also:
#   https://home.gwu.edu/~maxal/gpscripts/

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use Math::AnyNum qw(ilog);
use experimental qw(signatures);

sub factorial_without_prime ($n, $p, $pk, $from, $count, $res) {
    return 1 if ($n <= 1);

    if ($p > $n) {
        return factorialmod($n, $pk);
    }

    if ($$from == $n) {
        return $$res;
    }

    if ($$from > $n) {
        $$from  = 0;
        $$count = 0;
        $$res   = 1;
    }

    my $r = $$res;
    my $t = $$count;

    foreach my $v ($$from + 1 .. $n) {
        if (++$t == $p) {
            $t = 0;
        }
        else {
            $r = mulmod($r, $v, $pk);
        }
    }

    $$res   = $r;
    $$count = $t;
    $$from  = $n;

    return $r;
}

sub lucas_theorem ($n, $k, $p) {    # p is prime

    my $r = 1;

    while ($k) {

        my $np = modint($n, $p);
        my $kp = modint($k, $p);

        if ($kp > $np) { return 0 }

        $r = (
              mulmod(
                     $r,
                     divmod(factorialmod($np, $p), mulmod(factorialmod($kp, $p), factorialmod(subint($np, $kp), $p), $p), $p),
                     $p
                    )
             );

        $n = divint($n, $p);
        $k = divint($k, $p);
    }

    return $r;
}

sub modular_binomial ($n, $k, $m) {

    if ($k < 0 or $m == 1) {
        return 0;
    }

    if ($n < 0) {
        return mulint(powint(-1, $k), __SUB__->(subint($k, $n) - 1, $k, $m));
    }

    if ($k > $n) {
        return 0;
    }

    if ($k == 0 or $k == $n) {
        return modint(1, $m);
    }

    if ($k == 1 or $k == subint($n, 1)) {
        return modint($n, $m);
    }

    my @F;

    foreach my $pp (factor_exp(absint($m))) {
        my ($p, $q) = @$pp;

        if ($q == 1) {
            push @F, [lucas_theorem($n, $k, $p), $p];
            next;
        }

        #my $d = logint($n, $p) + 1;        # incorrect for large p
        my $d = ilog($n, $p) + 1;

        my (@np, @kp);

        do {
            my $pi = 1;
            foreach my $i (0 .. $d) {
                push @np, modint(divint($n, $pi), $p);
                push @kp, modint(divint($k, $pi), $p);
                $pi = mulint($pi, $p);
            }
        };

        my @e;

        foreach my $i (0 .. $d) {
            $e[$i] = ($np[$i] < ($kp[$i] + (($i > 0) ? $e[$i - 1] : 0))) ? 1 : 0;
        }

        for (my $i = $d - 1 ; $i >= 0 ; --$i) {
            $e[$i] += $e[$i + 1];
        }

        if ($e[0] >= $q) {
            push @F, [0, powint($p, $q)];
            next;
        }

        my $rq = $q - $e[0];

        my $pq  = powint($p, $q);
        my $prq = powint($p, $rq);

        my (@N, @K, @R);

        do {
            my $pi = 1;
            my $r  = subint($n, $k);
            foreach my $i (0 .. $d) {
                push @N, modint(divint($n, $pi), $prq);
                push @K, modint(divint($k, $pi), $prq);
                push @R, modint(divint($r, $pi), $prq);
                $pi = mulint($pi, $p);
            }
        };

        my @NKR = (
                   sort { $a->[3] <=> $b->[3] }
                   map  { [$N[$_], $K[$_], $R[$_], $N[$_] + $K[$_] + $R[$_]] } 0 .. $#N
                  );

        @N = map { $_->[0] } @NKR;
        @K = map { $_->[1] } @NKR;
        @R = map { $_->[2] } @NKR;

        my @acc = (1);

        if ($prq < ~0 and $p < $n) {
            my $t = 0;
            foreach my $k (1 .. vecmin(vecmax(@N, @K, @R), 1e4)) {
                if (++$t == $p) {
                    push @acc, $acc[-1];
                    $t = 0;
                }
                else {
                    push @acc, mulmod($acc[-1], $k, $prq);
                }
            }
        }

        my $v = powmod($p, $e[0], $pq);

        do {
            my $from  = 0;
            my $count = 0;
            my $res   = 1;

            foreach my $j (0 .. $d) {

                my @pairs;
                my ($x, $y, $z);

                $x = $acc[$N[$j]] // push(@pairs, [\$x, $N[$j]]);
                $y = $acc[$K[$j]] // push(@pairs, [\$y, $K[$j]]);
                $z = $acc[$R[$j]] // push(@pairs, [\$z, $R[$j]]);

                foreach my $pair (sort { $a->[1] <=> $b->[1] } @pairs) {
                    ${$pair->[0]} = factorial_without_prime($pair->[1], $p, $prq, \$from, \$count, \$res);
                }

                $v = mulmod($v, divmod($x, mulmod($y, $z, $pq), $pq), $pq);
            }
        };

        if (($p > 2 or $rq < 3) and $q <= scalar(@e)) {
            $v = mulmod($v, powint(-1, $e[$rq - 1]), $pq);
        }

        push @F, [$v, $pq];
    }

    modint(chinese(@F), $m);
}

#
## Run some tests
#

use Test::More tests => 42;

is(modular_binomial(10, 2, 43), 2);
is(modular_binomial(10, 8, 43), 2);

is(modular_binomial(10, 2, 24), 21);
is(modular_binomial(10, 8, 24), 21);

is(modular_binomial(100, 42, -127), binomial(100, 42) % -127);

is(modular_binomial(12,    5,   100000),     792);
is(modular_binomial(16,    4,   100000),     1820);
is(modular_binomial(100,   50,  139),        71);
is(modular_binomial(1000,  10,  1243),       848);
is(modular_binomial(124,   42,  1234567),    395154);
is(modular_binomial(1e9,   1e4, 1234567),    833120);
is(modular_binomial(1e10,  1e5, 1234567),    589372);
is(modular_binomial(-1e10, 1e5, 4233330243), 2865877173);

is(modular_binomial(1e10, 1e4, factorial(13)), 1845043200);
is(modular_binomial(1e10, 1e5, factorial(13)), 1556755200);
is(modular_binomial(1e10, 1e6, factorial(13)), 5748019200);

is(modular_binomial(-1e10, 1e4, factorial(13)), 4151347200);
is(modular_binomial(-1e10, 1e5, factorial(13)), 1037836800);
is(modular_binomial(-1e10, 1e6, factorial(13)), 2075673600);

is(modular_binomial(3, 1, 9),  binomial(3, 1) % 9);
is(modular_binomial(4, 1, 16), binomial(4, 1) % 16);

is(modular_binomial(1e9,  1e5, 43 * 97 * 503),         585492);
is(modular_binomial(1e9,  1e6, 5041689707),            15262431);
is(modular_binomial(1e7,  1e5, 43**2 * 97**3 * 13**4), 1778017500428);
is(modular_binomial(1e7,  1e5, 42**2 * 97**3 * 13**4), 10015143223176);
is(modular_binomial(1e9,  1e5, 12345678910),           4517333900);
is(modular_binomial(1e9,  1e6, 13**2 * 5**6),          2598375);
is(modular_binomial(1e10, 1e5, 1234567),               589372);

is(modular_binomial(1e5,     1e3, 43),                 binomial(1e5,     1e3) % 43);
is(modular_binomial(1e5,     1e3, 43 * 97),            binomial(1e5,     1e3) % (43 * 97));
is(modular_binomial(1e5,     1e3, 43 * 97 * 43),       binomial(1e5,     1e3) % (43 * 97 * 43));
is(modular_binomial(1e5,     1e3, 43 * 97 * (5**5)),   binomial(1e5,     1e3) % (43 * 97 * (5**5)));
is(modular_binomial(1e5,     1e3, next_prime(1e4)**2), binomial(1e5,     1e3) % next_prime(1e4)**2);
is(modular_binomial(1e5,     1e3, next_prime(1e4)),    binomial(1e5,     1e3) % next_prime(1e4));
is(modular_binomial(1e6,     1e3, next_prime(1e5)),    binomial(1e6,     1e3) % next_prime(1e5));
is(modular_binomial(1e6,     1e3, next_prime(1e7)),    binomial(1e6,     1e3) % next_prime(1e7));
is(modular_binomial(1234567, 1e3, factorial(20)),      binomial(1234567, 1e3) % factorial(20));
is(modular_binomial(1234567, 1e4, factorial(20)),      binomial(1234567, 1e4) % factorial(20));

is(modular_binomial(1e6, 1e3, powint(2, 128) + 1), binomial(1e6, 1e3) % (powint(2, 128) + 1));
is(modular_binomial(1e6, 1e3, powint(2, 128) - 1), binomial(1e6, 1e3) % (powint(2, 128) - 1));

is(modular_binomial(1e6, 1e4, (powint(2, 128) + 1)**2), binomial(1e6, 1e4) % ((powint(2, 128) + 1)**2));
is(modular_binomial(1e6, 1e4, (powint(2, 128) - 1)**2), binomial(1e6, 1e4) % ((powint(2, 128) - 1)**2));

say("binomial(10^10, 10^5) mod 13! = ", modular_binomial(1e10, 1e5, factorial(13)));

__END__
foreach my $n (0 .. 50) {
    foreach my $k (0 .. $n) {
        foreach my $m (1 .. 50) {
            say "Testing: binomial($n, $k, $m)";
            is(modular_binomial($n, $k, $m), binomial($n, $k) % $m);
        }
    }
}
