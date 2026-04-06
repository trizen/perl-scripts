#!/usr/bin/perl

# Fast algorithm for computing the binomial coefficient modulo some integer m.
# Based on Lucas' Theorem and Granville's generalization:
#   Andrew Granville, "The Arithmetic Properties of Binomial Coefficients",
#   Proceedings of the Organic Mathematics Workshop, SFU, December 12-14, 1995.

use 5.036;
use Math::GMPz;
use ntheory 0.74 qw(:all);
use Math::Prime::Util::GMP qw();

prime_set_config(bigint => "Math::BigInt");

#--------------------------------------------------------------------------
# Polynomial helpers (coefficients kept mod pk, degree truncated to < e)
#--------------------------------------------------------------------------

# Multiply two polynomials mod pk, dropping all terms of degree >= e.
sub _poly_mul {
    my ($A, $B, $pk, $e) = @_;
    my @C = (0) x $e;
    for my $i (0 .. $e - 1) {
        next unless $A->[$i];
        for my $j (0 .. $e - 1 - $i) {
            next unless $B->[$j];
            $C[$i + $j] = addmod($C[$i + $j], mulmod($A->[$i], $B->[$j], $pk), $pk);
        }
    }
    return \@C;
}

# Compute B(x) = A(x + h) mod pk, dropping all terms of degree >= e.
sub _poly_shift {
    my ($A, $h_gz, $pk, $e) = @_;
    my @B = (0) x $e;
    for my $j (0 .. $e - 1) {
        next unless $A->[$j];
        my $h_pow = Math::GMPz->new(1);
        for my $i (reverse 0 .. $j) {
            my $term = mulmod(mulmod(binomial($j, $i), $h_pow, $pk), $A->[$j], $pk);
            $B[$i] = addmod($B[$i], $term, $pk);
            $h_pow = mulmod($h_pow, $h_gz, $pk) if $i > 0;
        }
    }
    return \@B;
}

# Compute P(x, q) = product_{i=0}^{q-1} Poly(x + i) mod pk (degree < e),
# using divide-and-conquer in q.
sub _get_P {
    my ($q_gz, $Poly, $pk, $e) = @_;

    return do { my @r = (0) x $e; $r[0] = 1; \@r } if Math::GMPz::Rmpz_cmp_ui($q_gz, 0) == 0;
    return $Poly                                   if Math::GMPz::Rmpz_cmp_ui($q_gz, 1) == 0;

    my $h_gz = Math::GMPz->new(0);
    Math::GMPz::Rmpz_fdiv_q_2exp($h_gz, $q_gz, 1);    # h = floor(q/2)

    my $P_h  = _get_P($h_gz, $Poly, $pk, $e);
    my $P_2h = _poly_mul($P_h, _poly_shift($P_h, $h_gz, $pk, $e), $pk, $e);

    # If q is odd (q = 2h+1), multiply by the extra factor Poly(x + 2h)
    if (Math::GMPz::Rmpz_odd_p($q_gz)) {
        return _poly_mul($P_2h, _poly_shift($Poly, 2 * $h_gz, $pk, $e), $pk, $e);
    }

    return $P_2h;
}

#--------------------------------------------------------------------------
# Factorial-without-prime helpers
#--------------------------------------------------------------------------

# Compute n!_p mod pk (= product of 1..n with multiples of p removed),
# where pk = p^e.  Uses Granville's polynomial method (fast for large n).
sub _factorial_without_prime_pe {
    my ($n, $p, $e, $pk) = @_;

    # Small-n shortcut: direct product
    if (cmpint($n, $p) < 0) {
        my $res = 1;
        $res = mulmod($res, $_, $pk) for 1 .. $n;
        return $res;
    }

    # Step 1: Build Poly(X) mod pk.
    # Start from the expansion log(prod_{j=1}^{p-1}(1 + X/j)), collecting
    # coefficients c[k] of X^k, then scale to Poly[k] = c[k] * (p-1)! * p^k.
    my @c    = (1, (0) x ($e - 1));
    my $fact = 1;                     # accumulates (p-1)! mod pk

    for my $j (1 .. subint($p, 1)) {
        $fact = mulmod($fact, $j, $pk);
        my $inv = invmod($j, $pk);
        for my $k (reverse 1 .. $e - 1) {
            $c[$k] = addmod($c[$k], mulmod($c[$k - 1], $inv, $pk), $pk) if $c[$k - 1];
        }
    }

    my @Poly  = (0) x $e;
    my $p_pow = 1;
    for my $k (0 .. $e - 1) {
        $Poly[$k] = mulmod(mulmod($c[$k], $fact, $pk), $p_pow, $pk);
        $p_pow = mulmod($p_pow, $p, $pk);
    }

    my $q = divint($n, $p);
    my $r = modint($n, $p);

    # Step 2: The constant term of P(0, q) gives the main factor.
    my $q_gz = Math::GMPz::Rmpz_init_set_str("$q", 10);
    my $res  = _get_P($q_gz, \@Poly, $pk, $e)->[0];

    # Step 3: Multiply by the tail (pq+1)(pq+2)...(pq+r).
    if ("$r") {
        my $pq = mulint($q, $p);
        $res = mulmod($res, addint($pq, $_), $pk) for 1 .. "$r";
    }

    return $res;
}

# Compute n!_p mod pk, with an incremental cache ($from, $res) that lets
# successive calls reuse partial products when endpoints are non-decreasing.
sub _factorial_without_prime {
    my ($n, $p, $pk, $from, $res) = @_;

    return 1                     if $n <= 1;
    return factorialmod($n, $pk) if $p > $n;
    return $$res                 if $$from == $n;

    ($$from, $$res) = (0, 1) if $$from > $n;    # cache unusable; reset

    # Fast path for pk = p^2: Harmonic-number expansion, O(p) cost
    # instead of the naive O(p^2).
    if ($p > 2 && cmpint($pk, mulint($p, $p)) == 0) {
        my $a = divint($n, $p);
        my $b = modint($n, $p);

        # H_b = sum_{j=1}^{b} 1/j  mod p
        my $Hb = 0;
        if ($b > 0) {
            $Hb = addmod($Hb, invmod($_, $p), $p) for 1 .. $b;
        }

        my $r = mulmod(powmod(factorialmod(subint($p, 1), $pk), $a, $pk), factorialmod($b, $pk), $pk);

        # Correction term: multiply by (1 + a*p*H_b) mod pk
        if ($a > 0 && $Hb) {
            $r = mulmod($r, addmod(1, mulmod(mulmod($a, $p, $pk), $Hb, $pk), $pk), $pk);
        }

        ($$from, $$res) = ($n, $r);
        return $r;
    }

    # Fast path for pk = p^e, e >= 3: Granville polynomial method
    {
        my $e = valuation($pk, $p);
        if ($e >= 3) {
            my $r = _factorial_without_prime_pe($n, $p, $e, $pk);
            ($$from, $$res) = ($n, $r);
            return $r;
        }
    }

    # O(n) fallback: direct product (only reached when pk is not a prime power)
    my $r = $$res;
    for my $v ($$from + 1 .. $n) {
        $r = mulmod($r, $v, $pk) if $v % $p;
    }
    ($$from, $$res) = ($n, $r);
    return $r;
}

# ---------------------------------------------------------------------------
# Binomial-coefficient helpers
# ---------------------------------------------------------------------------

# Compute C(n, k) mod m via direct numerator/denominator product.
# Tracks p-adic valuation of the result to handle the p-part separately.
sub _small_k_binomialmod {
    my ($n_val, $k_val, $m_val, $p) = @_;

    $n_val = Math::GMPz::Rmpz_init_set_str("$n_val", 10) unless ref($n_val) eq 'Math::GMPz';
    $m_val = Math::GMPz::Rmpz_init_set_str("$m_val", 10) unless ref($m_val) eq 'Math::GMPz';

    # For small k or no prime to track, let GMP compute it directly
    if (!$p or $k_val <= 1e5) {
        my $bin = Math::GMPz::Rmpz_init();
        if (Math::GMPz::Rmpz_fits_ulong_p($n_val) && Math::GMPz::Rmpz_cmp_ui($n_val, 1e5) <= 0) {
            Math::GMPz::Rmpz_bin_uiui($bin, Math::GMPz::Rmpz_get_ui($n_val), $k_val);
        }
        else {
            Math::GMPz::Rmpz_bin_ui($bin, $n_val, $k_val);
        }
        Math::GMPz::Rmpz_mod($bin, $bin, $m_val);
        return $bin;
    }

    # Track the net p-adic valuation v across numerator and denominator,
    # keeping running products reduced mod m to avoid huge intermediate values.
    my $v = 0;
    state $num_mult = Math::GMPz::Rmpz_init_nobless();
    state $den_mult = Math::GMPz::Rmpz_init_nobless();
    state $temp     = Math::GMPz::Rmpz_init_nobless();
    state $p_z      = Math::GMPz::Rmpz_init_nobless();

    Math::GMPz::Rmpz_set_ui($num_mult, 1);
    Math::GMPz::Rmpz_set_ui($den_mult, 1);
    Math::GMPz::Rmpz_set_ui($p_z,      $p);

    for my $i (0 .. $k_val - 1) {
        Math::GMPz::Rmpz_sub_ui($temp, $n_val, $i);

        if (Math::GMPz::Rmpz_divisible_ui_p($temp, $p)) {
            $v += Math::GMPz::Rmpz_remove($temp, $temp, $p_z);
        }

        Math::GMPz::Rmpz_mul($num_mult, $num_mult, $temp);
        Math::GMPz::Rmpz_mod($num_mult, $num_mult, $m_val);

        my $den = $i + 1;
        if ($den % $p == 0) {
            Math::GMPz::Rmpz_set_ui($temp, $den);
            $v -= Math::GMPz::Rmpz_remove($temp, $temp, $p_z);
            $den = Math::GMPz::Rmpz_get_ui($temp);
        }

        Math::GMPz::Rmpz_mul_ui($den_mult, $den_mult, $den);
        Math::GMPz::Rmpz_mod($den_mult, $den_mult, $m_val);
    }

    Math::GMPz::Rmpz_invert($temp, $den_mult, $m_val);
    my $ans = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($ans, $num_mult, $temp);
    Math::GMPz::Rmpz_mod($ans, $ans, $m_val);

    if ($v > 0) {
        Math::GMPz::Rmpz_powm_ui($temp, $p_z, $v, $m_val);
        Math::GMPz::Rmpz_mul($ans, $ans, $temp);
        Math::GMPz::Rmpz_mod($ans, $ans, $m_val);
    }

    return $ans;
}

# Heuristic: is computing C(n, k) mod m via direct product likely cheaper
# than going through the full Granville machinery?
sub _is_small_k_binomialmod {
    my ($n, $k, $m) = @_;

    $n >= 1e6 or return;
    return 1 if $m >= 1e7 && $n >= 1e7 && $k <= 1e6;

    my $sym_k = subint($n, $k);
    $k = $sym_k if $sym_k > 0 && $sym_k < $k;

    $k <= 1e7 or return;

    sqrtint($m) > $k
      && divint($m, $n) > $k;
}

# Lucas' theorem: C(n, k) mod p for prime p, evaluated digit by digit in base p.
sub _lucas_theorem {
    my ($n, $k, $p) = @_;
    my $r = 1;

    while ($k) {
        my $np = modint($n, $p);
        my $kp = modint($k, $p);

        return 0 if $kp > $np;

        if ($kp > 0) {
            if (_is_small_k_binomialmod($np, $kp, $p)) {
                $r = mulmod($r, _small_k_binomialmod($np, $kp, $p), $p);
            }
            else {
                my $nf = factorialmod($np, $p);
                my $df =
                  mulmod(factorialmod($kp, $p), factorialmod($np - $kp, $p), $p);
                $r = mulmod($r, ($df ne '1' ? divmod($nf, $df, $p) : $nf), $p);
            }
        }

        $n = divint($n, $p);
        $k = divint($k, $p);
    }

    return $r;
}

# ---------------------------------------------------------------------------
# Core implementation
# ---------------------------------------------------------------------------

sub _modular_binomial {
    my ($n, $k, $m) = @_;

    return 0 if Math::GMPz::Rmpz_cmp_ui($m, 1) == 0;

    # Negative k: apply upper-negation identity C(n,k) = C(n, n-k) when k < 0
    if (Math::GMPz::Rmpz_sgn($k) < 0) {
        my $tmp = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub($tmp, $n, $k);
        Math::GMPz::Rmpz_set($k, $tmp);
    }
    return 0 if Math::GMPz::Rmpz_sgn($k) < 0;

    # Negative n: C(n,k) = (-1)^k * C(-n+k-1, k)
    if (Math::GMPz::Rmpz_sgn($n) < 0) {
        my $sign  = Math::GMPz::Rmpz_even_p($k) ? 1 : -1;
        my $abs_n = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_neg($abs_n, $n);
        Math::GMPz::Rmpz_add($abs_n, $abs_n, $k);
        Math::GMPz::Rmpz_sub_ui($abs_n, $abs_n, 1);
        return modint(mulint($sign, __SUB__->($abs_n, $k, $m)), $m);
    }

    return 0 if Math::GMPz::Rmpz_cmp($k, $n) > 0;

    # Trivial boundary cases
    return modint(1, $m)
      if Math::GMPz::Rmpz_sgn($k) == 0 || Math::GMPz::Rmpz_cmp($k, $n) == 0;

    {
        my $n1 = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub_ui($n1, $n, 1);
        return modint($n, $m)
          if Math::GMPz::Rmpz_cmp_ui($k, 1) == 0 || Math::GMPz::Rmpz_cmp($k, $n1) == 0;
    }

    # Exploit symmetry C(n,k) = C(n, n-k) to keep k <= n/2
    {
        my $n_minus_k = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub($n_minus_k, $n, $k);
        Math::GMPz::Rmpz_set($k, $n_minus_k) if Math::GMPz::Rmpz_cmp($n_minus_k, $k) < 0;
    }

    return modint(_small_k_binomialmod($n, $k, $m), $m)
      if Math::GMPz::Rmpz_cmp_ui($k, 1e4) <= 0;

    # General case: factor m into prime powers, solve each via Granville's
    # method, then combine with CRT.
    my @F;
    for my $pp (factor_exp(absint($m))) {
        my ($p, $q) = @$pp;

        if ($q == 1) {
            push @F, [_lucas_theorem($n, $k, $p), $p];
            next;
        }

        my $pq = powint($p, $q);

        if (cmpint($p, $n) > 0) {
            push @F, [_small_k_binomialmod($n, $k, $pq, $p), $pq];
            next;
        }

        my $d = logint($n, $p) + 1;

        # Base-p digits of n and k (one digit per level, accumulated mod p)
        my (@np, @kp);
        {
            my $pi = 1;
            for my $i (0 .. $d) {
                push @np, modint(divint($n, $pi), $p);
                push @kp, modint(divint($k, $pi), $p);
                $pi = mulint($pi, $p);
            }
        }

        # Kummer's theorem: e[i] = number of carries at position i and above
        # when adding k and (n-k) in base p.
        my @e;
        for my $i (0 .. $d) {
            $e[$i] = ($np[$i] < ($kp[$i] + ($i > 0 ? $e[$i - 1] : 0))) ? 1 : 0;
        }
        for (my $i = $d - 1 ; $i >= 0 ; --$i) {
            $e[$i] += $e[$i + 1];
        }

        # If total carries >= q, the result is divisible by p^q, i.e., 0 mod p^q
        if ($e[0] >= $q) {
            push @F, [0, $pq];
            next;
        }

        my $rq  = $q - $e[0];
        my $prq = powint($p, $rq);

        if (_is_small_k_binomialmod($n, $k, mulint($p, $q))) {
            push @F, [_small_k_binomialmod($n, $k, $pq), $pq];
            next;
        }

        # Digits of n, k, r = n-k mod p^rq at each level
        my (@N, @K, @R);
        {
            my $pi = 1;
            my $r  = subint($n, $k);
            for my $i (0 .. $d) {
                push @N, modint(divint($n, $pi), $prq);
                push @K, modint(divint($k, $pi), $prq);
                push @R, modint(divint($r, $pi), $prq);
                $pi = mulint($pi, $p);
            }
        }

        # Sort triples by N+K+R so _factorial_without_prime's cache is maximally reused
        {
            my @idx = sort { ($N[$a] + $K[$a] + $R[$a]) <=> ($N[$b] + $K[$b] + $R[$b]) } 0 .. $#N;
            @N = @N[@idx];
            @K = @K[@idx];
            @R = @R[@idx];
        }

        # Precompute small factorial-without-p values into a lookup table
        my %acc  = ('0' => 1);
        my $nfac = 1;
        if ($prq < ~0 && $p < $n) {
            for my $v (1 .. vecmin(vecmax(@N, @K, @R), 1e3)) {
                $nfac = mulmod($nfac, $v, $prq) if $v % $p;
                $acc{$v} = $nfac;
            }
        }

        my $v = powmod($p, $e[0], $pq);

        {
            my ($from, $res_cache) = (0, 1);

            for my $j (0 .. $d) {
                my @pairs;
                my ($x, $y, $z);

                ($x = $acc{$N[$j]}) // push @pairs, [\$x, $N[$j]];
                ($y = $acc{$K[$j]}) // push @pairs, [\$y, $K[$j]];
                ($z = $acc{$R[$j]}) // push @pairs, [\$z, $R[$j]];

                # Process missing entries in ascending order to benefit the cache
                for my $pair (sort { $a->[1] <=> $b->[1] } @pairs) {
                    ${$pair->[0]} = _factorial_without_prime($pair->[1], $p, $prq, \$from, \$res_cache);
                }

                $y = mulmod($y, $z, $pq);
                $x = divmod($x, $y, $pq) if $y ne '1';
                $v = mulmod($v, $x, $pq);
            }
        }

        # Wilson's theorem sign correction
        if (($p > 2 || $rq < 3) && $rq <= scalar(@e)) {
            $v = mulmod($v, $e[$rq - 1] % 2 == 0 ? 1 : -1, $pq);
        }

        push @F, [$v, $pq];
    }

    Math::Prime::Util::GMP::modint(Math::Prime::Util::GMP::chinese(@F), $m);
}

# ---------------------------------------------------------------------------
# Public interface
# ---------------------------------------------------------------------------

sub modular_binomial {
    my ($n, $k, $m) = @_;

    $n = Math::GMPz->new("$n");
    $k = Math::GMPz->new("$k");
    $m = Math::GMPz->new("$m");

    return undef unless Math::GMPz::Rmpz_sgn($m);

    _modular_binomial($n, $k, $m);
}

use Math::Sidef qw();

sub test_binomialmod($n, $k, $m) {
    Math::Sidef::binomialmod($n, $k, $m);
}

#
## Run some tests
#

use Test::More tests => 103;

for my $e (1 .. 5) {
    my $n = powint(2,                33) + int rand 1234;
    my $k = powint(2,                32) - int rand 1234;
    my $m = powint(2 + int rand 100, $e);
    say "binomialmod($n,$k,$m) = ", modular_binomial($n, $k, $m);
    is(modular_binomial($n, $k, $m), test_binomialmod($n, $k, $m));
}

is(modular_binomial(8589934703, 4294966460, 4182119424),          4133348352);
is(modular_binomial(8589934823, 4294966769, 52521875),            26643750);
is(modular_binomial(8589935272, 429496,     "97656250000000000"), "57900778336640000");
is(modular_binomial(8589935272, 4294965,    "97656250000000000"), "96886205280000000");
is(modular_binomial(8589935272, 4294966820, "97656250000000000"), "55077260000000000");
is(modular_binomial(8589935272, 42949658,   "97656250000000000"), "46773145040000000");

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

is(binomialmod(0, 0, 7), 1);
is(modular_binomial(0,         1,        7),          0);
is(modular_binomial(0,         2,        7),          0);
is(modular_binomial(3,         0,        7),          1);
is(modular_binomial(7,         5,        11),         10);
is(modular_binomial(950,       100,      123456),     24942);
is(modular_binomial(950,       100,      7),          2);
is(modular_binomial(8100,      4000,     1155),       924);
is(modular_binomial(950,       100,      1000000007), 640644226);
is(modular_binomial(189,       34,       877),        81);
is(modular_binomial(189,       34,       253009),     47560);
is(modular_binomial(189,       34,       36481),      14169);
is(modular_binomial(1900,      17,       41),         0);
is(modular_binomial(5000,      654,      101223721),  59171352);
is(modular_binomial(-112,      5,        351),        313);
is(modular_binomial(-189,      34,       877),        141);
is(modular_binomial(-23,       -29,      377),        117);
is(modular_binomial(189,       -34,      877),        0);
is(modular_binomial(100000000, 87654321, 1005973),    937361);
is(modular_binomial(100000000, 7654321,  1299709),    582708);
is(modular_binomial(100000000, 7654321,  12345678),   4152168);
is(modular_binomial(100000,    7654,     32768),      12288);
is(modular_binomial(100000,    7654,     196608),     110592);
is(modular_binomial(100000,    7654,     101223721),  5918452);
is(modular_binomial(100000000, 7654321,  32768),      24576);
is(modular_binomial(100000000, 7654321,  196608),     122880);
is(modular_binomial(100000000, 7654321,  101223721),  5463123);

say("binomial(10^10, 10^5) mod 13! = ", modular_binomial(1e10, 1e5, factorial(13)));
