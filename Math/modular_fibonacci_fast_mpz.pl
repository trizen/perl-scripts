#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 June 2018
# https://github.com/trizen

# An efficient algorithm for computing the nth-Fibonacci number (mod m).

# See also:
#   https://en.wikipedia.org/wiki/Fibonacci_number

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

sub modular_fibonacci ($n, $m) {

    $n = Math::GMPz->new("$n");
    $m = Math::GMPz->new("$m");

    state $t = Math::GMPz::Rmpz_init_nobless();
    state $u = Math::GMPz::Rmpz_init_nobless();

    my $f = Math::GMPz::Rmpz_init_set_ui(0);    # set to 2 for Lucas numbers
    my $g = Math::GMPz::Rmpz_init_set_ui(1);

    my $A = Math::GMPz::Rmpz_init_set_ui(0);
    my $B = Math::GMPz::Rmpz_init_set_ui(1);

    my @bits = split(//, Math::GMPz::Rmpz_get_str($n, 2));

    while (@bits) {

        if (pop @bits) {

            # (f, g) = (f*a + g*b, f*b + g*(a+b))  mod m

            Math::GMPz::Rmpz_mul($u, $g, $B);
            Math::GMPz::Rmpz_mul($t, $f, $A);
            Math::GMPz::Rmpz_mul($g, $g, $A);

            Math::GMPz::Rmpz_add($t, $t, $u);
            Math::GMPz::Rmpz_add($g, $g, $u);

            Math::GMPz::Rmpz_addmul($g, $f, $B);

            Math::GMPz::Rmpz_mod($f, $t, $m);
            Math::GMPz::Rmpz_mod($g, $g, $m);
        }

        # (a, b) = (a*a + b*b, a*b + b*(a+b))  mod m

        Math::GMPz::Rmpz_mul($t, $A, $A);
        Math::GMPz::Rmpz_mul($u, $B, $B);

        Math::GMPz::Rmpz_mul($B, $B, $A);
        Math::GMPz::Rmpz_mul_2exp($B, $B, 1);

        Math::GMPz::Rmpz_add($B, $B, $u);
        Math::GMPz::Rmpz_add($t, $t, $u);

        Math::GMPz::Rmpz_mod($A, $t, $m);
        Math::GMPz::Rmpz_mod($B, $B, $m);
    }

    return $f;
}

say "=> Last 20 digits of the 10^100-th Fibonacci number:";
say modular_fibonacci(Math::GMPz->new(10)**100, Math::GMPz->new(10)**20);

say "\n=> First few Fibonacci numbers:";
say join(' ', map { modular_fibonacci($_, 10**9) } 0 .. 25);

say "\n=> Last digit of Fibonacci numbers: ";
say join(' ', map { modular_fibonacci($_, 10) } 0 .. 50);
