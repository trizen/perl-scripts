#!/usr/bin/perl

# Translated by: Trizen
# Date: 18 March 2026
# https://github.com/trizen

# Fast algorithm for computing the binomial coefficient modulo some integer m.

# The implementation is based on Lucas' Theorem and its generalization given in the paper
# Andrew Granville "The Arithmetic Properties of Binomial Coefficients", In Proceedings of
# the Organic Mathematics Workshop, Simon Fraser University, December 12-14, 1995.

# Translation of binomod.gp v1.5 by Max Alekseyev, with some minor optimizations.

# See also:
#   https://home.gwu.edu/~maxal/gpscripts/

use 5.036;
use Math::GMPz;
use ntheory 0.74           qw(:all);
use Math::Prime::Util::GMP qw();
use Math::Sidef            qw();

prime_set_config(bigint => "Math::BigInt");

sub test_binomialmod($n, $k, $m) {
    Math::Sidef::binomialmod($n, $k, $m);
}

sub _factorial_without_prime {
    my ($n, $p, $pk, $from, $count, $res) = @_;

    return 1 if ($n <= 1);

    if ($p > $n) {
        return factorialmod($n, $pk);
    }

    if ($$from == $n) {
        return $$res;
    }

    if ($$from > $n) {
        $$from  = 0;
        $$count = 0;
        $$res   = 1;
    }

    my $r = $$res;
    my $t = $$count;

    foreach my $v ($$from + 1 .. $n) {
        if (++$t == $p) {
            $t = 0;
        }
        else {
            $r = mulmod($r, $v, $pk);
        }
    }

    $$res   = $r;
    $$count = $t;
    $$from  = $n;

    return $r;
}

sub _small_k_binomialmod {
    my ($n_val, $k_val, $m_val, $p) = @_;

    $n_val = Math::GMPz::Rmpz_init_set_str($n_val, 10) if ref($n_val) ne 'Math::GMPz';
    $m_val = Math::GMPz::Rmpz_init_set_str($m_val, 10) if ref($m_val) ne 'Math::GMPz';

    if (!$p or $k_val <= 1e5) {
        my $bin = Math::GMPz::Rmpz_init();
        if (Math::GMPz::Rmpz_fits_ulong_p($n_val) and Math::GMPz::Rmpz_cmp_ui($n_val, 1e5) <= 0) {
            Math::GMPz::Rmpz_bin_uiui($bin, Math::GMPz::Rmpz_get_ui($n_val), $k_val);
        }
        else {
            Math::GMPz::Rmpz_bin_ui($bin, $n_val, $k_val);
        }
        Math::GMPz::Rmpz_mod($bin, $bin, $m_val);
        return $bin;
    }

    my $v = 0;
    state $num_mult = Math::GMPz::Rmpz_init_nobless();
    state $den_mult = Math::GMPz::Rmpz_init_nobless();
    state $temp     = Math::GMPz::Rmpz_init_nobless();

    Math::GMPz::Rmpz_set_ui($num_mult, 1);
    Math::GMPz::Rmpz_set_ui($den_mult, 1);

    for my $i (0 .. $k_val - 1) {
        Math::GMPz::Rmpz_sub_ui($temp, $n_val, $i);
        while (Math::GMPz::Rmpz_divisible_ui_p($temp, $p)) {
            Math::GMPz::Rmpz_divexact_ui($temp, $temp, $p);
            ++$v;
        }
        Math::GMPz::Rmpz_mul($num_mult, $num_mult, $temp);
        Math::GMPz::Rmpz_mod($num_mult, $num_mult, $m_val);

        my $den = $i + 1;
        while ($den % $p == 0) {
            $den = Math::Prime::Util::divint($den, $p);
            --$v;
        }

        Math::GMPz::Rmpz_mul_ui($den_mult, $den_mult, $den);
        Math::GMPz::Rmpz_mod($den_mult, $den_mult, $m_val);
    }

    Math::GMPz::Rmpz_invert($temp, $den_mult, $m_val);

    my $ans = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($ans, $num_mult, $temp);
    Math::GMPz::Rmpz_mod($ans, $ans, $m_val);

    if ($v > 0) {
        Math::GMPz::Rmpz_ui_pow_ui($temp, $p, $v);
        Math::GMPz::Rmpz_mul($ans, $ans, $temp);
        Math::GMPz::Rmpz_mod($ans, $ans, $m_val);
    }

    return $ans;
}

sub _is_small_k_binomialmod {
    my ($n, $k, $m) = @_;

    $n >= 1e6 or return;

    ## say "Small k check: binomial($n, $k, $m)";

    if ($m >= 1e7 and $n >= 1e7 and $k <= 1e6) {
        return 1;
    }

    my $new_k = Math::Prime::Util::GMP::subint($n, $k);

    if ($new_k > 0 and $new_k < $k) {
        $k = $new_k;
    }

    $k <= 1e7 or return;

    my $sqrt_m   = Math::Prime::Util::GMP::sqrtint($m);
    my $m_over_n = Math::Prime::Util::GMP::divint($m, $n);

    $k < $sqrt_m and $k < $m_over_n;
}

sub _lucas_theorem {    # p is prime
    my ($n, $k, $p) = @_;

    my $r = 1;
    my (@nd, @kd);

    while ($k) {
        my $np = Math::Prime::Util::GMP::modint($n, $p);
        my $kp = Math::Prime::Util::GMP::modint($k, $p);

        push @nd, $np;
        push @kd, $kp;

        if ($kp > $np) { return 0 }

        $n = Math::Prime::Util::GMP::divint($n, $p);
        $k = Math::Prime::Util::GMP::divint($k, $p);
    }

    foreach my $i (0 .. $#nd) {

        my $np = $nd[$i];
        my $kp = $kd[$i];
        my $rp = Math::Prime::Util::GMP::subint($np, $kp);

        ## say "Lucas theorem: ($np, $kp, $p)";

        if (_is_small_k_binomialmod($np, $kp, $p)) {
            ## say "Optimization: ($np, $kp, $p)";
            my $bin = _small_k_binomialmod($np, $kp, $p);
            $r = Math::Prime::Util::GMP::mulmod($r, $bin, $p);
            next;
        }

        my $x = Math::Prime::Util::GMP::factorialmod($np, $p);
        my $y = Math::Prime::Util::GMP::factorialmod($kp, $p);
        my $z = Math::Prime::Util::GMP::factorialmod($rp, $p);

        $y = Math::Prime::Util::GMP::mulmod($y, $z, $p);
        $x = Math::Prime::Util::GMP::divmod($x, $y, $p) if ($y ne '1');
        $r = Math::Prime::Util::GMP::mulmod($r, $x, $p);
    }

    return $r;
}

sub _modular_binomial {
    my ($n, $k, $m) = @_;

    # Translation of binomod.gp v1.5 by Max Alekseyev, with some extra optimizations.

    # m == 1
    if (Math::GMPz::Rmpz_cmp_ui($m, 1) == 0) {
        return 0;
    }

    # k < 0
    if (Math::GMPz::Rmpz_sgn($k) < 0) {
        $k = $n - $k;
    }

    # k < n-k < 0
    if (Math::GMPz::Rmpz_sgn($k) < 0) {
        return 0;
    }

    # n < 0
    if (Math::GMPz::Rmpz_sgn($n) < 0) {
        my $x = Math::GMPz::Rmpz_even_p($k) ? 1 : -1;
        $x = Math::Prime::Util::GMP::mulint($x, __SUB__->(-$n + $k - 1, $k, $m));
        return Math::Prime::Util::GMP::modint($x, $m);
    }

    # k > n
    if (Math::GMPz::Rmpz_cmp($k, $n) > 0) {
        return 0;
    }

    # k == 0 or k == n
    if (Math::GMPz::Rmpz_sgn($k) == 0 or Math::GMPz::Rmpz_cmp($k, $n) == 0) {
        return Math::Prime::Util::GMP::modint(1, $m);
    }

    # k == 1 or k == n-1
    if (Math::GMPz::Rmpz_cmp_ui($k, 1) == 0 or $k == $n - 1) {
        return Math::Prime::Util::GMP::modint($n, $m);
    }

    # n-k > 0 and n-k < k
    if (Math::GMPz::Rmpz_cmp($n - $k, $k) < 0) {
        $k = $n - $k;
    }

    # k <= 10^4
    if (Math::GMPz::Rmpz_cmp_ui($k, 1e4) <= 0) {
        return Math::Prime::Util::GMP::modint(_small_k_binomialmod($n, $k, $m), $m);
    }

    my @F;

    foreach my $pp (factor_exp(Math::Prime::Util::GMP::absint($m))) {
        my ($p, $q) = @$pp;

        if ($q == 1) {
            push @F, [_lucas_theorem($n, $k, $p), $p];
            next;
        }

        my $pq = Math::Prime::Util::GMP::powint($p, $q);

        # If $n is smaller than the prime power, we can use the small_k algorithm directly
        if (Math::Prime::Util::GMP::cmpint($pq, $n) > 0) {
            push @F, [_small_k_binomialmod($n, $k, $pq, $p), $pq];
            next;
        }

        my $d = logint($n, $p) + 1;

        my (@np, @kp);

        do {
            my $pi = 1;
            foreach my $i (0 .. $d) {
                push @np, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($n, $pi), $p);
                push @kp, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($k, $pi), $p);
                $pi = Math::Prime::Util::GMP::mulint($pi, $p);
            }
        };

        my @e;

        foreach my $i (0 .. $d) {
            $e[$i] = ($np[$i] < ($kp[$i] + (($i > 0) ? $e[$i - 1] : 0))) ? 1 : 0;
        }

        for (my $i = $d - 1 ; $i >= 0 ; --$i) {
            $e[$i] += $e[$i + 1];
        }

        if ($e[0] >= $q) {
            push @F, [0, Math::Prime::Util::GMP::powint($p, $q)];
            next;
        }

        my $rq  = $q - $e[0];
        my $prq = Math::Prime::Util::GMP::powint($p, $rq);

        if (_is_small_k_binomialmod($n, $k, $pq)) {
            ## say "Optimization prime power: ($n, $k, $p, $pq)";
            my $bin = _small_k_binomialmod($n, $k, $pq);
            push @F, [$bin, $pq];
            next;
        }

        my (@N, @K, @R);

        do {
            my $pi = 1;
            my $r  = Math::Prime::Util::GMP::subint($n, $k);
            foreach my $i (0 .. $d) {
                push @N, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($n, $pi), $prq);
                push @K, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($k, $pi), $prq);
                push @R, Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::divint($r, $pi), $prq);
                $pi = Math::Prime::Util::GMP::mulint($pi, $p);
            }
        };

        my @NKR = (
                   sort { $a->[3] <=> $b->[3] }
                   map  { [$N[$_], $K[$_], $R[$_], $N[$_] + $K[$_] + $R[$_]] } 0 .. $#N
                  );

        @N = map { $_->[0] } @NKR;
        @K = map { $_->[1] } @NKR;
        @R = map { $_->[2] } @NKR;

        my @acc  = (1);
        my $nfac = 1;

        if ($prq < ~0 and $p < $n) {
            my $count = 0;
            foreach my $k (1 .. vecmin(vecmax(@N, @K, @R), 1e3)) {
                if (++$count == $p) {
                    $count = 0;
                }
                else {
                    $nfac = mulmod($nfac, $k, $prq);
                }
                push @acc, $nfac;
            }
        }

        my $v = Math::Prime::Util::GMP::powmod($p, $e[0], $pq);

        do {
            my $from  = 0;
            my $count = 0;
            my $res   = 1;

            foreach my $j (0 .. $d) {

                my @pairs;
                my ($x, $y, $z);

                ($x = $acc[$N[$j]]) // push(@pairs, [\$x, $N[$j]]);
                ($y = $acc[$K[$j]]) // push(@pairs, [\$y, $K[$j]]);
                ($z = $acc[$R[$j]]) // push(@pairs, [\$z, $R[$j]]);

                foreach my $pair (sort { $a->[1] <=> $b->[1] } @pairs) {
                    ## say "Factorial($pair->[1]) mod $prq with p = $p";
                    ${$pair->[0]} = _factorial_without_prime($pair->[1], $p, $prq, \$from, \$count, \$res);
                }

                $y = Math::Prime::Util::GMP::mulmod($y, $z, $pq);
                $x = Math::Prime::Util::GMP::divmod($x, $y, $pq) if ($y ne '1');
                $v = Math::Prime::Util::GMP::mulmod($v, $x, $pq);
            }
        };

        if (($p > 2 or $rq < 3) and $q <= scalar(@e)) {
            $v = Math::Prime::Util::GMP::mulmod($v, (($e[$rq - 1] % 2 == 0) ? 1 : -1), $pq);
        }

        push @F, [$v, $pq];
    }

    Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::chinese(@F), $m);
}

sub modular_binomial {
    my ($n, $k, $m) = @_;

    $n = Math::GMPz->new("$n");
    $k = Math::GMPz->new("$k");
    $m = Math::GMPz->new("$m");

    Math::GMPz::Rmpz_sgn($m) || return undef;

    _modular_binomial($n, $k, $m);
}

#
## Run some tests
#

use Test::More tests => 65;

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

is(modular_binomial(1e6, 1e3, powint(2, 128) + 1), binomial(1e6, 1e3) % (powint(2, 128) + 1));
is(modular_binomial(1e6, 1e3, powint(2, 128) - 1), binomial(1e6, 1e3) % (powint(2, 128) - 1));

is(modular_binomial(1e6, 1e4, (powint(2, 128) + 1)**2), binomial(1e6, 1e4) % ((powint(2, 128) + 1)**2));
is(modular_binomial(1e6, 1e4, (powint(2, 128) - 1)**2), binomial(1e6, 1e4) % ((powint(2, 128) - 1)**2));

is(modular_binomial(1e10, 1e4, powint(prev_prime(powint(2, 64)), 2)), test_binomialmod(1e10, 1e4, powint(prev_prime(powint(2, 64)), 2)));
is(modular_binomial(1e10, 1e4, next_prime(powint(2, 64))**2),         test_binomialmod(1e10, 1e4, next_prime(powint(2, 64))**2));

is(modular_binomial(1e10, 1e4, prev_prime(powint(2, 64))), test_binomialmod(1e10, 1e4, prev_prime(powint(2, 64))));
is(modular_binomial(1e10, 1e4, next_prime(powint(2, 64))), test_binomialmod(1e10, 1e4, next_prime(powint(2, 64))));

is(modular_binomial(1e10, 1e3, (powint(2, 127) + 1)), test_binomialmod(1e10, 1e3, powint(2, 127) + 1));
is(modular_binomial(1e10, 1e3, (powint(2, 127) - 1)), test_binomialmod(1e10, 1e3, powint(2, 127) - 1));
is(modular_binomial(1e10, 1e5, (powint(2, 127) - 1)), test_binomialmod(1e10, 1e5, powint(2, 127) - 1));
is(modular_binomial(1e10, 1e5, (powint(2, 127) + 1)), test_binomialmod(1e10, 1e5, powint(2, 127) + 1));

is(modular_binomial(1e10, 1e10 - 1e5, (powint(2, 127) - 1)), test_binomialmod(1e10, 1e5, powint(2, 127) - 1));
is(modular_binomial(1e10, 1e10 - 1e5, (powint(2, 127) + 1)), test_binomialmod(1e10, 1e5, powint(2, 127) + 1));
is(modular_binomial(1e10, 1e10 - 1e5, (powint(2, 127) + 1)**2), test_binomialmod(1e10, 1e5, (powint(2, 127) + 1)**2));

is(modular_binomial(1e10, 1e5, (powint(2, 127) - 1)**2), test_binomialmod(1e10, 1e5, (powint(2, 127) - 1)**2));
is(modular_binomial(1e10, 1e4, (powint(2, 128) - 1)**2), test_binomialmod(1e10, 1e4, (powint(2, 128) - 1)**2));
is(modular_binomial(1e7,  1e5, (powint(2, 128) - 1)**2), test_binomialmod(1e7,  1e5, (powint(2, 128) - 1)**2));

is(modular_binomial(4294967291 + 1, 1e5, powint(4294967291, 2)), test_binomialmod(4294967291 + 1, 1e5, powint(4294967291, 2)));
is(modular_binomial(powint(2, 60) - 99, 1e5, prev_prime(1e9)),           test_binomialmod(powint(2, 60) - 99, 1e5, prev_prime(1e9)));
is(modular_binomial(powint(2, 60) - 99, 1e5, next_prime(powint(2, 64))), test_binomialmod(powint(2, 60) - 99, 1e5, next_prime(powint(2, 64))));

say("binomial(10^10, 10^5) mod 13! = ", modular_binomial(1e10, 1e5, factorial(13)));

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
