#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 April 2018
# https://github.com/trizen

# A simple factorization algorithm, based on ideas from the continued fraction factorization method.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use ntheory qw(is_prime factor_exp vecprod);
use Math::AnyNum qw(is_square isqrt irand idiv gcd valuation);

sub pell_cfrac ($n) {

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

    my $r = $x + $x;

    my ($e1, $e2) = (1, 0);
    my ($f1, $f2) = (0, 1);

    my %table;

    for (; ;) {

        $y = $r * $z - $y;
        $z = idiv($n - $y * $y, $z);
        $r = idiv($x + $y, $z);

        my $u = ($x * $f2 + $e2) % $n;
        my $v = ($u * $u) % $n;

        my $c = ($v > $w ? $n - $v : $v);

        # Congruence of squares
        if (is_square($c)) {
            my $g = gcd($u - isqrt($c), $n);

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n / $g)
                );
            }
        }

        my @factors    = factor_exp($c);
        my @odd_powers = grep { $factors[$_][1] % 2 == 1 } 0 .. $#factors;

        if (@odd_powers <= 3) {
            my $key = join(' ', map { $_->[0] } @factors[@odd_powers]);

            # Congruence of squares by creating a square from previous terms
            if (exists $table{$key}) {
                foreach my $d (@{$table{$key}}) {

                    my $g = gcd($d->{u} * $u - isqrt($d->{c} * $c), $n);

                    if ($g > 1 and $g < $n) {
                        return sort { $a <=> $b } (
                            __SUB__->($g),
                            __SUB__->($n / $g)
                        );
                    }
                }
            }

            push @{$table{$key}}, {c => $c, u => $u};
        }

        ($f1, $f2) = ($f2, ($r * $f2 + $f1) % $n);
        ($e1, $e2) = ($e2, ($r * $e2 + $e1) % $n);

        # Pell factorization
        foreach my $t (
            $e2 + $e2 + $f2 + $x,
            $e2 + $f2 + $f2,
            $e2 + $f2 * $x,
            $e2 + $f2,
            $e2,
        ) {
            my $g = gcd($t, $n);

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n / $g)
                );
            }
        }
    }
}

foreach my $k (2 .. 60) {

    my $n = irand(2, 1 << $k);
    my @f = pell_cfrac($n);

    say "$n = ", join(' * ', @f);

    die 'error' if grep { !is_prime($_) } @f;
    die 'error' if vecprod(@f) != $n;
}
