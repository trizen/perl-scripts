#!/usr/bin/perl

# Efficient algorithm for computing `binomial(n, k) mod m`, based on the factorization of `m`.

# Algorithm by Andrew Granville:
#     https://www.scribd.com/document/344759427/BinCoeff-pdf

# Algorithm translated from (+some optimizations):
#   https://github.com/hellman/libnum/blob/master/libnum/modular.py

# Translated by: Trizen
# Date: 29 September 2017
# Edit: 28 April 2022
# https://github.com/trizen

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub modular_binomial ($n, $k, $m) {

    if ($m == 0) {
        return undef;
    }

    if ($m == 1) {
        return 0;
    }

    if ($k < 0) {
        $k = subint($n, $k);
    }

    if ($k < 0) {
        return 0;
    }

    if ($n < 0) {
        return modint(mulint(powint(-1, $k), __SUB__->(subint($k, $n) - 1, $k, $m)), $m);
    }

    if ($k > $n) {
        return 0;
    }

    if ($k == 0 or $k == $n) {
        return modint(1, $m);
    }

    if ($k == 1 or $k == subint($n, 1)) {
        return modint($n, $m);
    }

    my @congruences;

    foreach my $pair (factor_exp(absint($m))) {
        my ($p, $e) = @$pair;

        if ($e == 1) {
            push @congruences, [lucas_theorem($n, $k, $p), $p];
        }
        else {
            push @congruences, [modular_binomial_prime_power($n, $k, $p, $e), powint($p, $e)];
        }
    }

    modint(chinese(@congruences), $m);
}

#<<<
#~ sub factorial_prime_pow ($n, $p) {
    #~ divint(subint($n, sumdigits($n, $p)), subint($p, 1));
#~ }
#>>>

sub factorial_prime_pow ($n, $p) {
    my $count = 0;
    my $ppow  = $p;
    while ($ppow <= $n) {
        $count = addint($count, divint($n, $ppow));
        $ppow  = mulint($ppow, $p);
    }
    return $count;
}

sub binomial_prime_pow ($n, $k, $p) {
#<<<
      factorial_prime_pow($n,      $p)
    - factorial_prime_pow($k,      $p)
    - factorial_prime_pow(subint($n, $k), $p);
#>>>
}

sub factorial_without_prime ($n, $p, $pk) {
    return 1 if ($n <= 1);

    if ($p > $n) {
        return factorialmod($n, $pk);
    }

    my $r = 1;
    my $t = 0;

    foreach my $v (1 .. $n) {
        if (++$t == $p) {
            $t = 0;
        }
        else {
            $r = mulmod($r, $v, $pk);
        }
    }

    return $r;
}

sub lucas_theorem ($n, $k, $p) {    # p is prime

    my $r = 1;

    while ($k) {

        my $np = modint($n, $p);
        my $kp = modint($k, $p);

        if ($kp > $np) { return 0 }

        my $rp = subint($np, $kp);

        my $x = factorialmod($np, $p);
        my $y = factorialmod($kp, $p);
        my $z = factorialmod($rp, $p);

        $y = mulmod($y, $z, $p);
        $x = divmod($x, $y, $p);

        $r = mulmod($r, $x, $p);

        $n = divint($n, $p);
        $k = divint($k, $p);
    }

    return $r;
}

sub binomial_non_prime_part ($n, $k, $p, $e) {

    my $pe = powint($p, $e);
    my $r  = subint($n, $k);

    my $acc     = 1;
    my @fact_pe = (1);

    if ($pe < ~0 and $p < $n) {
        my $count = 0;
        foreach my $x (1 .. vecmin(1e4, $pe - 1)) {
            if (++$count == $p) {
                $count = 0;
            }
            else {
                $acc = mulmod($acc, $x, $pe);
            }
            push @fact_pe, $acc;
        }
    }

    my $top         = 1;
    my $bottom      = 1;
    my $is_negative = 0;
    my $digits      = 0;

    while ($n) {

        if ($digits >= $e) {
            $is_negative ^= modint($n, 2);
            $is_negative ^= modint($r, 2);
            $is_negative ^= modint($k, 2);
        }

        my $np = modint($n, $pe);
        my $rp = modint($r, $pe);
        my $kp = modint($k, $pe);

#<<<
        $top    = mulmod($top,    ($fact_pe[$np] // factorial_without_prime($np, $p, $pe)), $pe);
        $bottom = mulmod($bottom, ($fact_pe[$rp] // factorial_without_prime($rp, $p, $pe)), $pe);
        $bottom = mulmod($bottom, ($fact_pe[$kp] // factorial_without_prime($kp, $p, $pe)), $pe);
#>>>

        $n = divint($n, $p);
        $r = divint($r, $p);
        $k = divint($k, $p);

        ++$digits;
    }

    my $res = divmod($top, $bottom, $pe);

    if ($is_negative and ($p != 2 or $e < 3)) {
        $res = subint($pe, $res);
    }

    return $res;
}

sub modular_binomial_prime_power ($n, $k, $p, $e) {
    my $pow = binomial_prime_pow($n, $k, $p);

    if ($pow >= $e) {
        return 0;
    }

    my $er = $e - $pow;
    my $r  = modint(binomial_non_prime_part($n, $k, $p, $er), powint($p, $er));

    my $pe = powint($p, $e);
    return mulmod(powmod($p, $pow, $pe), $r, $pe);
}

use Test::More tests => 44;

is(modular_binomial(10, 2, 43), 2);
is(modular_binomial(10, 8, 43), 2);

is(modular_binomial(10, 2, 24), 21);
is(modular_binomial(10, 8, 24), 21);

is(modular_binomial(100, 42, -127), binomial(100, 42) % -127);

is(modular_binomial(12,   5,   100000),  792);
is(modular_binomial(16,   4,   100000),  1820);
is(modular_binomial(100,  50,  139),     71);
is(modular_binomial(1000, 10,  1243),    848);
is(modular_binomial(124,  42,  1234567), 395154);
is(modular_binomial(1e9,  1e4, 1234567), 833120);
is(modular_binomial(1e10, 1e5, 1234567), 589372);

is(modular_binomial(1e10,  1e5, 4233330243), 3403056024);
is(modular_binomial(-1e10, 1e5, 4233330243), 2865877173);

is(modular_binomial(1e10, 1e4, factorial(13)), 1845043200);
is(modular_binomial(1e10, 1e5, factorial(13)), 1556755200);
is(modular_binomial(1e10, 1e6, factorial(13)), 5748019200);

is(modular_binomial(-1e10, 1e4, factorial(13)), 4151347200);
is(modular_binomial(-1e10, 1e5, factorial(13)), 1037836800);
is(modular_binomial(-1e10, 1e6, factorial(13)), 2075673600);

is(modular_binomial(3, 1, 9),  binomial(3, 1) % 9);
is(modular_binomial(4, 1, 16), binomial(4, 1) % 16);

is(modular_binomial(1e9,  1e5, 43 * 97 * 503),         585492);
is(modular_binomial(1e9,  1e6, 5041689707),            15262431);
is(modular_binomial(1e7,  1e5, 43**2 * 97**3 * 13**4), 1778017500428);
is(modular_binomial(1e7,  1e5, 42**2 * 97**3 * 13**4), 10015143223176);
is(modular_binomial(1e9,  1e5, 12345678910),           4517333900);
is(modular_binomial(1e9,  1e6, 13**2 * 5**6),          2598375);
is(modular_binomial(1e10, 1e5, 1234567),               589372);

is(modular_binomial(1e5,     1e3, 43),                 binomial(1e5,     1e3) % 43);
is(modular_binomial(1e5,     1e3, 43 * 97),            binomial(1e5,     1e3) % (43 * 97));
is(modular_binomial(1e5,     1e3, 43 * 97 * 43),       binomial(1e5,     1e3) % (43 * 97 * 43));
is(modular_binomial(1e5,     1e3, 43 * 97 * (5**5)),   binomial(1e5,     1e3) % (43 * 97 * (5**5)));
is(modular_binomial(1e5,     1e3, next_prime(1e4)**2), binomial(1e5,     1e3) % next_prime(1e4)**2);
is(modular_binomial(1e5,     1e3, next_prime(1e4)),    binomial(1e5,     1e3) % next_prime(1e4));
is(modular_binomial(1e6,     1e3, next_prime(1e5)),    binomial(1e6,     1e3) % next_prime(1e5));
is(modular_binomial(1e6,     1e3, next_prime(1e7)),    binomial(1e6,     1e3) % next_prime(1e7));
is(modular_binomial(1234567, 1e3, factorial(20)),      binomial(1234567, 1e3) % factorial(20));
is(modular_binomial(1234567, 1e4, factorial(20)),      binomial(1234567, 1e4) % factorial(20));

is(modular_binomial(1e6, 1e3, powint(2, 128) + 1), binomial(1e6, 1e3) % (powint(2, 128) + 1));
is(modular_binomial(1e6, 1e3, powint(2, 128) - 1), binomial(1e6, 1e3) % (powint(2, 128) - 1));

is(modular_binomial(1e6, 1e4, (powint(2, 128) + 1)**2), binomial(1e6, 1e4) % ((powint(2, 128) + 1)**2));
is(modular_binomial(1e6, 1e4, (powint(2, 128) - 1)**2), binomial(1e6, 1e4) % ((powint(2, 128) - 1)**2));
is(modular_binomial(-10, -9,  -10), binomial(-10, -9) % -10);

say("binomial(10^10, 10^5) mod 13! = ", modular_binomial(1e10, 1e5, factorial(13)));

say modular_binomial(12,   5,   100000);     #=> 792
say modular_binomial(16,   4,   100000);     #=> 1820
say modular_binomial(100,  50,  139);        #=> 71
say modular_binomial(1000, 10,  1243);       #=> 848
say modular_binomial(124,  42,  1234567);    #=> 395154
say modular_binomial(1e9,  1e4, 1234567);    #=> 833120
say modular_binomial(1e10, 1e5, 1234567);    #=> 589372

__END__
my $upto = 10;
foreach my $n (-$upto .. $upto) {
    foreach my $k (-$upto .. $upto) {
        foreach my $m (-$upto .. $upto) {
            next if ($m == 0);
            say "Testing: binomial($n, $k, $m)";
            is(modular_binomial($n, $k, $m), binomial($n, $k) % $m);
        }
    }
}
