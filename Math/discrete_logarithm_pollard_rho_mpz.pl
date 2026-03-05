#!/usr/bin/perl

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

# Pollard's rho for discrete logarithm in a group of prime order
# Returns x such that g^x = h (mod n) where g has order p (prime)
sub _znlog_pollard_rho($g, $h, $p, $n, $max_tries = 10) {

    # Trivial cases
    if (Math::GMPz::Rmpz_cmp_ui($h, 1) == 0) {
        return Math::GMPz::Rmpz_init_set_ui(0);
    }
    if (Math::GMPz::Rmpz_cmp($g, $h) == 0) {
        return Math::GMPz::Rmpz_init_set_ui(1);
    }

    # For very small prime orders, use brute-force
    if (Math::GMPz::Rmpz_cmp_ui($p, 100) <= 0) {
        my $t = Math::GMPz::Rmpz_init_set_ui(1);
        for my $i (0 .. Math::GMPz::Rmpz_get_ui($p) - 1) {
            if (Math::GMPz::Rmpz_cmp($t, $h) == 0) {
                return Math::GMPz::Rmpz_init_set_ui($i);
            }
            Math::GMPz::Rmpz_mul($t, $t, $g);
            Math::GMPz::Rmpz_mod($t, $t, $n);
        }
        return undef;
    }

    state $rng = Math::GMPz::zgmp_randinit_default_nobless();

    state $tmp = Math::GMPz::Rmpz_init_nobless();
    state $a1  = Math::GMPz::Rmpz_init_nobless();
    state $b1  = Math::GMPz::Rmpz_init_nobless();
    state $x1  = Math::GMPz::Rmpz_init_nobless();
    state $a2  = Math::GMPz::Rmpz_init_nobless();
    state $b2  = Math::GMPz::Rmpz_init_nobless();
    state $x2  = Math::GMPz::Rmpz_init_nobless();

    state $da = Math::GMPz::Rmpz_init_nobless();
    state $db = Math::GMPz::Rmpz_init_nobless();

    state $invdb = Math::GMPz::Rmpz_init_nobless();

    # Floyd's cycle detection
    my $iter = sub {
        my ($a, $b, $x) = @_;
        my $r = Math::GMPz::Rmpz_mod_ui($tmp, $x, 3);
        if ($r == 0) {
            Math::GMPz::Rmpz_add_ui($a, $a, 1);
            Math::GMPz::Rmpz_mul($x, $x, $g);
            Math::GMPz::Rmpz_mod($x, $x, $n);
        }
        elsif ($r == 1) {
            Math::GMPz::Rmpz_add_ui($b, $b, 1);
            Math::GMPz::Rmpz_mul($x, $x, $h);
            Math::GMPz::Rmpz_mod($x, $x, $n);
        }
        else {
            Math::GMPz::Rmpz_mul_2exp($a, $a, 1);
            Math::GMPz::Rmpz_mul_2exp($b, $b, 1);
            Math::GMPz::Rmpz_mod($a, $a, $p);
            Math::GMPz::Rmpz_mod($b, $b, $p);
            Math::GMPz::Rmpz_powm_ui($x, $x, 2, $n);
        }
    };

    foreach my $attempt (1 .. $max_tries) {

        # Random starting point (a,b) with X = g^a * h^b
        Math::GMPz::Rmpz_urandomm($a1, $b1, $rng, $p, 2);    # 0 <= a1 < p

        Math::GMPz::Rmpz_powm($x1,  $g, $a1, $n);            # g^a1 mod n
        Math::GMPz::Rmpz_powm($tmp, $h, $b1, $n);            # h^b1 mod n
        Math::GMPz::Rmpz_mul($x1, $x1, $tmp);
        Math::GMPz::Rmpz_mod($x1, $x1, $n);

        # Hare starts same as tortoise
        Math::GMPz::Rmpz_set($a2, $a1);
        Math::GMPz::Rmpz_set($b2, $b1);
        Math::GMPz::Rmpz_set($x2, $x1);

        while (1) {

            # Tortoise step
            $iter->($a1, $b1, $x1);

            # Hare step (two iterations)
            $iter->($a2, $b2, $x2);
            $iter->($a2, $b2, $x2);

            if (Math::GMPz::Rmpz_cmp($x1, $x2) == 0) {

                # Collision: g^{a1} h^{b1} = g^{a2} h^{b2}
                Math::GMPz::Rmpz_sub($da, $a1, $a2);
                Math::GMPz::Rmpz_mod($da, $da, $p);

                Math::GMPz::Rmpz_sub($db, $b2, $b1);
                Math::GMPz::Rmpz_mod($db, $db, $p);

                if (Math::GMPz::Rmpz_sgn($db) == 0) {
                    last;    # degenerate case, restart
                }

                Math::GMPz::Rmpz_invert($invdb, $db, $p) || last;

                my $x = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_mul($x, $da, $invdb);
                Math::GMPz::Rmpz_mod($x, $x, $p);

                # Verify
                Math::GMPz::Rmpz_powm($tmp, $g, $x, $n);
                if (Math::GMPz::Rmpz_cmp($tmp, $h) == 0) {
                    return $x;
                }
                last;    # verification failed, restart
            }
        }
    }
    return undef;
}

# Solve g^x = a (mod n) where g has order exactly p^e * r,
# and we want x modulo p^e.
sub _znlog_prime_power($a, $g, $n, $p, $e, $full_order) {

    my $L = $full_order;
    state $r = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_pow_ui($r, $p, $e);    # p^e
    Math::GMPz::Rmpz_tdiv_q($r, $L, $r);    # r = L / p^e

    state $g0 = Math::GMPz::Rmpz_init_nobless();
    state $a0 = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_powm($g0, $g, $r, $n);
    Math::GMPz::Rmpz_powm($a0, $a, $r, $n);

    my $x = Math::GMPz::Rmpz_init_set_ui(0);

    state $cur_g = Math::GMPz::Rmpz_init_nobless();
    state $cur_a = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_set($cur_g, $g0);
    Math::GMPz::Rmpz_set($cur_a, $a0);

    state $f = Math::GMPz::Rmpz_init_nobless();    # multiplier for current digit
    Math::GMPz::Rmpz_set_ui($f, 1);

    state $tmp   = Math::GMPz::Rmpz_init_nobless();
    state $sub_g = Math::GMPz::Rmpz_init();
    state $sub_a = Math::GMPz::Rmpz_init();

    foreach my $i (0 .. $e - 1) {

        Math::GMPz::Rmpz_pow_ui($tmp, $p, $e - $i - 1);    # p^(e-1-i)
        Math::GMPz::Rmpz_powm($sub_g, $cur_g, $tmp, $n);
        Math::GMPz::Rmpz_powm($sub_a, $cur_a, $tmp, $n);

        my $d = _znlog_pollard_rho($sub_g, $sub_a, $p, $n) // return undef;

        # x += d * f
        Math::GMPz::Rmpz_mul($tmp, $d, $f);
        Math::GMPz::Rmpz_add($x, $x, $tmp);

        # f *= p
        Math::GMPz::Rmpz_mul($f, $f, $p);

        # Remove the found part: cur_a = cur_a * inv(cur_g^d) mod n
        Math::GMPz::Rmpz_powm($tmp, $cur_g, $d, $n);
        Math::GMPz::Rmpz_invert($tmp, $tmp, $n) || return undef;
        Math::GMPz::Rmpz_mul($cur_a, $cur_a, $tmp);
        Math::GMPz::Rmpz_mod($cur_a, $cur_a, $n);

        # Next generator: cur_g = cur_g^p mod n
        Math::GMPz::Rmpz_powm($cur_g, $cur_g, $p, $n);
    }
    return $x;
}

# Solve g^x = a (mod n) where gcd(g, n) = 1, using Pohlig-Hellman over order of g.
# Suitable when n is a prime power (or when called per prime-power factor of n).
sub _znlog_coprime_prime_power($a, $g, $n) {

    my $order = Math::GMPz->new((znorder($g, $n) // return undef));

    state $tmp   = Math::GMPz::Rmpz_init_nobless();
    state $p_mpz = Math::GMPz::Rmpz_init_nobless();

    # Quick necessary condition: a must lie in the subgroup generated by g
    Math::GMPz::Rmpz_powm($tmp, $a, $order, $n);
    if (Math::GMPz::Rmpz_cmp_ui($tmp, 1) != 0) {
        return undef;
    }

    # Trivial case
    if (Math::GMPz::Rmpz_cmp_ui($order, 1) == 0) {
        if (Math::GMPz::Rmpz_cmp_ui($a, 1) == 0) {
            return 0;
        }
        return undef;
    }

    # Factor the order into prime powers and solve for each
    my @factors  = factor_exp($order);
    my @residues = ();

    foreach my $pp (@factors) {
        my ($p, $e) = @$pp;
        Math::GMPz::Rmpz_set_str($p_mpz, $p, 10);
        my $x = _znlog_prime_power($a, $g, $n, $p_mpz, $e, $order) // return undef;
        push @residues, [$x, powint($p, $e)];
    }

    # Combine via CRT
    my $x = chinese(@residues) // return undef;

    # Verify
    Math::GMPz::Rmpz_set_str($tmp, $x, 10);
    Math::GMPz::Rmpz_powm($tmp, $g, $tmp, $n);
    if (Math::GMPz::Rmpz_cmp($tmp, $a) == 0) {
        return $x;
    }
    return undef;
}

sub _znlog_pohlig_hellman {
    my ($a, $g, $n, $order) = @_;

    state $tmp = Math::GMPz::Rmpz_init_nobless();

    Math::GMPz::Rmpz_gcd($tmp, $g, $n);

    # Handle non-coprime case: gcd(g, n) > 1
    if (Math::GMPz::Rmpz_cmp_ui($tmp, 1) != 0) {

        my $g_pow = Math::GMPz::Rmpz_init_set_ui(1);    # g^k mod n (original n), for direct equality check
        my $n_red = Math::GMPz::Rmpz_init_set($n);      # modulus being reduced
        my $a_red = Math::GMPz::Rmpz_init_set($a);      # target being reduced
        my $d_acc = Math::GMPz::Rmpz_init_set_ui(1);    # accumulated product: (g/D_1)*(g/D_2)*...*(g/D_k) mod n_red

        my $k = 0;
        while (1) {

            Math::GMPz::Rmpz_gcd($tmp, $g, $n_red);
            Math::GMPz::Rmpz_cmp_ui($tmp, 1) == 0 and last;

            # Check if g^k already equals a (mod n)
            if (Math::GMPz::Rmpz_cmp($g_pow, $a) == 0) {
                return $k;
            }

            Math::GMPz::Rmpz_divisible_p($a_red, $tmp) || return undef;

            Math::GMPz::Rmpz_div($n_red, $n_red, $tmp);
            Math::GMPz::Rmpz_div($a_red, $a_red, $tmp);

            Math::GMPz::Rmpz_div($tmp, $g, $tmp);
            Math::GMPz::Rmpz_mul($d_acc, $d_acc, $tmp);
            Math::GMPz::Rmpz_mul($g_pow, $g_pow, $g);
            Math::GMPz::Rmpz_mod($d_acc, $d_acc, $n_red);
            Math::GMPz::Rmpz_mod($g_pow, $g_pow, $n);

            ++$k;
        }

        # Final direct check after stripping
        if (Math::GMPz::Rmpz_cmp($g_pow, $a) == 0) {
            return $k;
        }

        # Phase 2: gcd(g, n_red) = 1 now; solve g^y = a_red * inv(d_acc) (mod n_red)
        Math::GMPz::Rmpz_invert($tmp, $d_acc, $n_red) || return undef;
        Math::GMPz::Rmpz_mul($tmp, $tmp, $a_red);

        my $new_a = Math::GMPz::Rmpz_init();
        my $new_g = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_mod($new_a, $tmp, $n_red);
        Math::GMPz::Rmpz_mod($new_g, $g,   $n_red);

        my $y = __SUB__->($new_a, $new_g, $n_red) // return undef;

        return ($y + $k);
    }

    # Coprime case: gcd(g, n) = 1

    # Factor n into prime powers
    my @n_factors = factor_exp($n);

    # Composite n: solve g^x = a (mod p^e) for each prime-power factor, then CRT
    my @residues = ();

    state $pe  = Math::GMPz::Rmpz_init();
    state $g_i = Math::GMPz::Rmpz_init();
    state $a_i = Math::GMPz::Rmpz_init();

    foreach my $pp (@n_factors) {
        my ($p, $e) = @$pp;

        Math::GMPz::Rmpz_set_str($pe, $p, 10);
        Math::GMPz::Rmpz_pow_ui($pe, $pe, $e);
        Math::GMPz::Rmpz_mod($g_i, $g, $pe);
        Math::GMPz::Rmpz_mod($a_i, $a, $pe);

        my $r     = _znlog_coprime_prime_power($a_i, $g_i, $pe) // return undef;
        my $ord_i = znorder($g_i, $pe)                          // return undef;

        push @residues, [$r, $ord_i];
    }

    my $x = Math::GMPz::Rmpz_init_set_str((chinese(@residues) // return undef), 10);

    # Verify the result
    Math::GMPz::Rmpz_set_str($tmp, $x, 10);
    Math::GMPz::Rmpz_powm($tmp, $g, $tmp, $n);
    if (Math::GMPz::Rmpz_cmp($tmp, $a) == 0) {
        return Math::GMPz::Rmpz_init_set_str($x, 10);
    }

    return undef;
}

sub discrete_log {
    my ($a, $g, $n) = @_;

    $a = Math::GMPz->new("$a");
    $g = Math::GMPz->new("$g");
    $n = Math::GMPz->new("$n");

    my $sgn = Math::GMPz::Rmpz_sgn($n) || return undef;

    if ($sgn < 0) {
        $n = Math::GMPz::Rmpz_init_set($n);
        Math::GMPz::Rmpz_abs($n, $n);
    }

    if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0) {
        return 0;
    }

    $a = Math::GMPz::Rmpz_init_set($a);    # copy
    $g = Math::GMPz::Rmpz_init_set($g);    # copy

    Math::GMPz::Rmpz_mod($a, $a, $n);
    Math::GMPz::Rmpz_mod($g, $g, $n);

    if (   Math::GMPz::Rmpz_cmp_ui($a, 1) == 0
        or Math::GMPz::Rmpz_cmp_ui($g, 0) == 0) {
        return 0;
    }

    my $res = _znlog_pohlig_hellman($a, $g, $n) // return undef;
    return join '', $res;
}

use Test::More tests => 1309;

is(discrete_log(5678, 5, 10007), 8620);

foreach my $test (
                  [[5675,              5,      10000019],          2003974],            # 5675 = 5^2003974 mod 10000019
                  [[18478760,          5,      314138927],         34034873],
                  [[553521,            459996, 557057],            15471],
                  [[7443282,           4,      13524947],          6762454],
                  [[32712908945642193, 5,      71245073933756341], 5945146967010377],
  ) {
    my ($t, $v) = @$test;
    say "Testing: discrete_log(", join(', ', @$t), ") = ", $v;
    is(discrete_log($t->[0], $t->[1], $t->[2]), $v);
}

is_deeply(
          [map { discrete_log(powint(2, $_) - 5, 3, powint(2, $_ + 1)) } 0 .. 35],
          [undef,  0,       undef,    1,        7,        3,         27,       43,        75,        139,        11,         779,
           267,    1291,    3339,     7435,     32011,    48395,     81163,    146699,    277771,    15627,      1588491,    2637067,
           539915, 4734219, 13122827, 63454475, 29900043, 231226635, 97008907, 902315275, 365444363, 1439186187, 3586669835, 7881637131
          ]
         );

is_deeply([map { discrete_log(-1, 3, powint(3, $_) - 2) // 0 } 2 .. 30],
          [3, 10, 39, 60, 121, 0, 117, 4920, 0, 0, 0, 28322, 0, 1434890, 0, 0, 0, 116226146, 0, 0, 15690529803, 0, 108443565, 66891206007, 0, 0, 0, 0, 0]);

# Non-coprime tests
is(discrete_log(36, 44, 50), 2);    # 44^2 = 1936 = 36 (mod 50), gcd(44,50)=2
is(discrete_log(0,  2,  4),  2);    # 2^2 = 4 = 0 (mod 4)
is(discrete_log(4,  6,  8),  2);    # 6^2 = 36 = 4 (mod 8)

# Composite modulus, coprime base
is(discrete_log(130, 85, 177), 15);    # 177 = 3*59, gcd(85,177)=1
is(discrete_log(100, 52, 209), 10);    # 209 = 11*19, 52^10 = 100 (mod 209)

# Verify no-solution cases still return undef
is(discrete_log(3, 4, 6), undef);      # no solution exists

is(discrete_log(1, 2, 7), 0);
is(discrete_log(2, 2, 7), 1);
is(discrete_log(4, 2, 7), 2);
is(discrete_log(1, 3, 7), 0);

is(discrete_log(3, 2, 5), 3);          # 2^3 mod 5 = 3
is(discrete_log(4, 2, 5), 2);

is(discrete_log(2,     4,     7),      2);
is(discrete_log(4,     5,     7),      2);
is(discrete_log(5,     3,     7),      5);
is(discrete_log(130,   85,    177),    15);
is(discrete_log(79,    92,    129),    2);
is(discrete_log(115,   116,   141),    26);
is(discrete_log(67741, 90737, 120309), 146);
is(discrete_log(12,    42,    122),    13);
is(discrete_log(36,    44,    50),     2);
is(discrete_log(34,    170,   187),    5);

# Small modulus cycles

is(discrete_log(8, 2, 11), 3);
is(discrete_log(5, 2, 11), 4);
is(discrete_log(9, 3, 11), 2);

# Edge cases

is(discrete_log(1, 1, 13), 0);
is(discrete_log(1, 5, 13), 0);

# g == a
is(discrete_log(7, 7, 19), 1);

# modulus 2
is(discrete_log(1, 1, 2), 0);

# Non-prime modulus

is(discrete_log(4, 2, 15), 2);    # 2^2 = 4 mod 15
is(discrete_log(1, 4, 9),  0);

# Cases where solution may not exist

is(discrete_log(3, 4, 7), undef);
is(discrete_log(3, 2, 4), undef);
is(discrete_log(6, 4, 8), undef);

# Verify correctness by recomputing power

for my $n (7, 11, 13, 17) {
    for my $g (2 .. $n - 1) {
        for my $k (0 .. $n - 1) {

            my $a = powmod($g, $k, $n);
            my $r = discrete_log($a, $g, $n);

            ok(defined($r), "discrete_log($a, $g, $n)");
            is(powmod($g, $r, $n), $a) if defined($r);
        }
    }
}

# Randomized tests

for (1 .. 100) {
    my $n = urandomm(200000 - 50000) + 50000;
    my $g = urandomm($n - 2) + 2;
    my $k = urandomm(50000);

    my $a = powmod($g, $k, $n);
    my $r = discrete_log($a, $g, $n);

    ok(defined($r), "discrete_log($a, $g, $n)");
    is(powmod($g, $r, $n), $a) if defined($r);
}

# Computationally intensive tests

my $p = 1000003;
my $g = 2;
my $k = 123456;

my $a = powmod($g, $k, $p);

is(powmod($g, discrete_log($a, $g, $p), $p), $a);

# Larger exponent

my $k2 = 654321;
my $a2 = powmod($g, $k2, $p);

is(powmod($g, discrete_log($a2, $g, $p), $p), $a2);

# Large prime modulus stress test

my $p2 = 10000019;
my $g2 = 2;
my $k3 = 777777;

my $a3 = powmod($g2, $k3, $p2);

is(powmod($g2, discrete_log($a3, $g2, $p2), $p2), $a3);
