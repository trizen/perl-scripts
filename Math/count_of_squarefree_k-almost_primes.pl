#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 March 2021
# https://github.com/trizen

# Count the number of squarefree k-almost primes <= n.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub squarefree_almost_prime_count ($n, $k) {

    if ($k == 1) {
        return prime_count($n);
    }

    my $count = 0;

    sub ($m, $p, $k, $j = 0) {

        my $s = rootint(divint($n, $m), $k);

        if ($k == 2) {

            foreach my $q (@{primes($p, $s)}) {

                ++$j;

                if (modint($m, $q) != 0) {
                    $count += prime_count(divint($n, mulint($m, $q))) - $j;
                }
            }

            return;
        }

        foreach my $p (@{primes($p, $s)}) {
            if (modint($m, $p) != 0) {
                __SUB__->(mulint($m, $p), $p, $k - 1, $j);
            }
            ++$j;
        }
    }->(1, 2, $k);

    return $count;
}

# Run some tests

foreach my $k (1 .. 7) {

    my $upto = pn_primorial($k) + int(rand(1e5));

    my $x = squarefree_almost_prime_count($upto, $k);
    my $y = scalar grep { is_square_free($_) } @{almost_primes($k, $upto)};

    say "Testing: $k with n = $upto -> $x";

    $x == $y
      or die "Error: $x != $y";
}

say '';

foreach my $k (1 .. 8) {
    say("Count of squarefree $k-almost primes for 10^n: ", join(', ', map { squarefree_almost_prime_count(10**$_, $k) } 0 .. 9));
}

__END__
Count of squarefree 1-almost primes for 10^n: 0, 4, 25, 168, 1229, 9592, 78498, 664579, 5761455, 50847534
Count of squarefree 2-almost primes for 10^n: 0, 2, 30, 288, 2600, 23313, 209867, 1903878, 17426029, 160785135
Count of squarefree 3-almost primes for 10^n: 0, 0, 5, 135, 1800, 19919, 206964, 2086746, 20710806, 203834084
Count of squarefree 4-almost primes for 10^n: 0, 0, 0, 16, 429, 7039, 92966, 1103888, 12364826, 133702610
Count of squarefree 5-almost primes for 10^n: 0, 0, 0, 0, 24, 910, 18387, 286758, 3884936, 48396263
Count of squarefree 6-almost primes for 10^n: 0, 0, 0, 0, 0, 20, 1235, 32396, 605939, 9446284
Count of squarefree 7-almost primes for 10^n: 0, 0, 0, 0, 0, 0, 8, 1044, 38186, 885674
Count of squarefree 8-almost primes for 10^n: 0, 0, 0, 0, 0, 0, 0, 1, 516, 29421
