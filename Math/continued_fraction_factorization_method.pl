#!/usr/bin/perl

# A simple implementation of the continued fraction factorization method,
# combined with modular arithmetic (variation of the Brillhart-Morrison algorithm).

# See also:
#   https://en.wikipedia.org/wiki/Continued_fraction_factorization

# Parts of code inspired by:
#    https://github.com/martani/Quadratic-Sieve

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use List::Util qw(first);
use ntheory qw(is_prime factor_exp prime_count vecprod);
use Math::AnyNum qw(is_square isqrt irand idiv gcd valuation getbit setbit);

use constant { ONE => Math::AnyNum->new(1) };

sub gaussian_elimination ($rows, $n) {

    my @A = @$rows;
    my $m = $#A;
    my @I = map { ONE << $_ } 0 .. $m;

    my $nrow = -1;
    my $mcol = $m < $n ? $m : $n;

    foreach my $col (0 .. $mcol) {
        my $npivot = -1;

        foreach my $row ($nrow + 1 .. $m) {
            if (getbit($A[$row], $col)) {
                $npivot = $row;
                $nrow++;
                last;
            }
        }

        next if ($npivot == -1);

        if ($npivot != $nrow) {
            @A[$npivot, $nrow] = @A[$nrow, $npivot];
            @I[$npivot, $nrow] = @I[$nrow, $npivot];
        }

        foreach my $row ($nrow + 1 .. $m) {
            if (getbit($A[$row], $col)) {
                $A[$row] ^= $A[$nrow];
                $I[$row] ^= $I[$nrow];
            }
        }
    }

    return (\@A, \@I);
}

sub exponents_signature (@factors) {
    my $sig = 0;

    foreach my $p (@factors) {
        if ($p->[1] & 1) {
            $sig = setbit($sig, prime_count($p->[0]) - 1);
        }
    }

    return $sig;
}

sub cffm ($n) {

    # Check for primes and negative numbers
    return ()   if $n <= 1;
    return ($n) if is_prime($n);

    # Check for perfect squares
    if (is_square($n)) {
        my @factors = __SUB__->(isqrt($n));
        return sort { $a <=> $b } ((@factors) x 2);
    }

    # Check for divisibility by 2
    if (!($n & 1)) {

        my $v = valuation($n, 2);
        my $t = $n >> $v;

        my @factors = (2) x $v;

        if ($t > 1) {
            push @factors, __SUB__->($t);
        }

        return @factors;
    }

    my $x = isqrt($n);
    my $y = $x;
    my $z = 1;

    my $w = $x+$x;
    my $r = $w;

    my ($e1, $e2) = (1, 0);
    my ($f1, $f2) = (0, 1);

    my (@A, @Q);

    my $B = 2 * int(exp(sqrt(log($n) * log(log($n))) / 2));    # B-smooth limit
    my $L = prime_count($B) + int(log($n));                    # maximum number of matrix-rows

    do {

        $y = $r * $z - $y;
        $z = idiv($n - $y * $y, $z);
        $r = idiv($x + $y, $z);

        my $u = ($x * $f2 + $e2) % $n;
        my $v = ($u * $u) % $n;
        my $c = ($v > $w ? $n - $v : $v);

        if (is_square($c)) {
            my $g = gcd($u - isqrt($c), $n);

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n / $g)
                );
            }
        }

        my @factors = factor_exp($c);

        if (@factors and $factors[-1][0] <= $B) {
            push @A, exponents_signature(@factors);
            push @Q, [$u, $c];
        }

        ($f1, $f2) = ($f2, ($r * $f2 + $f1) % $n);
        ($e1, $e2) = ($e2, ($r * $e2 + $e1) % $n);

    } while ($z > 1 and @A <= $L);

    if (@A < $L) {
        push @A, (0) x ($L - @A + 1);
    }

    my ($A, $I) = gaussian_elimination(\@A, $L - 1);

    my $LR = ((first { $A->[-$_] } 1 .. @$A) // 0) - 1;

    foreach my $solution (@{$I}[@$I - $LR .. $#$I]) {

        my $solution_A = 1;
        my $solution_B = 1;
        my $solution_X = 1;
        my $solution_Y = 1;

        foreach my $i (0 .. $#Q) {

            getbit($solution, $i) || next;

            ($solution_A *= $Q[$i][0]) %= $n;
            ($solution_B *= $Q[$i][0]);

            ($solution_X *= $Q[$i][1]) %= $n;
            ($solution_Y *= $Q[$i][1]);

            foreach my $pair (
                [$solution_A, $solution_X],
                [$solution_A, $solution_Y],
                [$solution_B, $solution_X],
                [$solution_B, $solution_Y],
            ) {
                my ($X, $Y) = @$pair;
                my $g = gcd($X - isqrt($Y), $n);

                if ($g > 1 and $g < $n) {
                    return sort { $a <=> $b } (
                        __SUB__->($g),
                        __SUB__->($n / $g)
                    );
                }
            }
        }
    }

    return ($n);
}

foreach my $k (2 .. 60) {

    my $n = irand(2, 1 << $k);
    my @f = cffm($n);

    if (grep { !is_prime($_) } @f) {
        say "$n = ", join(' * ', @f), ' (incomplete factorization)';
    }
    else {
        say "$n = ", join(' * ', @f);
    }

    die 'error' if vecprod(@f) != $n;
}
