#!/usr/bin/perl

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

# Pollard's rho for discrete logarithm in a group of prime order
# Returns x such that g^x = h (mod n) where g has order p (prime)
sub _pollard_rho_log ($g, $h, $p, $n, $max_tries = 10) {

    # Trivial cases
    if (Math::GMPz::Rmpz_cmp_ui($h, 1) == 0) {
        return Math::GMPz::Rmpz_init_set_ui(0);
    }
    if (Math::GMPz::Rmpz_cmp($g, $h) == 0) {
        return Math::GMPz::Rmpz_init_set_ui(1);
    }

    state $rng = Math::GMPz::zgmp_randinit_default();

    my $tmp = Math::GMPz::Rmpz_init();
    my $a1  = Math::GMPz::Rmpz_init();
    my $b1  = Math::GMPz::Rmpz_init();
    my $x1  = Math::GMPz::Rmpz_init();
    my $a2  = Math::GMPz::Rmpz_init();
    my $b2  = Math::GMPz::Rmpz_init();
    my $x2  = Math::GMPz::Rmpz_init();

    my $da = Math::GMPz::Rmpz_init();
    my $db = Math::GMPz::Rmpz_init();

    my $invdb = Math::GMPz::Rmpz_init();

    # Floyd's cycle detection
    my $iter = sub {
        my ($a, $b, $x) = @_;
        my $r = Math::GMPz::Rmpz_mod_ui($tmp, $x, 3);
        if ($r == 0) {
            Math::GMPz::Rmpz_add_ui($a, $a, 1);
            Math::GMPz::Rmpz_mod($a, $a, $p);
            Math::GMPz::Rmpz_mul($x, $x, $g);
            Math::GMPz::Rmpz_mod($x, $x, $n);
        }
        elsif ($r == 1) {
            Math::GMPz::Rmpz_add_ui($b, $b, 1);
            Math::GMPz::Rmpz_mod($b, $b, $p);
            Math::GMPz::Rmpz_mul($x, $x, $h);
            Math::GMPz::Rmpz_mod($x, $x, $n);
        }
        else {
            Math::GMPz::Rmpz_mul_2exp($a, $a, 1);
            Math::GMPz::Rmpz_mod($a, $a, $p);
            Math::GMPz::Rmpz_mul_2exp($b, $b, 1);
            Math::GMPz::Rmpz_mod($b, $b, $p);
            Math::GMPz::Rmpz_mul($x, $x, $x);
            Math::GMPz::Rmpz_mod($x, $x, $n);
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
sub _prime_power_log ($a, $g, $n, $p, $e, $full_order) {

    my $L = $full_order;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_pow_ui($r, $p, $e);    # p^e
    Math::GMPz::Rmpz_tdiv_q($r, $L, $r);    # r = L / p^e

    my $g0 = Math::GMPz::Rmpz_init();
    my $a0 = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_powm($g0, $g, $r, $n);
    Math::GMPz::Rmpz_powm($a0, $a, $r, $n);

    my $x     = Math::GMPz::Rmpz_init_set_ui(0);
    my $cur_g = Math::GMPz::Rmpz_init_set($g0);
    my $cur_a = Math::GMPz::Rmpz_init_set($a0);
    my $f     = Math::GMPz::Rmpz_init_set_ui(1);    # multiplier for current digit

    for (my $i = 0 ; $i < $e ; $i++) {
        my $exp = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_pow_ui($exp, $p, $e - $i - 1);    # p^(e-1-i)

        my $sub_g = Math::GMPz::Rmpz_init();
        my $sub_a = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_powm($sub_g, $cur_g, $exp, $n);
        Math::GMPz::Rmpz_powm($sub_a, $cur_a, $exp, $n);

        my $d = _pollard_rho_log($sub_g, $sub_a, $p, $n);
        return (undef, 0) unless defined $d;

        # x += d * f
        my $tmp = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul($tmp, $d, $f);
        Math::GMPz::Rmpz_add($x, $x, $tmp);

        # f *= p
        Math::GMPz::Rmpz_mul_ui($f, $f, $p);

        # Remove the found part: cur_a = cur_a * inv(cur_g^d) mod n
        Math::GMPz::Rmpz_powm($tmp, $cur_g, $d, $n);
        Math::GMPz::Rmpz_invert($tmp, $tmp, $n) || return (undef, 0);
        Math::GMPz::Rmpz_mul($cur_a, $cur_a, $tmp);
        Math::GMPz::Rmpz_mod($cur_a, $cur_a, $n);

        # Next generator: cur_g = cur_g^p mod n
        Math::GMPz::Rmpz_powm($cur_g, $cur_g, $p, $n);
    }
    return ($x, 1);
}

sub discrete_log($a, $g, $n, $order = undef) {

    $a = Math::GMPz->new("$a");
    $g = Math::GMPz->new("$g");
    $n = Math::GMPz->new("$n");

    # Normalise inputs
    $a %= $n;
    $g %= $n;

    # g must be invertible modulo n
    if (gcd($g, $n) != 1) {
        return undef;
    }

    # Determine the order of g if not provided
    $order //= znorder($g, $n) // return undef;

    $order = Math::GMPz->new("$order");

    # Quick necessary condition: a must lie in the subgroup generated by g
    if (powmod($a, $order, $n) != 1) {
        return undef;
    }

    # Trivial cases
    if ($order == 1) {
        return ($a == 1 ? 0 : undef);
    }

    # Factor the order into prime powers
    my @factors = factor_exp($order);

    # Solve for x modulo each prime power
    my @residues;

    foreach my $pp (@factors) {
        my ($p, $e) = @$pp;
        $p = Math::GMPz->new("$p");
        my ($x, $ok) = _prime_power_log($a, $g, $n, $p, $e, $order);
        $ok || return undef;
        push @residues, [$x, powint($p, $e)];
    }

    # Combine via CRT
    my $x = chinese(@residues);

    # Verify the result (should always hold if the algorithm succeeded)
    (powmod($g, $x, $n) == $a) ? $x : undef;
}

use Test::More tests => 9;

is(discrete_log(5678,                       5,                                        10007),                      8620);
is(discrete_log("232752345212475230211680", "23847293847923847239847098123812075234", "804842536444911030681947"), 13);

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
