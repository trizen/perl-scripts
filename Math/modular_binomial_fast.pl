#!/usr/bin/perl

# Efficient algorithm for computing `binomial(n, k) mod m`, based on the factorization of `m`.

# Algorithm by Andrew Granville:
#     https://www.scribd.com/document/344759427/BinCoeff-pdf

# Algorithm translated from:
#   https://github.com/hellman/libnum/blob/master/libnum/modular.py

# Translated by: Daniel "Trizen" Șuteu
# Date: 29 September 2017
# https://github.com/trizen

use 5.010;
use strict;
use warnings;

use integer;

use experimental qw(signatures);
use ntheory qw(factor_exp chinese invmod mulmod powmod todigits vecsum);

sub modular_binomial ($n, $k, $m) {

    my @rems_mods;
    foreach my $pair (factor_exp($m)) {
        my ($p, $e) = @$pair;
        push @rems_mods, [modular_binomial_prime_power($n, $k, $p, $e), $p**$e];
    }

    return chinese(@rems_mods);
}

sub factorial_prime_pow ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub binomial_prime_pow ($n, $k, $p) {
#<<<
      factorial_prime_pow($n,      $p)
    - factorial_prime_pow($k,      $p)
    - factorial_prime_pow($n - $k, $p);
#>>>
}

sub binomial_non_prime_part ($n, $k, $p, $e) {
    my $pe = $p**$e;
    my $r  = $n - $k;

    my $acc     = 1;
    my @fact_pe = (1);

    foreach my $x (1 .. $pe - 1) {
        if ($x % $p == 0) {
            $x = 1;
        }
        $acc = mulmod($acc, $x, $pe);
        push @fact_pe, $acc;
    }

    my $top         = 1;
    my $bottom      = 1;
    my $is_negative = 0;
    my $digits      = 0;

    while ($n) {

        if ($acc != 1 and $digits >= $e) {
            $is_negative ^= $n & 1;
            $is_negative ^= $r & 1;
            $is_negative ^= $k & 1;
        }

#<<<
        $top    = mulmod($top,    $fact_pe[$n % $pe], $pe);
        $bottom = mulmod($bottom, $fact_pe[$r % $pe], $pe);
        $bottom = mulmod($bottom, $fact_pe[$k % $pe], $pe);
#>>>

        $n = $n / $p;
        $r = $r / $p;
        $k = $k / $p;

        ++$digits;
    }

    my $res = mulmod($top, invmod($bottom, $pe), $pe);

    if ($is_negative and ($p != 2 or $e < 3)) {
        $res = $pe - $res;
    }

    return $res;
}

sub modular_binomial_prime_power ($n, $k, $p, $e) {
    my $pow = binomial_prime_pow($n, $k, $p);

    if ($pow >= $e) {
        return 0;
    }

    my $modpow = $e - $pow;
    my $r = binomial_non_prime_part($n, $k, $p, $modpow) % $p**$modpow;

    if ($pow == 0) {
        return ($r % $p**$e);
    }

    return mulmod(powmod($p, $pow, $p**$e), $r, $p**$e);
}

say modular_binomial(12,   5,   100000);     #=> 792
say modular_binomial(16,   4,   100000);     #=> 1820
say modular_binomial(100,  50,  139);        #=> 71
say modular_binomial(1000, 10,  1243);       #=> 848
say modular_binomial(124,  42,  1234567);    #=> 395154
say modular_binomial(1e9,  1e4, 1234567);    #=> 833120
say modular_binomial(1e10, 1e5, 1234567);    #=> 589372
