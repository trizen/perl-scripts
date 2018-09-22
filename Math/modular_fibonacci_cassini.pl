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
use Math::Prime::Util::GMP qw(consecutive_integer_lcm gcd);

sub fibmod ($n, $m) {

    $n = Math::GMPz->new("$n");
    $m = Math::GMPz->new("$m");

    my ($f, $g, $a) = (0, 1, -2);

    foreach my $bit (split(//, substr(Math::GMPz::Rmpz_get_str($n, 2), 1))) {

        ($g *= $g) %= $m;
        ($f *= $f) %= $m;

        my $t = ($g << 2) - $f + $a;

        $f += $g;

        if ($bit) {
            ($f, $g, $a) = ($t - $f, $t, -2);
        }
        else {
            ($g, $a) = ($t - $f, 2);
        }
    }

    return ($g % $m);
}

sub fibonacci_factorization ($n, $B = 10000) {

    my $k = consecutive_integer_lcm($B);    # lcm(1..B)
    my $F = fibmod($k, $n);                 # Fibonacci(k) (mod n)

    return gcd($F, $n);
}

say fibonacci_factorization("121095274043",             700);     #=> 470783           (p+1 is  700-smooth)
say fibonacci_factorization("544812320889004864776853", 3000);    #=> 333732865481     (p-1 is 3000-smooth)
