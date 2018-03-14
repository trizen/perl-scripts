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
use ntheory qw(is_prime factor_exp random_prime prime_count vecprod);
use Math::AnyNum qw(:overload is_square isqrt irand idiv gcd valuation);

sub getbit ($n, $k) {
    ($n >> $k) & 1;
}

sub setbit ($n, $k) {
    (1 << $k) | $n;
}

sub gaussian_elimination ($rows, $n) {

    my @A = @$rows;
    my $m = $#A;
    my @I = map { 1 << $_ } 0 .. $m;

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
    my $w = 2 * $x;

    my ($e1, $e2) = (1, 0);
    my ($f1, $f2) = (0, 1);

    my (@A, @Q, %S);

    my $L = 500;    # maximum number of matrix-rows
    my $B = 100;    # B-smooth limit

    my $pi_B = prime_count($B);

    do {

        $y = idiv($x + $y,      $z) * $z - $y;
        $z = idiv($n - $y * $y, $z);

        my $u = ($x * $f2 + $e2) % $n;
        my $v = ($u * $u - $n * $f2 * $f2) % $n;

        if (exists $S{$v}) {
            my $g = gcd($v - $u * $S{$v}, $n);

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n / $g),
                );
            }

            $S{$v} = $u;
        }
        else {
            $S{$v} = $u;
        }

        if (is_square($v)) {
            my $g = gcd(isqrt($v) - $u, $n);

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n / $g),
                );
            }
        }

        my $c = ($v > $w ? $n - $v : $v);
        my @factors = factor_exp($c);

        if (@factors and $factors[-1][0] <= $B) {
            push @A, exponents_signature(@factors);
            push @Q, [$u, $v];
        }

        my $r = idiv($x + $y, $z);

        ($f1, $f2) = ($f2, ($r * $f2 + $f1) % $n);
        ($e1, $e2) = ($e2, ($r * $e2 + $e1) % $n);

    } while ($z > 1 and @A < $L);

    if (@A < $pi_B) {
        push @A, (0) x ($pi_B - @A + 1);
    }

    my ($A, $I) = gaussian_elimination(\@A, $pi_B - 1);

    my $LR = (first { $A->[-$_] } 1 .. @$A) - 1;

    foreach my $solution (@{$I}[@$I - $LR .. $#$I]) {

        my $solution_X = 1;
        my $solution_Y = 1;

        foreach my $i (0 .. $#Q) {

            getbit($solution, $i) || next;

            ($solution_X *= $Q[$i][0]) %= $n;
            ($solution_Y *= $Q[$i][1]) %= $n;

            is_square($solution_Y) || next;

            my $g = gcd(isqrt($solution_Y) + $solution_X, $n);

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n / $g),
                );
            }
        }
    }

    return ($n);
}

say join ' ', cffm(50754640);
say join ' ', cffm(4882742467);
say join ' ', cffm(25570266803);
say join ' ', cffm(2**62 - 1);
say join ' ', cffm(2758006706116313);

say '';

foreach my $k (2 .. 20) {

    my $n = irand(2, 1 << $k) * random_prime(1 << $k) * random_prime(1 << $k);
    my @f = cffm($n);

    if (grep { !is_prime($_) } @f) {
        say "$n = ", join(' * ', @f), ' (incomplete factorization)';
    }
    else {
        say "$n = ", join(' * ', @f);
    }

    die 'error' if vecprod(@f) != $n;
}
