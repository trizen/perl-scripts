#!/usr/bin/perl

# Efficient algorithm for computing the nth-Lucas number (mod m).

# Algorithm from:
#   https://metacpan.org/source/KRYDE/Math-NumSeq-72/lib/Math/NumSeq/LucasNumbers.pm

# See also:
#   https://en.wikipedia.org/wiki/Lucas_number

use 5.020;
use warnings;

use experimental qw(signatures);

use Math::GMPz;
use Math::Prime::Util::GMP qw(gcd consecutive_integer_lcm);

sub lucasmod ($n, $m) {

    $n = Math::GMPz->new("$n");
    $m = Math::GMPz->new("$m");

    my ($f, $g, $w) = (
        Math::GMPz::Rmpz_init_set_ui(3),
        Math::GMPz::Rmpz_init_set_ui(1),
    );

    foreach my $bit (split(//, substr(Math::GMPz::Rmpz_get_str($n, 2), 1))) {

        Math::GMPz::Rmpz_powm_ui($g, $g, 2, $m);
        Math::GMPz::Rmpz_powm_ui($f, $f, 2, $m);

        $w
          ? do {
            Math::GMPz::Rmpz_sub_ui($g, $g, 2);
            Math::GMPz::Rmpz_add_ui($f, $f, 2);
          }
          : do {
            Math::GMPz::Rmpz_add_ui($g, $g, 2);
            Math::GMPz::Rmpz_sub_ui($f, $f, 2);
          };

        if ($bit) {
            Math::GMPz::Rmpz_sub($g, $f, $g);
            $w = 0;
        }
        else {
            Math::GMPz::Rmpz_sub($f, $f, $g);
            $w = 1;
        }
    }

    Math::GMPz::Rmpz_mod($g, $g, $m);

    return $g;
}

sub lucas_factorization ($n, $B = 10000) {

    my $k = consecutive_integer_lcm($B);    # lcm(1..B)
    my $L = lucasmod($k, $n);               # Lucas(k) (mod n)

    return gcd($L - 2, $n);
}

say lucas_factorization("121095274043",             700);     #=> 470783           (p+1 is  700-smooth)
say lucas_factorization("544812320889004864776853", 3000);    #=> 333732865481     (p-1 is 3000-smooth)
