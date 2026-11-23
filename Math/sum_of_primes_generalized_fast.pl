#!/usr/bin/perl

# Simple implementation of the prime-summation function:
#   Sum_{p prime <= n} p^k, for any fixed k >= 0.

use 5.036;
use Math::GMPz;
use ntheory                qw(divint sqrtint primes);
use Math::Prime::Util::GMP qw(faulhaber_sum);

sub sum_of_primes ($n, $k = 1) {

    $n <= 1 and return 0;

    my $r         = sqrtint($n);
    my $max_small = divint($n, $r + 1);
    my @V_small   = CORE::reverse(1 .. $max_small);

    my (@S_small, @S_large);

    # Initialize S_large[i] = faulhaber_sum(floor(n / i), k)
    for my $i (1 .. $r) {
        $S_large[$i] = Math::GMPz::Rmpz_init_set_str(faulhaber_sum(divint($n, $i), $k), 10);
    }

    my $t = Math::GMPz::Rmpz_init();
    my $u = Math::GMPz::Rmpz_init();

    # Initialize S_small[v] = faulhaber_sum(v, k)
    for my $v (1 .. $max_small) {
        Math::GMPz::Rmpz_ui_pow_ui($t, $v, $k);
        Math::GMPz::Rmpz_add($u, $u, $t);
        $S_small[$v] = Math::GMPz::Rmpz_init_set($u);
    }

    foreach my $p (@{primes(2, $r)}) {

        my $cp = $S_small[$p - 1];
        my $p2 = $p * $p;
        Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k);

        # Update S_large[i] where floor(n / i) >= p^2  <=>  i <= floor(n / p^2)
        my $max_i = divint($n, $p2);
        $max_i = $r if $max_i > $r;

        foreach my $i (1 .. $max_i) {
            my $ip    = $i * $p;
            my $s_div = ($ip <= $r) ? $S_large[$ip] : $S_small[divint($n, $ip)];
            Math::GMPz::Rmpz_sub($u, $s_div, $cp);
            Math::GMPz::Rmpz_submul($S_large[$i], $u, $t);
        }

        # Update S_small[v] for v >= p^2
        foreach my $v (@V_small) {
            last if $v < $p2;
            Math::GMPz::Rmpz_sub($u, $S_small[divint($v, $p)], $cp);
            Math::GMPz::Rmpz_submul($S_small[$v], $u, $t);
        }
    }

    return $S_large[1] - 1;
}

say sum_of_primes(100, 0);    #=> 25
say sum_of_primes(1e8);       #=> 279209790387276
say sum_of_primes(1e8, 2);    #=> 18433608754948081174274
say sum_of_primes(1e9, 3);    #=> 12212817300801335181685928278468661

