#!/usr/bin/perl

# Method for finding the smallest Carmichael number divisible by n.

# See also:
#   https://oeis.org/A135721
#   https://oeis.org/A253595

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub carmichael_from_multiple ($A, $B, $m, $L, $lo, $k, $callback) {

    # Largest possisble prime factor for Carmichael numbers <= B
    my $max_p = (1 + sqrtint(8*$B + 1))>>2;

    my $hi = vecmin($max_p, rootint(divint($B, $m), $k));

    if ($lo > $hi) {
        return;
    }

    if ($k == 1) {

        $lo = vecmax($lo, divceil($A, $m));
        $lo > $hi && return;

        my $t = invmod($m, $L) // return;
        $t > $hi && return;
        $t += $L while ($t < $lo);

        for (my $p = $t ; $p <= $hi ; $p += $L) {
            if ($m % $p != 0 and is_prime($p)) {
                my $n = $m * $p;
                if (($n - 1) % ($p - 1) == 0) {
                    $callback->($n);
                }
            }
        }

        return;
    }

    foreach my $p (@{primes($lo, $hi)}) {

        $m % $p == 0 and next;
        gcd($m, $p - 1) == 1 or next;

        __SUB__->($A, $B, $m * $p, lcm($L, $p - 1), $p + 1, $k - 1, $callback);
    }
}

sub carmichael_divisible_by ($m) {

    $m >= 1 or return;
    $m % 2 == 0 and return;
    is_square_free($m) || return;
    gcd($m, euler_phi($m)) == 1 or return;

    my $A = vecmax(561, $m);
    my $B = 2 * $A;

    my $L = vecmax(1, lcm(map { $_ - 1 } factor($m)));

    my @found;

    for (; ;) {
        for my $k ((is_prime($m) ? 2 : 1) .. 1000) {

            my @P;
            for (my $p = 3 ; scalar(@P) < $k ; $p = next_prime($p)) {
                if ($m % $p != 0 and $L % $p != 0) {
                    push @P, $p;
                }
            }

            last if (vecprod(@P, $m) > $B);

            my $callback = sub ($n) {
                push @found, $n;
                $B = vecmin($B, $n);
            };

            carmichael_from_multiple($A, $B, $m, $L, $P[0], $k, $callback);
        }

        last if @found;

        $A = $B + 1;
        $B = 2 * $A;
    }

    vecmin(@found);
}

carmichael_divisible_by(3) == 561             or die;
carmichael_divisible_by(3 * 5) == 62745       or die;
carmichael_divisible_by(7 * 19) == 1729       or die;
carmichael_divisible_by(47 * 89) == 62745     or die;
carmichael_divisible_by(5 * 47 * 89) == 62745 or die;
carmichael_divisible_by(3 * 47 * 89) == 62745 or die;
carmichael_divisible_by(3 * 89) == 62745      or die;

say join(', ', map { carmichael_divisible_by($_) } @{primes(3, 50)});
say join(', ', map { carmichael_divisible_by($_) } 1 .. 60);

__END__
561, 1105, 1729, 561, 1105, 561, 1729, 6601, 2465, 2821, 29341, 6601, 334153, 62745
561, 561, 1105, 1729, 561, 1105, 62745, 561, 1729, 6601, 2465, 2821, 561, 825265, 29341, 6601, 334153, 62745, 561, 2433601, 74165065
