#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 March 2018
# https://github.com/trizen

# A hybrid factorization algorithm, using:
#   * Pollard's p-1 algorithm
#   * Pollard's rho algorithm
#   * A simple version of the continued-fraction factorization method
#   * Fermat's factorization method

# See also:
#   https://en.wikipedia.org/wiki/Quadratic_sieve
#   https://en.wikipedia.org/wiki/Dixon%27s_factorization_method
#   https://en.wikipedia.org/wiki/Fermat%27s_factorization_method
#   https://en.wikipedia.org/wiki/Pollard%27s_p_%E2%88%92_1_algorithm

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use ntheory qw(is_prime random_prime vecprod);

use Math::AnyNum qw(
    gcd valuation powmod irand ipow
    isqrt idiv is_square next_prime
);

sub fermat_hybrid_factorization ($n) {

    return ()   if $n <= 1;
    return ($n) if is_prime($n);

    # Test for divisibility by 2
    if (!($n & 1)) {

        my $v = valuation($n, 2);
        my $t = $n >> $v;

        my @factors = (2) x $v;

        if ($t > 1) {
            push @factors, __SUB__->($t);
        }

        return @factors;
    }

    my $p = isqrt($n);
    my $x = $p;
    my $q = ($p * $p - $n);

    my $t = 1;
    my $h = 1;
    my $z = Math::AnyNum->new(random_prime($n));

    my $g = 1;
    my $c = $q + $p;

    my $a0 = 1;
    my $a1 = ($a0 * $a0 + $c);
    my $a2 = ($a1 * $a1 + $c);

    my $c1 = $p;
    my $c2 = 1;

    my $r = $p + $p;

    my ($e1, $e2) = (1, 0);
    my ($f1, $f2) = (0, 1);

    while (not is_square($q)) {

        $q += 2 * $p++ + 1;

        # Pollard's rho algorithm
        $g = gcd($n, $a2 - $a1);

        if ($g > 1 and $g < $n) {
            return sort { $a <=> $b } (
                __SUB__->($g),
                __SUB__->($n / $g),
            );
        }

        $a1 = (($a1 * $a1 + $c) % $n);
        $a2 = (($a2 * $a2 + $c) % $n);
        $a2 = (($a2 * $a2 + $c) % $n);

        # Simple version of the continued-fraction factorization method.
        # Efficient for numbers that have factors relatively close to sqrt(n)
        $c1 = $r * $c2 - $c1;
        $c2 = idiv($n - $c1 * $c1, $c2);

        my $x1 = ($x * $f2 + $e2) % $n;
        my $y1 = ($x1 * $x1) % $n;

        if (is_square($y1)) {
            $g = gcd($x1 - isqrt($y1), $n);

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n / $g),
                );
            }
        }

        $r = idiv($x + $c1, $c2);

        ($f1, $f2) = ($f2, ($r * $f2 + $f1) % $n);
        ($e1, $e2) = ($e2, ($r * $e2 + $e1) % $n);

        # Pollard's p-a algorithm (random variation)
        $t = $z;
        $h = next_prime($h);
        $z = powmod($z, $h, $n);
        $g = gcd($z * powmod($t, irand($n), $n) - 1, $n);

        if ($g > 1) {

            if ($g == $n) {
                $h = 1;
                $z = Math::AnyNum->new(random_prime($n));
                next;
            }

            return sort { $a <=> $b } (
                __SUB__->($g),
                __SUB__->($n / $g),
            );
        }
    }

    # Fermat's method
    my $s = isqrt($q);

    return sort { $a <=> $b } (
        __SUB__->($p + $s),
        __SUB__->($p - $s),
    );
}

my @tests = map { Math::AnyNum->new($_) } qw(
     160587846247027 5040 65127835124 6469693230
     12129569695640600539 38568900844635025971879799293495379321
     5057557777500469647488909553014309710588182149566739774380944488183531188525863600127265768146701283
);

foreach my $n (@tests) {

    my @f = fermat_hybrid_factorization($n);

    say "$n = ", join(' * ', @f);
    die 'error' if vecprod(@f) != $n;
    die 'error' if grep { !is_prime($_) } @f;
}

say "\n=> Factoring 2^k+1";

foreach my $k (1 .. 100) {

    my $n = ipow(2, $k) + 1;
    my @f = fermat_hybrid_factorization($n);

    say "2^$k + 1 = ", join(' * ', @f);
    die 'error' if vecprod(@f) != $n;
    die 'error' if grep { !is_prime($_) } @f;
}

# Test the continued-fraction method with factors relatively close to sqrt(n)
foreach my $k (1 .. 100) {

    my $p = random_prime(ipow(2, 100 + $k));
    my $n = next_prime($p + irand(10**15)) * $p;
    my @f = fermat_hybrid_factorization($n);

    #say join(' * ', @f), " = $n";
    die 'error' if vecprod(@f) != $n;
    die 'error' if grep { !is_prime($_) } @f;
}

# Test for small numbers
for my $n (1 .. 1000) {

    my @f = fermat_hybrid_factorization($n);

    die 'error' if vecprod(@f) != $n;
    die 'error' if grep { !is_prime($_) } @f;
}
