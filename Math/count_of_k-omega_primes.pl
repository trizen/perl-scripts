#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 March 2021
# https://github.com/trizen

# Count the number of k-omega primes <= n.

# Definition:
#   k-omega primes are numbers n such that omega(n) = k.

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://en.wikipedia.org/wiki/Prime_omega_function

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub omega_prime_count_rec ($n, $k = 1) {

    if ($k == 1) {
        return prime_power_count($n);
    }

    my $count = 0;

    sub ($m, $p, $k, $s = rootint(divint($n, $m), $k), $j = 1) {

        if ($k == 2) {

            for (my $q = $p ; $q <= $s ; ++$j, ($q = next_prime($q))) {

                if (modint($m, $q) == 0) {
                    next;
                }

                for (my $t = mulint($m, $q) ; $t <= $n ; $t = mulint($t, $q)) {

                    my $w = divint($n, $t);

                    if ($q > $w) {
                        last;
                    }

                    $count += prime_count($w) - $j;

                    for (my $r = $q ; $r <= $w ; $r = next_prime($r)) {

                        my $u = vecprod($t, $r, $r);

                        if ($u > $n) {
                            last;
                        }

                        if (modint($t, $r) == 0) {
                            next;
                        }

                        for (; $u <= $n ; $u = mulint($u, $r)) {
                            ++$count;
                        }
                    }
                }
            }

            return;
        }

        for (; $p <= $s ; $p = next_prime($p)) {
            if (modint($m, $p) != 0) {
                for (my $t = mulint($m, $p) ; $t <= $n ; $t = mulint($t, $p)) {
                    my $s = rootint(divint($n, $t), $k - 1);
                    last if ($p > $s);
                    __SUB__->($t, $p, $k - 1, $s, $j);
                }
            }
            ++$j;
        }
    }->(1, 2, $k);

    return $count;
}

# Run some tests

foreach my $k (1 .. 10) {

    my $upto = pn_primorial($k) + int(rand(1e5));

    my $x = omega_prime_count_rec($upto, $k);
    my $y = omega_prime_count($k, $upto);

    say "Testing: $k with n = $upto -> $x";

    $x == $y
      or die "Error: $x != $y";
}

say '';

foreach my $k (1 .. 8) {
    say("Count of $k-omega primes for 10^n: ", join(', ', map { omega_prime_count_rec(10**$_, $k) } 0 .. 8));
}

__END__
Count of 1-omega primes for 10^n: 0, 7, 35, 193, 1280, 9700, 78734, 665134, 5762859
Count of 2-omega primes for 10^n: 0, 2, 56, 508, 4097, 33759, 288726, 2536838, 22724609
Count of 3-omega primes for 10^n: 0, 0, 8, 275, 3695, 38844, 379720, 3642766, 34800362
Count of 4-omega primes for 10^n: 0, 0, 0, 23, 894, 15855, 208034, 2389433, 25789580
Count of 5-omega primes for 10^n: 0, 0, 0, 0, 33, 1816, 42492, 691209, 9351293
Count of 6-omega primes for 10^n: 0, 0, 0, 0, 0, 25, 2285, 72902, 1490458
Count of 7-omega primes for 10^n: 0, 0, 0, 0, 0, 0, 8, 1716, 80119
Count of 8-omega primes for 10^n: 0, 0, 0, 0, 0, 0, 0, 1, 719
