#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 01 June 2022
# https://github.com/trizen

# Concept for an integer factorization method based on the Chinese Remainder Theorem (CRT).

# Example:
#   n = 43*97

# We have:
#   n == 1 mod 2
#   n == 1 mod 3
#   n == 1 mod 5
#   n == 6 mod 7
#   n == 2 mod 11

# 43 = chinese(Mod(1,2), Mod(1,3), Mod(3,5), Mod(1,7))
# 97 = chinese(Mod(1,2), Mod(1,3), Mod(2,5), Mod(6,7))

# For some small primes p, we try to find pairs of a and b, such that:
#   a*b == n mod p

# Then using either the `a` or the `b` values, we can construct a factor of n, using the CRT.

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);
use Math::GMPz;

sub CRT_factor ($n) {

    return $n if is_prime($n);

    my $congruences = [0];

    my $LCM   = 1;
    my $limit = vecmin(sqrtint($n), 1e6);

    for (my $p = 2 ; $p <= $limit ; $p = next_prime($p)) {

        my $r = modint($n, $p);

        if ($r == 0) {
            return $p;
        }

        my @new_congruences;

        foreach my $c (@$congruences) {
            foreach my $d (1 .. $p - 1) {
                my $t = [$d, $p];

                my $z = chinese([$c, $LCM], $t);
                my $g = gcd($z, $n);

                if ($g > 1 and $g < $n) {
                    return $g;
                }

                push @new_congruences, $z;
            }
        }

        $LCM         = lcm($LCM, $p);
        $congruences = \@new_congruences;
    }

    return 1;
}

say CRT_factor(43 * 97);      #=> 97
say CRT_factor(503 * 863);    #=> 863

say CRT_factor(Math::GMPz->new(2)**32 + 1);    #=> 641
say CRT_factor(Math::GMPz->new(2)**64 + 1);    #=> 274177

say CRT_factor(Math::GMPz->new("273511610089"));      #=> 377827
say CRT_factor(Math::GMPz->new("24259337155997"));    #=> 5944711
