#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 30 October 2017
# https://github.com/trizen

# Find all the solutions to the congruence equation:
#   x^2 = a (mod n)

# Defined for any values of `a` and `n` for which `kronecker(a, n) = 1`.

# When `kronecker(a, n) != 1`, for example:
#
#   a = 472
#   n = 972
#
# which represents:
#   x^2 = 472 (mod 972)
#
# this algorithm is not able to find a solution, although there exist four solutions:
#   x = {38, 448, 524, 934}

# Code inspired from:
#   https://github.com/Magtheridon96/Square-Root-Modulo-N

use 5.020;
use warnings;

use experimental qw(signatures);

use List::Util qw(uniq);
use Set::Product::XS qw(product);
use ntheory qw(factor_exp is_prime chinese);
use Math::AnyNum qw(:overload kronecker powmod invmod valuation ipow);

sub tonelli_shanks ($n, $p) {

    my $q = $p - 1;
    my $s = valuation($q, 2);

    $s == 1
      and return powmod($n, ($p + 1) >> 2, $p);

    $q >>= $s;

    my $z = 1;
    for (my $i = 2 ; $i < $p ; ++$i) {
        if (kronecker($i, $p) == -1) {
            $z = $i;
            last;
        }
    }

    my $c = powmod($z, $q, $p);
    my $r = powmod($n, ($q + 1) >> 1, $p);
    my $t = powmod($n, $q, $p);

    while (($t - 1) % $p != 0) {

        my $k = 1;
        my $v = $t * $t % $p;

        for (my $i = 1 ; $i < $s ; ++$i) {
            if (($v - 1) % $p == 0) {
                $k = powmod($c, 1 << ($s - $i - 1), $p);
                $s = $i;
                last;
            }
            $v = $v * $v % $p;
        }

        $r = $r * $k % $p;
        $c = $k * $k % $p;
        $t = $t * $c % $p;
    }

    return $r;
}

sub sqrt_mod_n ($a, $n) {

    kronecker($a, $n) == 1 or return;

    $a %= $n;

    if (($n & ($n - 1)) == 0) {    # n is a power of 2

        if ($a % 8 == 1) {

            my $k = valuation($n, 2);

            $k == 1 and return (1);
            $k == 2 and return (1, 3);
            $k == 3 and return (1, 3, 5, 7);

            if ($a == 1) {
                return (1, ($n >> 1) - 1, ($n >> 1) + 1, $n - 1);
            }

            my @roots;

            foreach my $s (sqrt_mod_n($a, $n >> 1)) {
                my $i = ((($s * $s - $a) >> ($k - 1)) % 2);
                my $r = ($s + ($i << ($k - 2)));
                push(@roots, $r, $n - $r);
            }

            return uniq(@roots);
        }

        return;
    }

    if (is_prime($n)) {    # n is a prime
        my $r = tonelli_shanks($a, $n);
        return ($r, $n - $r);
    }

    my @pe = factor_exp($n);    # factorize `n` into prime powers

    if (@pe == 1) {             # `n` is an odd prime power

        my $p = Math::AnyNum->new($pe[0][0]);

        kronecker($a, $p) == 1 or return;

        my $r = tonelli_shanks($a, $p);
        my ($r1, $r2) = ($r, $n - $r);

        my $pk = $p;
        my $pi = $p * $p;

        for (1 .. $pe[0][1]-1) {

            my $x = $r1;
            my $y = invmod(2, $pk) * invmod($x, $pk);

            $r1 = ($pi + $x - $y * ($x * $x - $a + $pi)) % $pi;
            $r2 = ($pi - $r1);

            $pk *= $p;
            $pi *= $p;
        }

        return ($r1, $r2);
    }

    my @chinese;

    foreach my $f (@pe) {
        my $m = ipow($f->[0], $f->[1]);
        my @r = sqrt_mod_n($a, $m);
        push @chinese, [map { [$_, $m] } @r];
    }

    my @roots;

    product {
        push @roots, chinese(@_);
    } @chinese;

    return uniq(@roots);
}

say join(' ', sqrt_mod_n(993, 2048));    #=> 369 1679 655 1393
say join(' ', sqrt_mod_n(441, 920));     #=> 761 481 209 849 531 251 899 619 301 21 669 389 71 711 439 159
say join(' ', sqrt_mod_n(841, 905));     #=> 391 876 29 514
say join(' ', sqrt_mod_n(289, 992));     #=> 417 513 975 79 913 17 479 575

# The algorithm works for arbitrary large integers
say join(' ', sqrt_mod_n(13**18 * 5**7 - 1, 13**18 * 5**7));    #=> 633398078861605286438568 2308322911594648160422943 6477255756527023177780182 8152180589260066051764557
