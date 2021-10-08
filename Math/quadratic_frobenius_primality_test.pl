#!/usr/bin/perl

# A simple implemenetation of the Frobenius Quadratic pseudoprimality test.

# Conditions:
#   1. Make sure n is odd and is not a perfect power.
#   2. Find the smallest odd prime p such that kronecker(p, n) = -1.
#   3. Check if (1 + sqrt(p))^n == (1 - sqrt(p)) mod n.

# Generalized test:
#   1. Make sure n is odd and is not a perfect power.
#   2. Find the smallest squarefree number c such that kronecker(c, n) = -1.
#   3. Check if (a + b*sqrt(c))^n == (a - b*sqrt(c)) mod n, where a,b,c are all coprime with n.

# No counter-examples are known to this test.

# See also:
#   https://en.wikipedia.org/wiki/Quadratic_integer

use 5.020;
use warnings;

use Math::GMPz;
use ntheory qw(:all);
use experimental qw(signatures);

sub quadratic_powmod ($a, $b, $w, $n, $m) {

    state $t = Math::GMPz::Rmpz_init_nobless();

    my $x = Math::GMPz::Rmpz_init_set_ui(1);
    my $y = Math::GMPz::Rmpz_init_set_ui(0);

    do {

        if ($n & 1) {

            # (x, y) = ((a*x + b*y*w) % m, (a*y + b*x) % m)
            Math::GMPz::Rmpz_mul_ui($t, $b, $w);
            Math::GMPz::Rmpz_mul($t, $t, $y);
            Math::GMPz::Rmpz_addmul($t, $a, $x);
            Math::GMPz::Rmpz_mul($y, $y, $a);
            Math::GMPz::Rmpz_addmul($y, $x, $b);
            Math::GMPz::Rmpz_mod($x, $t, $m);
            Math::GMPz::Rmpz_mod($y, $y, $m);
        }

        # (a, b) = ((a*a + b*b*w) % m, (2*a*b) % m)
        Math::GMPz::Rmpz_mul($t, $a, $b);
        Math::GMPz::Rmpz_mul_2exp($t, $t, 1);
        Math::GMPz::Rmpz_powm_ui($a, $a, 2, $m);
        Math::GMPz::Rmpz_powm_ui($b, $b, 2, $m);
        Math::GMPz::Rmpz_addmul_ui($a, $b, $w);
        Math::GMPz::Rmpz_mod($b, $t, $m);

    } while ($n >>= 1);

    Math::GMPz::Rmpz_set($a, $x);
    Math::GMPz::Rmpz_set($b, $y);
}

sub find_discriminant ($n) {
    for (my $p = 3 ; ; $p = next_prime($p)) {

        my $k = Math::GMPz::Rmpz_ui_kronecker($p, $n);

        if ($k == 0 and $p != $n) {
            return undef;
        }
        elsif ($k == -1) {
            return $p;
        }
    }
}

sub is_quadratic_frobenius_pseudoprime ($n) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    return 0 if ($n <= 1);
    return 1 if ($n == 2);

    return 0 if Math::GMPz::Rmpz_even_p($n);
    return 0 if Math::GMPz::Rmpz_perfect_power_p($n);

    my $c = find_discriminant($n) // return 0;

    my $x_a = Math::GMPz->new(1);
    my $x_b = Math::GMPz->new(1);
    my $w   = Math::GMPz->new($c);

    quadratic_powmod($x_a, $x_b, $w, $n, $n);

    Math::GMPz::Rmpz_congruent_ui_p($x_a, 1, $n)
      && Math::GMPz::Rmpz_congruent_p($x_b, $n - 1, $n);
}

my $count = 0;
foreach my $n (1 .. 1e5) {
    if (is_quadratic_frobenius_pseudoprime($n)) {
        ++$count;
        if (!is_prime($n)) {
            die "Counter-example: $n";
        }
    }
    elsif (is_prime($n)) {
        die "Missed prime: $n";
    }
}

say "Count: $count";    #=> Count: 9592
