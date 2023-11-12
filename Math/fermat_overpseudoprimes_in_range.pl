#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 06 September 2022
# https://github.com/trizen

# Generate all the k-omega Fermat overpseudoprimes to a given base in a given range [a,b]. (not in sorted order)

# Definition:
#   k-omega primes are numbers n such that omega(n) = k.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Prime_omega_function
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);
use Memoize      qw(memoize);

memoize('inverse_znorder_primes');

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub inverse_znorder_primes ($base, $lambda) {
    my %seen;
    grep { !$seen{$_}++ } factor(subint(powint($base, $lambda), 1));
}

sub iterate_over_primes ($x, $y, $base, $lambda, $callback) {

    if ($lambda > 1 and $lambda <= 100) {
        foreach my $p (inverse_znorder_primes($base, $lambda)) {

            next if $p < $x;
            last if $p > $y;

            znorder($base, $p) == $lambda or next;

            $callback->($p);
        }
        return;
    }

    if ($lambda > 1) {
        for (my $w = $lambda * divceil($x - 1, $lambda) ; $w <= $y ; $w += $lambda) {
            if (is_prime($w + 1) and powmod($base, $lambda, $w + 1) == 1) {
                $callback->($w + 1);
            }
        }
        return;
    }

    for (my $p = (is_prime($x) ? $x : next_prime($x)) ; $p <= $y ; $p = next_prime($p)) {
        $callback->($p);
    }
}

sub fermat_overpseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    my $F;
    $F = sub ($m, $lambda, $lo, $j) {

        my $hi = rootint(divint($B, $m), $j);

        $lo > $hi and return;

        iterate_over_primes($lo, $hi, $base, $lambda, sub ($p) {
            if ($base % $p != 0) {

                for (my ($q, $v) = ($p, $m * $p) ; $v <= $B ; ($q, $v) = ($q * $p, $v * $p)) {

                    my $z = znorder($base, $q);
                    if ($lambda > 1) {
                        $lambda == $z or last;
                    }
                    gcd($v, $z) == 1 or last;

                    if ($j == 1) {
                        $v >= $A or next;
                        $k == 1 and is_prime($v) and next;
                        ($v - 1) % $z == 0 or next;
                        $callback->($v);
                        next;
                    }

                    $F->($v, $z, $p + 1, $j - 1);
                }
            }
        });
    };

    $F->(1, 1, 2, $k);
    undef $F;
}

# Generate all the Fermat overpseudoprimes to base 2 in the range [1, 1325843]

my $from = 1;
my $upto = 1325843;
my $base = 2;

my @arr;
foreach my $k (1 .. 100) {
    last if pn_primorial($k) > $upto;
    fermat_overpseudoprimes_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });
}

say join(', ', sort { $a <=> $b } @arr);

__END__
2047, 3277, 4033, 8321, 65281, 80581, 85489, 88357, 104653, 130561, 220729, 253241, 256999, 280601, 390937, 458989, 486737, 514447, 580337, 818201, 838861, 877099, 916327, 976873, 1016801, 1082401, 1145257, 1194649, 1207361, 1251949, 1252697, 1325843
