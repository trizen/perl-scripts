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
    my $q = divint($x, $y);
    ($q * $y == $x) ? $q : ($q + 1);
}

sub carmichael_from_multiple ($A, $B, $m, $lambda, $p, $k, $callback) {

    my $y = rootint(divint($B, $m), $k);

    if ($k == 1) {

        my $x = vecmax($p, divceil($A, $m));

        forprimes {
            if ($m % $_ != 0) {
                my $t = $m * $_;
                if (($t - 1) % $lambda == 0 and ($t - 1) % ($_ - 1) == 0) {
                    $callback->($t);
                }
            }
        } $x, $y;

        return;
    }

    for (my $r ; $p <= $y ; $p = $r) {

        $r = next_prime($p);
        $m % $p == 0 and next;

        my $L = lcm($lambda, $p - 1);
        gcd($L, $m) == 1 or next;

        my $t = $m * $p;
        my $u = divceil($A, $t);
        my $v = divint($B, $t);

        if ($u <= $v) {
            __SUB__->($A, $B, $t, $L, $r, $k - 1, $callback);
        }
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

carmichael_divisible_by(3) == 561 or die;
carmichael_divisible_by(3*5) == 62745 or die;
carmichael_divisible_by(7*19) == 1729 or die;
carmichael_divisible_by(47*89) == 62745 or die;
carmichael_divisible_by(5*47*89) == 62745 or die;
carmichael_divisible_by(3*47*89) == 62745 or die;
carmichael_divisible_by(3*89) == 62745 or die;

say join(', ', map { carmichael_divisible_by($_) } @{primes(3, 50)});
say join(', ', map { carmichael_divisible_by($_) } 1..60);

__END__
561, 1105, 1729, 561, 1105, 561, 1729, 6601, 2465, 2821, 29341, 6601, 334153, 62745
561, 561, 1105, 1729, 561, 1105, 62745, 561, 1729, 6601, 2465, 2821, 561, 825265, 29341, 6601, 334153, 62745, 561, 2433601, 74165065
