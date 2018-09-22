#!/usr/bin/perl

# An efficient algorithm for computing the nth-Fibonacci number (mod m).

# Algorithm from:
#   https://metacpan.org/source/KRYDE/Math-NumSeq-72/lib/Math/NumSeq/Fibonacci.pm

# See also:
#   https://en.wikipedia.org/wiki/Fibonacci_number

use 5.020;
use warnings;

use experimental qw(signatures);

use Math::GMPz;
use Math::Prime::Util::GMP qw(gcd consecutive_integer_lcm);

sub fibmod ($n, $m) {

    $n = Math::GMPz->new("$n");
    $m = Math::GMPz->new("$m");

    my ($f, $g, $w) = (
        Math::GMPz::Rmpz_init_set_ui(0),
        Math::GMPz::Rmpz_init_set_ui(1),
    );

    my $t = Math::GMPz::Rmpz_init();

    foreach my $bit (split(//, substr(Math::GMPz::Rmpz_get_str($n, 2), 1))) {

        Math::GMPz::Rmpz_powm_ui($g, $g, 2, $m);
        Math::GMPz::Rmpz_powm_ui($f, $f, 2, $m);

        Math::GMPz::Rmpz_mul_2exp($t, $g, 2);
        Math::GMPz::Rmpz_sub($t, $t, $f);

        $w
          ? Math::GMPz::Rmpz_add_ui($t, $t, 2)
          : Math::GMPz::Rmpz_sub_ui($t, $t, 2);

        Math::GMPz::Rmpz_add($f, $f, $g);

        if ($bit) {
            Math::GMPz::Rmpz_sub($f, $t, $f);
            Math::GMPz::Rmpz_set($g, $t);
            $w = 0;
        }
        else {
            Math::GMPz::Rmpz_sub($g, $t, $f);
            $w = 1;
        }
    }

    Math::GMPz::Rmpz_mod($g, $g, $m);

    return $g;
}

sub fibonacci_factorization ($n, $B = 10000) {

    my $k = consecutive_integer_lcm($B);    # lcm(1..B)
    my $F = fibmod($k, $n);                 # Fibonacci(k) (mod n)

    return gcd($F, $n);
}

say fibonacci_factorization("121095274043",             700);     #=> 470783           (p+1 is  700-smooth)
say fibonacci_factorization("544812320889004864776853", 3000);    #=> 333732865481     (p-1 is 3000-smooth)
