#!/usr/bin/perl

# Simple implementation of Pollard's p-1 integer factorization algorithm, with the B2 stage.

# See also:
#   https://en.wikipedia.org/wiki/Pollard%27s_p_%E2%88%92_1_algorithm
#   https://trizenx.blogspot.com/2019/08/special-purpose-factorization-algorithms.html

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory      qw(is_prime logint primes prime_iterator sqrtint next_prime);
use Math::AnyNum qw(:overload powmod gcd is_coprime mulmod);

sub pollard_pm1_factor ($n, $B1 = logint($n, 6)**3, $B2 = $B1 * logint($B1, 2)) {

    return () if $n <= 1;
    return $n if is_prime($n);
    return 2  if $n % 2 == 0;

    my $G = log($B1 * $B1);
    my $t = 2;

    foreach my $p (@{primes(2, sqrtint($B1))}) {
        for (1 .. int($G / log($p))) {
            $t = powmod($t, $p, $n);
        }
    }

    my $it = prime_iterator(sqrtint($B1) + 1);
    for (my $p = $it->() ; $p <= $B1 ; $p = $it->()) {
        $t = powmod($t, $p, $n);
        is_coprime($t - 1, $n) || return gcd($t - 1, $n);
    }

    my @table;
    my $Q  = next_prime($B1);
    my $TQ = powmod($t, $Q, $n);

    my $it2 = prime_iterator($Q + 1);
    for (my $p = $it2->() ; $p <= $B2 ; $p = $it2->()) {
        $TQ = mulmod($TQ, ($table[$p - $Q] //= powmod($t, $p - $Q, $n)), $n);
        is_coprime($TQ - 1, $n) || return gcd($TQ - 1, $n);
        $Q = $p;
    }

    return gcd($t - 1, $n);
}

say pollard_pm1_factor(1204123279);                                #=> 25889
say pollard_pm1_factor(83910721266759813859);                      #=> 4545646757
say pollard_pm1_factor(406816927495811038353579431);               #=> 9074269
say pollard_pm1_factor(38568900844635025971879799293495379321);    #=> 17495058332072672321
