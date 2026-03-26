#!/usr/bin/perl

# Pollard-Strassen O(n^(1/4)) factorization algorithm.

# Illustrated by David Harvey in the following video:
#   https://yewtu.be/watch?v=_53s-0ZLxbQ

use 5.020;
use warnings;

use bigint try => 'GMP';
use experimental qw(signatures);
use ntheory      qw(random_prime rootint gcd);

use Math::Polynomial;
use Math::ModInt qw(mod);
use Math::Polynomial::ModInt;

sub pollard_strassen_factorization ($n, $d = 1 + rootint($n, 4), $tries = $d) {

    my $a = random_prime($n);

    my @baby_steps;

    my $bs = mod(1, $n);
    foreach my $k (1 .. $d) {
        push @baby_steps, $bs;
        $bs *= $a;
    }

    my $x = Math::Polynomial::ModInt->new(mod(0, $n), mod(1, $n));
    my @f = map { $x - $_ } @baby_steps;

    # --- Divide-and-Conquer Polynomial Multiplication ---
    while (@f > 1) {
        my @next_level;

        # Multiply adjacent pairs in the current level
        while (@f >= 2) {
            my $p1 = shift @f;
            my $p2 = shift @f;
            push @next_level, $p1->mul($p2);
        }

        # If there's an odd polynomial left over, promote it to the next level
        push @next_level, shift @f if @f;

        @f = @next_level;
    }

    # Extract the final product, or return a constant polynomial of 1 if empty
    my $f = @f ? $f[0] : Math::Polynomial::ModInt->new(mod(1, $n));

    my $r = mod($a, $n);

    foreach my $k (1 .. $tries) {

        my $b = $r**($k * $d);
        my $v = $f->evaluate($b)->residue;
        my $g = gcd($v, $n);

        if ($g > 1 and $g < $n) {
            return $g;
        }
    }

    return 1;
}

say pollard_strassen_factorization(1207);
say pollard_strassen_factorization(503 * 863);
say pollard_strassen_factorization(2**64 + 1, 300, 5 * 300);
