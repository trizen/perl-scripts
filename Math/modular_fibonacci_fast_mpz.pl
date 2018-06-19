#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 June 2018
# https://github.com/trizen

# A very efficient algorithm for computing the nth-Fibonacci number (mod m).

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

sub modular_fibonacci ($n, $m) {

    $n = Math::GMPz->new("$n");
    $m = Math::GMPz->new("$m");

    my $t = Math::GMPz::Rmpz_init();
    my $u = Math::GMPz::Rmpz_init();

    my $f = Math::GMPz::Rmpz_init_set_ui(0);    # set to 2 for Lucas numbers
    my $g = Math::GMPz::Rmpz_init_set_ui(1);

    my $a = Math::GMPz::Rmpz_init_set_ui(0);
    my $b = Math::GMPz::Rmpz_init_set_ui(1);

    for (; ;) {

        if (Math::GMPz::Rmpz_odd_p($n)) {

            # (f, g) = (f*a + g*b, f*b + g*(a+b))  mod m

            Math::GMPz::Rmpz_mul($u, $g, $b);
            Math::GMPz::Rmpz_mul($t, $f, $a);
            Math::GMPz::Rmpz_mul($g, $g, $a);

            Math::GMPz::Rmpz_add($t, $t, $u);
            Math::GMPz::Rmpz_add($g, $g, $u);

            Math::GMPz::Rmpz_addmul($g, $f, $b);

            Math::GMPz::Rmpz_mod($f, $t, $m);
            Math::GMPz::Rmpz_mod($g, $g, $m);
        }

        # (a, b) = (a*a + b*b, a*b + b*(a+b))  mod m

        Math::GMPz::Rmpz_div_2exp($n, $n, 1);
        Math::GMPz::Rmpz_sgn($n) || last;

        Math::GMPz::Rmpz_mul($t, $a, $a);
        Math::GMPz::Rmpz_mul($u, $b, $b);
        Math::GMPz::Rmpz_mul($b, $b, $a);

        Math::GMPz::Rmpz_mul_2exp($b, $b, 1);

        Math::GMPz::Rmpz_add($b, $b, $u);
        Math::GMPz::Rmpz_add($t, $t, $u);

        Math::GMPz::Rmpz_mod($a, $t, $m);
        Math::GMPz::Rmpz_mod($b, $b, $m);
    }

    return $f;
}

say "=> Last 20 digits of the 10^100-th Fibonacci number:";
say modular_fibonacci(Math::GMPz->new(10)**100, Math::GMPz->new(10)**20);

say "\n=> First few Fibonacci numbers:";
say join(' ', map { modular_fibonacci($_, 10**9) } 0 .. 25);

say "\n=> Last digit of Fibonacci numbers: ";
say join(' ', map { modular_fibonacci($_, 10) } 0 .. 50);
