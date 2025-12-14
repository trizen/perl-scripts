#!/usr/bin/perl

# kth_root_mod: find all x (0 <= x < m) with x^k ≡ a (mod m)

# Based on code from Math::Prime::Util::PP by Dana Jacobsen.

use 5.036;
use ntheory qw(:all);
use Math::GMPz;
use Test::More tests => 61;

#----------------------------------------------------------
# Tonelli-Shanks algorithm for k-th roots modulo a prime
#----------------------------------------------------------
sub _tonelli_shanks {
    my ($a, $k, $p) = @_;

    my $exp = 0;
    my $q   = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub_ui($q, $p, 1);

    while (Math::GMPz::Rmpz_divisible_p($q, $k)) {
        $exp++;
        Math::GMPz::Rmpz_divexact($q, $q, $k);
    }

    my $k_exp = Math::GMPz::Rmpz_init();
    my $tmp   = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub_ui($tmp, $p, 1);
    Math::GMPz::Rmpz_divexact($k_exp, $tmp, $q);

    my $inv_k   = Math::GMPz::Rmpz_init();
    my $k_mod_q = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mod($k_mod_q, $k, $q);
    Math::GMPz::Rmpz_invert($inv_k, $k_mod_q, $q);

    my $root = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_powm($root, $a, $inv_k, $p);

    my $root_k = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_powm($root_k, $root, $k, $p);

    my $inv_a = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_invert($inv_a, $a, $p);

    my $b = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($b, $root_k, $inv_a);
    Math::GMPz::Rmpz_mod($b, $b, $p);

    # Find a generator of the k-th roots of unity
    my $candidate   = Math::GMPz::Rmpz_init_set_ui(2);
    my $zeta        = Math::GMPz::Rmpz_init_set_ui(1);
    my $gen         = Math::GMPz::Rmpz_init();
    my $k_exp_div_k = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_divexact($k_exp_div_k, $k_exp, $k);

    while (Math::GMPz::Rmpz_cmp_ui($zeta, 1) == 0) {
        Math::GMPz::Rmpz_powm($gen,  $candidate, $q,           $p);
        Math::GMPz::Rmpz_powm($zeta, $gen,       $k_exp_div_k, $p);
        Math::GMPz::Rmpz_add_ui($candidate, $candidate, 1);
    }

    # Iteratively refine the root
    my $new_gen           = Math::GMPz::Rmpz_init();
    my $k_exp_div_k_inner = Math::GMPz::Rmpz_init();
    my $test              = Math::GMPz::Rmpz_init();

    while (Math::GMPz::Rmpz_cmp($k_exp, $k) != 0) {
        Math::GMPz::Rmpz_divexact($k_exp, $k_exp, $k);

        Math::GMPz::Rmpz_powm($new_gen, $gen, $k, $p);
        Math::GMPz::Rmpz_set($candidate, $gen);
        Math::GMPz::Rmpz_set($gen,       $new_gen);

        Math::GMPz::Rmpz_divexact($k_exp_div_k_inner, $k_exp, $k);
        Math::GMPz::Rmpz_powm($test, $b, $k_exp_div_k_inner, $p);

        while (Math::GMPz::Rmpz_cmp_ui($test, 1) != 0) {
            Math::GMPz::Rmpz_mul($root, $root, $candidate);
            Math::GMPz::Rmpz_mod($root, $root, $p);

            Math::GMPz::Rmpz_mul($b, $b, $gen);
            Math::GMPz::Rmpz_mod($b, $b, $p);

            Math::GMPz::Rmpz_mul($test, $test, $zeta);
            Math::GMPz::Rmpz_mod($test, $test, $p);
        }
    }

    return ($root, $gen);    # return both root and zeta (gen)
}

#----------------------------------------------------------
# Chinese Remainder Theorem:   combine roots from two moduli
#----------------------------------------------------------
sub _crt_combine {
    my ($roots_a, $mod_a, $roots_b, $mod_b) = @_;

    state $mod = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($mod, $mod_a, $mod_b);

    state $inv = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_invert($inv, $mod_a, $mod_b)
      or die "CRT: undefined inverse";

    my @roots;
    state $diff   = Math::GMPz::Rmpz_init();
    state $result = Math::GMPz::Rmpz_init();

    for my $ra (@$roots_a) {
        for my $rb (@$roots_b) {
            Math::GMPz::Rmpz_sub($diff, $rb, $ra);
            Math::GMPz::Rmpz_mul($diff, $diff, $inv);
            Math::GMPz::Rmpz_mod($diff, $diff, $mod_b);

            Math::GMPz::Rmpz_mul($result, $mod_a, $diff);
            Math::GMPz::Rmpz_add($result, $result, $ra);
            Math::GMPz::Rmpz_mod($result, $result, $mod);

            push @roots, Math::GMPz::Rmpz_init_set($result);
        }
    }

    return \@roots;
}

#----------------------------------------------------------
# All k-th roots of a modulo prime p
#----------------------------------------------------------
sub _roots_mod_prime {
    my ($a, $k, $p) = @_;

    state $a_mod = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mod($a_mod, $a, $p);

    if (Math::GMPz::Rmpz_cmp_ui($p, 2) == 0 || Math::GMPz::Rmpz_cmp_ui($a_mod, 0) == 0) {
        return [Math::GMPz::Rmpz_init_set($a_mod)];
    }

    state $phi = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub_ui($phi, $p, 1);

    state $g = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_gcd($g, $k, $phi);

    # Unique root when gcd(k, p-1) = 1
    if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
        my $k_mod_phi = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mod($k_mod_phi, $k, $phi);
        my $inv = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_invert($inv, $k_mod_phi, $phi);
        my $root = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_powm($root, $a_mod, $inv, $p);
        return [$root];
    }

    # No roots if a is not a k-th power residue
    state $phi_div_g = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_divexact($phi_div_g, $phi, $g);
    state $test = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_powm($test, $a_mod, $phi_div_g, $p);
    return [] if (Math::GMPz::Rmpz_cmp_ui($test, 1) != 0);

    if (Math::GMPz::Rmpz_cmp_ui($p, 3) == 0) {
        return [Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(2)];
    }

    # Find one root and generate all others using roots of unity
    my ($root, $zeta) = _tonelli_shanks($a_mod, $k, $p);

    if (Math::GMPz::Rmpz_cmp_ui($zeta, 0) == 0) {
        die "Failed to find root";
    }
    state $root_k = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_powm($root_k, $root, $k, $p);
    if (Math::GMPz::Rmpz_cmp($root_k, $a_mod) != 0) {
        die "Failed to find root";
    }

    my @roots = (Math::GMPz::Rmpz_init_set($root));
    my $r     = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($r, $root, $zeta);
    Math::GMPz::Rmpz_mod($r, $r, $p);

    my $k_ui = Math::GMPz::Rmpz_get_ui($k);

    while (Math::GMPz::Rmpz_cmp($r, $root) != 0 && scalar(@roots) < $k_ui) {
        push @roots, Math::GMPz::Rmpz_init_set($r);
        Math::GMPz::Rmpz_mul($r, $r, $zeta);
        Math::GMPz::Rmpz_mod($r, $r, $p);
    }

    return \@roots;
}

#----------------------------------------------------------
# Hensel lifting helpers
#----------------------------------------------------------
sub _hensel_lift_standard {
    my ($roots, $A, $k, $mod) = @_;

    my @result;

    state $k_minus_1 = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub_ui($k_minus_1, $k, 1);

    state $s_pow     = Math::GMPz::Rmpz_init();
    state $deriv     = Math::GMPz::Rmpz_init();
    state $s_k       = Math::GMPz::Rmpz_init();
    state $residue   = Math::GMPz::Rmpz_init();
    state $common    = Math::GMPz::Rmpz_init();
    state $res_div   = Math::GMPz::Rmpz_init();
    state $deriv_div = Math::GMPz::Rmpz_init();
    state $inv_deriv = Math::GMPz::Rmpz_init();
    state $quot      = Math::GMPz::Rmpz_init();
    state $new_s     = Math::GMPz::Rmpz_init();

    for my $s (@$roots) {
        Math::GMPz::Rmpz_powm($s_pow, $s, $k_minus_1, $mod);

        Math::GMPz::Rmpz_mul($deriv, $k, $s_pow);
        Math::GMPz::Rmpz_mod($deriv, $deriv, $mod);

        Math::GMPz::Rmpz_powm($s_k, $s, $k, $mod);

        Math::GMPz::Rmpz_sub($residue, $A, $s_k);
        Math::GMPz::Rmpz_mod($residue, $residue, $mod);
        Math::GMPz::Rmpz_gcd($common, $residue, $deriv);

        Math::GMPz::Rmpz_divexact($res_div,   $residue, $common);
        Math::GMPz::Rmpz_divexact($deriv_div, $deriv,   $common);

        Math::GMPz::Rmpz_invert($inv_deriv, $deriv_div, $mod);

        Math::GMPz::Rmpz_mul($quot, $res_div, $inv_deriv);
        Math::GMPz::Rmpz_mod($quot, $quot, $mod);

        Math::GMPz::Rmpz_add($new_s, $s, $quot);
        Math::GMPz::Rmpz_mod($new_s, $new_s, $mod);

        push @result, Math::GMPz::Rmpz_init_set($new_s);
    }
    return \@result;
}

sub _hensel_lift_singular {
    my ($roots, $A, $k, $p, $mod) = @_;

    state $ext_mod = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($ext_mod, $mod, $p);

    state $submod_val = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_divexact($submod_val, $mod, $p);

    my %seen;

    state $k_minus_1 = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub_ui($k_minus_1, $k, 1);

    state $s_pow     = Math::GMPz::Rmpz_init();
    state $deriv     = Math::GMPz::Rmpz_init();
    state $s_k       = Math::GMPz::Rmpz_init();
    state $residue   = Math::GMPz::Rmpz_init();
    state $common    = Math::GMPz::Rmpz_init();
    state $res_div   = Math::GMPz::Rmpz_init();
    state $deriv_div = Math::GMPz::Rmpz_init();
    state $inv_deriv = Math::GMPz::Rmpz_init();
    state $quot      = Math::GMPz::Rmpz_init();
    state $r         = Math::GMPz::Rmpz_init();
    state $r_k       = Math::GMPz::Rmpz_init();
    state $A_mod     = Math::GMPz::Rmpz_init();
    state $i_val     = Math::GMPz::Rmpz_init();
    state $new_r     = Math::GMPz::Rmpz_init();

    my $k_ui = Math::GMPz::Rmpz_get_ui($k);

    for my $s (@$roots) {
        Math::GMPz::Rmpz_powm($s_pow, $s, $k_minus_1, $ext_mod);

        Math::GMPz::Rmpz_mul($deriv, $k, $s_pow);
        Math::GMPz::Rmpz_mod($deriv, $deriv, $ext_mod);
        Math::GMPz::Rmpz_powm($s_k, $s, $k, $ext_mod);

        Math::GMPz::Rmpz_sub($residue, $A, $s_k);
        Math::GMPz::Rmpz_mod($residue, $residue, $ext_mod);
        Math::GMPz::Rmpz_gcd($common, $residue, $deriv);

        Math::GMPz::Rmpz_divexact($res_div,   $residue, $common);
        Math::GMPz::Rmpz_divexact($deriv_div, $deriv,   $common);

        Math::GMPz::Rmpz_invert($inv_deriv, $deriv_div, $mod);

        Math::GMPz::Rmpz_mul($quot, $res_div, $inv_deriv);
        Math::GMPz::Rmpz_mod($quot, $quot, $mod);

        Math::GMPz::Rmpz_add($r, $s, $quot);
        Math::GMPz::Rmpz_mod($r, $r, $mod);

        Math::GMPz::Rmpz_powm($r_k, $r, $k, $mod);

        Math::GMPz::Rmpz_mod($A_mod, $A, $mod);
        next if (Math::GMPz::Rmpz_cmp($r_k, $A_mod) != 0);

        for my $i (0 .. $k_ui - 1) {
            Math::GMPz::Rmpz_mul_ui($i_val, $submod_val, $i);
            Math::GMPz::Rmpz_mod($i_val, $i_val, $mod);
            Math::GMPz::Rmpz_add_ui($i_val, $i_val, 1);
            Math::GMPz::Rmpz_mod($i_val, $i_val, $mod);

            Math::GMPz::Rmpz_mul($new_r, $r, $i_val);
            Math::GMPz::Rmpz_mod($new_r, $new_r, $mod);

            $seen{Math::GMPz::Rmpz_get_str($new_r, 10)} = Math::GMPz::Rmpz_init_set($new_r);
        }
    }
    return [values %seen];
}

#----------------------------------------------------------
# All k-th roots of r modulo prime power p^e
#----------------------------------------------------------
sub _roots_mod_prime_power {
    my ($r, $k, $p, $e) = @_;

    return _roots_mod_prime($r, $k, $p) if ($e == 1);

    my $mod = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_pow_ui($mod, $p, $e);

    my $k_ui = Math::GMPz::Rmpz_get_ui($k);
    my $pk   = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_pow_ui($pk, $p, $k_ui);

    # Special case:   a ≡ 0 (mod p^e)
    my $r_mod = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mod($r_mod, $r, $mod);
    if (Math::GMPz::Rmpz_cmp_ui($r_mod, 0) == 0) {
        my $t  = int(($e - 1) / $k_ui) + 1;
        my $pt = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_pow_ui($pt, $p, $t);
        my $cnt = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_pow_ui($cnt, $p, $e - $t);
        my $cnt_ui = Math::GMPz::Rmpz_get_ui($cnt);

        my @result;
        my $val = Math::GMPz::Rmpz_init();
        for my $i (0 .. $cnt_ui - 1) {
            Math::GMPz::Rmpz_mul_ui($val, $pt, $i);
            Math::GMPz::Rmpz_mod($val, $val, $mod);
            push @result, Math::GMPz::Rmpz_init_set($val);
        }
        return \@result;
    }

    # Special case:  a ≡ 0 (mod p^k) but a ≢ 0 (mod p^e)
    my $r_mod_pk = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mod($r_mod_pk, $r, $pk);
    if (Math::GMPz::Rmpz_cmp_ui($r_mod_pk, 0) == 0) {

        my $factor = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_pow_ui($factor, $p, ($e - $k_ui) + 1);

        my $count = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_pow_ui($count, $p, $k_ui - 1);

        my $count_ui = Math::GMPz::Rmpz_get_ui($count);
        my $r_div_pk = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_divexact($r_div_pk, $r, $pk);

        my $sub = _roots_mod_prime_power($r_div_pk, $k, $p, $e - $k_ui);

        my @result;
        my $base = Math::GMPz::Rmpz_init();
        my $val  = Math::GMPz::Rmpz_init();

        for my $s (@$sub) {
            Math::GMPz::Rmpz_mul($base, $s, $p);
            Math::GMPz::Rmpz_mod($base, $base, $mod);

            for my $i (0 .. $count_ui - 1) {
                Math::GMPz::Rmpz_mul_ui($val, $factor, $i);
                Math::GMPz::Rmpz_add($val, $val, $base);
                Math::GMPz::Rmpz_mod($val, $val, $mod);
                push @result, Math::GMPz::Rmpz_init_set($val);
            }
        }
        return \@result;
    }

    # No roots if p | a but p^k ∤ a
    my $r_mod_p = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mod($r_mod_p, $r, $p);
    return [] if (Math::GMPz::Rmpz_cmp_ui($r_mod_p, 0) == 0);

    # Hensel lifting from smaller exponent
    my $half =
      (Math::GMPz::Rmpz_cmp_ui($p, 2) > 0 || $e < 5)
      ? int(($e + 1) / 2)
      : int(($e + 3) / 2);

    my $sub = _roots_mod_prime_power($r, $k, $p, $half);

    if (Math::GMPz::Rmpz_cmp($k, $p) != 0) {
        return _hensel_lift_standard($sub, $r, $k, $mod);
    }
    else {
        return _hensel_lift_singular($sub, $r, $k, $p, $mod);
    }
}

#----------------------------------------------------------
# All k-th roots of r modulo n (with factorization)
#----------------------------------------------------------
sub _roots_mod_composite {
    my ($r, $k, $factors) = @_;

    my $mod   = Math::GMPz::Rmpz_init_set_ui(1);
    my $roots = [];
    my $pe    = Math::GMPz::Rmpz_init();

    for my $factor (@$factors) {
        my ($p, $e) = @$factor;

        my $sub = _roots_mod_prime_power($r, $k, $p, $e);
        return [] if (!@$sub);

        Math::GMPz::Rmpz_pow_ui($pe, $p, $e);

        if (@$roots) {
            $roots = _crt_combine($roots, $mod, $sub, $pe);
        }
        else {
            $roots = $sub;
        }
        Math::GMPz::Rmpz_mul($mod, $mod, $pe);
    }
    return $roots;
}

#----------------------------------------------------------
# Main entry point:   all k-th roots of A modulo n
#----------------------------------------------------------
sub kth_root_mod {
    my ($k, $A, $n) = @_;

    $k = Math::GMPz->new($k);
    $A = Math::GMPz->new($A);
    $n = Math::GMPz->new($n);

    Math::GMPz::Rmpz_abs($n, $n);
    return () if (Math::GMPz::Rmpz_cmp_ui($n, 0) == 0);

    Math::GMPz::Rmpz_mod($A, $A, $n);

    if (Math::GMPz::Rmpz_cmp_ui($k, 0) <= 0 && Math::GMPz::Rmpz_cmp_ui($A, 0) == 0) {
        return ();
    }

    if (Math::GMPz::Rmpz_sgn($k) < 0) {
        my $inv = Math::GMPz::Rmpz_init();
        if (!Math::GMPz::Rmpz_invert($inv, $A, $n)) {
            return ();
        }
        my $g = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_gcd($g, $inv, $n);
        return () if (Math::GMPz::Rmpz_cmp_ui($g, 1) != 0);
        Math::GMPz::Rmpz_set($A, $inv);
        Math::GMPz::Rmpz_neg($k, $k);
    }

    if (Math::GMPz::Rmpz_cmp_ui($n, 2) <= 0 || Math::GMPz::Rmpz_cmp_ui($k, 1) == 0) {
        return (Math::GMPz::Rmpz_init_set($A));
    }

    if (Math::GMPz::Rmpz_cmp_ui($k, 0) == 0) {
        if (Math::GMPz::Rmpz_cmp_ui($A, 1) == 0) {
            my $n_ui = Math::GMPz::Rmpz_get_ui($n);
            return (0 .. $n_ui - 1);
        }
        return ();
    }

    my @factors = map { [Math::GMPz->new($_->[0]), $_->[1]] } factor_exp(Math::GMPz::Rmpz_get_str($n, 10));

    my $roots     = [Math::GMPz::Rmpz_init_set($A)];
    my @k_factors = map { Math::GMPz->new($_) } factor(Math::GMPz::Rmpz_get_str($k, 10));

    for my $prime_factor (@k_factors) {
        my @new_roots;
        for my $r (@$roots) {
            my $sub = _roots_mod_composite($r, $prime_factor, \@factors);
            push @new_roots, @$sub;
        }
        $roots = \@new_roots;
    }

    return sort { Math::GMPz::Rmpz_cmp($a, $b) } @$roots;
}

is_deeply([kth_root_mod(3, 2, 101)], [26]);
is_deeply([kth_root_mod(2, 0, 16)],  [0, 4, 8, 12]);
is_deeply([kth_root_mod(2, 1, 101)], [1, 100]);
is_deeply([kth_root_mod(5, 4320, 5040)],
          [120, 330, 540, 750, 960, 1170, 1380, 1590, 1800, 2010, 2220, 2430, 2640, 2850, 3060, 3270, 3480, 3690, 3900, 4110, 4320, 4530, 4740, 4950]);
is_deeply(
          [kth_root_mod(6, 4320, 5040)],
          [30,   60,   90,   120,  150,  180,  240,  270,  300,  330,  360,  390,  450,  480,  510,  540,  570,  600,  660,  690,  720,  750,  780,  810,
           870,  900,  930,  960,  990,  1020, 1080, 1110, 1140, 1170, 1200, 1230, 1290, 1320, 1350, 1380, 1410, 1440, 1500, 1530, 1560, 1590, 1620, 1650,
           1710, 1740, 1770, 1800, 1830, 1860, 1920, 1950, 1980, 2010, 2040, 2070, 2130, 2160, 2190, 2220, 2250, 2280, 2340, 2370, 2400, 2430, 2460, 2490,
           2550, 2580, 2610, 2640, 2670, 2700, 2760, 2790, 2820, 2850, 2880, 2910, 2970, 3000, 3030, 3060, 3090, 3120, 3180, 3210, 3240, 3270, 3300, 3330,
           3390, 3420, 3450, 3480, 3510, 3540, 3600, 3630, 3660, 3690, 3720, 3750, 3810, 3840, 3870, 3900, 3930, 3960, 4020, 4050, 4080, 4110, 4140, 4170,
           4230, 4260, 4290, 4320, 4350, 4380, 4440, 4470, 4500, 4530, 4560, 4590, 4650, 4680, 4710, 4740, 4770, 4800, 4860, 4890, 4920, 4950, 4980, 5010
          ]
         );
is_deeply(
          [kth_root_mod(124, 2016, 5040)],
          [42,   84,   126,  168,  252,  294,  336,  378,  462,  504,  546,  588,  672,  714,  756,  798,  882,  924,  966,  1008, 1092, 1134, 1176, 1218,
           1302, 1344, 1386, 1428, 1512, 1554, 1596, 1638, 1722, 1764, 1806, 1848, 1932, 1974, 2016, 2058, 2142, 2184, 2226, 2268, 2352, 2394, 2436, 2478,
           2562, 2604, 2646, 2688, 2772, 2814, 2856, 2898, 2982, 3024, 3066, 3108, 3192, 3234, 3276, 3318, 3402, 3444, 3486, 3528, 3612, 3654, 3696, 3738,
           3822, 3864, 3906, 3948, 4032, 4074, 4116, 4158, 4242, 4284, 4326, 4368, 4452, 4494, 4536, 4578, 4662, 4704, 4746, 4788, 4872, 4914, 4956, 4998
          ]
         );
is_deeply([kth_root_mod(5, 43,  5040)], [1723]);
is_deeply([kth_root_mod(5, 243, 1000)], [3, 203, 403, 603, 803]);
is_deeply(
          [kth_root_mod(383, 32247425005, 64552988163)],
          [49,          168545710,   337091371,   505637032,   674182693,   842728354,   1011274015,  1179819676,  1348365337,  1516910998,
           1685456659,  1854002320,  2022547981,  2191093642,  2359639303,  2528184964,  2696730625,  2865276286,  3033821947,  3202367608,
           3370913269,  3539458930,  3708004591,  3876550252,  4045095913,  4213641574,  4382187235,  4550732896,  4719278557,  4887824218,
           5056369879,  5224915540,  5393461201,  5562006862,  5730552523,  5899098184,  6067643845,  6236189506,  6404735167,  6573280828,
           6741826489,  6910372150,  7078917811,  7247463472,  7416009133,  7584554794,  7753100455,  7921646116,  8090191777,  8258737438,
           8427283099,  8595828760,  8764374421,  8932920082,  9101465743,  9270011404,  9438557065,  9607102726,  9775648387,  9944194048,
           10112739709, 10281285370, 10449831031, 10618376692, 10786922353, 10955468014, 11124013675, 11292559336, 11461104997, 11629650658,
           11798196319, 11966741980, 12135287641, 12303833302, 12472378963, 12640924624, 12809470285, 12978015946, 13146561607, 13315107268,
           13483652929, 13652198590, 13820744251, 13989289912, 14157835573, 14326381234, 14494926895, 14663472556, 14832018217, 15000563878,
           15169109539, 15337655200, 15506200861, 15674746522, 15843292183, 16011837844, 16180383505, 16348929166, 16517474827, 16686020488,
           16854566149, 17023111810, 17191657471, 17360203132, 17528748793, 17697294454, 17865840115, 18034385776, 18202931437, 18371477098,
           18540022759, 18708568420, 18877114081, 19045659742, 19214205403, 19382751064, 19551296725, 19719842386, 19888388047, 20056933708,
           20225479369, 20394025030, 20562570691, 20731116352, 20899662013, 21068207674, 21236753335, 21405298996, 21573844657, 21742390318,
           21910935979, 22079481640, 22248027301, 22416572962, 22585118623, 22753664284, 22922209945, 23090755606, 23259301267, 23427846928,
           23596392589, 23764938250, 23933483911, 24102029572, 24270575233, 24439120894, 24607666555, 24776212216, 24944757877, 25113303538,
           25281849199, 25450394860, 25618940521, 25787486182, 25956031843, 26124577504, 26293123165, 26461668826, 26630214487, 26798760148,
           26967305809, 27135851470, 27304397131, 27472942792, 27641488453, 27810034114, 27978579775, 28147125436, 28315671097, 28484216758,
           28652762419, 28821308080, 28989853741, 29158399402, 29326945063, 29495490724, 29664036385, 29832582046, 30001127707, 30169673368,
           30338219029, 30506764690, 30675310351, 30843856012, 31012401673, 31180947334, 31349492995, 31518038656, 31686584317, 31855129978,
           32023675639, 32192221300, 32360766961, 32529312622, 32697858283, 32866403944, 33034949605, 33203495266, 33372040927, 33540586588,
           33709132249, 33877677910, 34046223571, 34214769232, 34383314893, 34551860554, 34720406215, 34888951876, 35057497537, 35226043198,
           35394588859, 35563134520, 35731680181, 35900225842, 36068771503, 36237317164, 36405862825, 36574408486, 36742954147, 36911499808,
           37080045469, 37248591130, 37417136791, 37585682452, 37754228113, 37922773774, 38091319435, 38259865096, 38428410757, 38596956418,
           38765502079, 38934047740, 39102593401, 39271139062, 39439684723, 39608230384, 39776776045, 39945321706, 40113867367, 40282413028,
           40450958689, 40619504350, 40788050011, 40956595672, 41125141333, 41293686994, 41462232655, 41630778316, 41799323977, 41967869638,
           42136415299, 42304960960, 42473506621, 42642052282, 42810597943, 42979143604, 43147689265, 43316234926, 43484780587, 43653326248,
           43821871909, 43990417570, 44158963231, 44327508892, 44496054553, 44664600214, 44833145875, 45001691536, 45170237197, 45338782858,
           45507328519, 45675874180, 45844419841, 46012965502, 46181511163, 46350056824, 46518602485, 46687148146, 46855693807, 47024239468,
           47192785129, 47361330790, 47529876451, 47698422112, 47866967773, 48035513434, 48204059095, 48372604756, 48541150417, 48709696078,
           48878241739, 49046787400, 49215333061, 49383878722, 49552424383, 49720970044, 49889515705, 50058061366, 50226607027, 50395152688,
           50563698349, 50732244010, 50900789671, 51069335332, 51237880993, 51406426654, 51574972315, 51743517976, 51912063637, 52080609298,
           52249154959, 52417700620, 52586246281, 52754791942, 52923337603, 53091883264, 53260428925, 53428974586, 53597520247, 53766065908,
           53934611569, 54103157230, 54271702891, 54440248552, 54608794213, 54777339874, 54945885535, 55114431196, 55282976857, 55451522518,
           55620068179, 55788613840, 55957159501, 56125705162, 56294250823, 56462796484, 56631342145, 56799887806, 56968433467, 57136979128,
           57305524789, 57474070450, 57642616111, 57811161772, 57979707433, 58148253094, 58316798755, 58485344416, 58653890077, 58822435738,
           58990981399, 59159527060, 59328072721, 59496618382, 59665164043, 59833709704, 60002255365, 60170801026, 60339346687, 60507892348,
           60676438009, 60844983670, 61013529331, 61182074992, 61350620653, 61519166314, 61687711975, 61856257636, 62024803297, 62193348958,
           62361894619, 62530440280, 62698985941, 62867531602, 63036077263, 63204622924, 63373168585, 63541714246, 63710259907, 63878805568,
           64047351229, 64215896890, 64384442551
          ]
         );

is_deeply(
          [kth_root_mod(3432, 33, 10428581733134514527),],
          [234538669356049904,  265172539733867379,  338494374696194946,  468144956219368759,   587920784072174975,   866212217277838851,
           1191587698502237300, 1469879131707901176, 2012837926243083376, 2116793631583228418,  2246444213106402231,  2616504840673145701,
           2819477257158647081, 2850111127536464556, 2969886955389270772, 3248178388594934648,  3672570580964689435,  3950862014170353311,
           4095753547647065419, 4374044980852729295, 4597776514045680553, 4699420462077127744,  4977711895282791620,  5201443428475742878,
           5227138304658771649, 5450869837851722907, 5729161271057386783, 5830805219088833974,  6054536752281785232,  6332828185487449108,
           6477719718964161216, 6756011152169825092, 7180403344539579879, 7458694777745243755,  7578470605598049971,  7609104475975867446,
           7812076892461368826, 8182137520028112296, 8311788101551286109, 8415743806891431151,  8958702601426613351,  9236994034632277227,
           9562369515856675676, 9840660949062339552, 9960436776915145768, 10090087358438319581, 10163409193400647148, 10194043063778464623
          ]
         );

# Check:
#   p {prime, prime power, square-free composite, non-SF composite}
#   k {prime, prime power, square-free composite, non-SF composite}
my @rootmods = (

    # prime moduli
    [14,    -3, 101,    [17]],
    [13,     6, 107,    [24, 83]],
    [13,    -6, 107,    [49, 58]],
    [64,     6, 101,    [2,  99]],
    [9,     -2, 101,    [34, 67]],
    [2,      3, 3,      [2]],
    [2,      3, 7,      undef],
    [17,    29, 19,     [6]],
    [5,      3, 13,     [7,     8,  11]],
    [53,     3, 151,    [15,    27, 109]],
    [3,      3, 73,     [25,    54, 67]],
    [7,      3, 73,     [13,    29, 31]],
    [49,     3, 73,     [12,    23, 38]],
    [44082,  4, 100003, [2003,  98000]],
    [90594,  6, 100019, [37071, 62948]],
    [6,      5, 31,     [11,    13, 21, 22, 26]],
    [0,      2, 2,      [0]],
    [2,      4, 5,      undef],
    [51,    12, 10009,  [64, 1203, 3183, 3247, 3999, 4807, 5202, 6010, 6762, 6826, 8806, 9945]],

    [15,  3, Math::GMPz->new("1000000000000000000117"), [qw/72574612502199260377 361680004182786118804 565745383315014620936/]],
    [1,   0, 13,                                        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]],
    [2,   0, 13,                                        undef],
    [0,   5, 0,                                         undef],
    [0,  -1, 3,                                         undef],

    # composite moduli.
    # Pari will usually give a *wrong* answer for these if using Mod(a,p).
    # The right way with Pari is to use p-adic.
    [4,  2, 10,   [2, 8]],
    [4,  2, 18,   [2, 16]],
    [2,  3, 21,   undef],                                                # Pari says 2
    [8,  3, 27,   [2,   11,  20]],                                       # Pari says 26
    [22, 3, 1505, [148, 578, 673, 793, 813, 1103, 1243, 1318, 1458]],    # Pari says 1408
    [58787, 3, 100035,
     [3773,  8633,  10793, 13763, 19163, 24293, 26183, 26588, 31313, 37118, 41978, 44138, 47108, 52508,
      57638, 59528, 59933, 64658, 70463, 75323, 77483, 80453, 85853, 90983, 92873, 93278, 98003
     ]
    ],
    [3748, 2, 4992,
     [154,  262,  314,  518,  730,  934,  986,  1094, 1402, 1510, 1562, 1766, 1978, 2182, 2234, 2342,
      2650, 2758, 2810, 3014, 3226, 3430, 3482, 3590, 3898, 4006, 4058, 4262, 4474, 4678, 4730, 4838
     ]
    ],
    [68,           2,  2048, [46,  466, 558, 978,  1070, 1490, 1582, 2002]],
    [96,           5,  128,  [6,   14,  22,  30,   38,   46,   54,   62,   70,   78,   86,   94,   102,  110,  118,  126]],
    [2912,         5,  4992, [182, 494, 806, 1118, 1430, 1742, 2054, 2366, 2678, 2990, 3302, 3614, 3926, 4238, 4550, 4862]],
    [2,            3,  4,    undef],
    [3,            2,  4,    undef],
    [3,            4,  19,   undef],
    [1,            4,  20,   [1, 3, 7,  9, 11, 13, 17, 19]],
    [9,            2,  24,   [3, 9, 15, 21]],
    [6,            6,  35,   undef],
    [36,           2,  40,   [6, 14, 26, 34]],
    [16,           12, 48,   [2, 4,  8,  10, 14, 16, 20, 22, 26, 28, 32, 34, 38, 40, 44, 46]],
    [13,           6,  112,  undef],
    [52,           6,  117,  undef],
    [48,           3,  128,  undef],
    [382,          3,  1000, undef],
    [10,           3,  81,   [13, 40,  67]],
    [26,           5,  625,  [81, 206, 331, 456, 581]],
    [51,           5,  625,  [61, 186, 311, 436, 561]],
    ["9833625071", 3,  "10000000071", [qw/3333332807 6666666164 9999999521/]],

    #[2131968,5,10000000000, [...]],   # Far too many
    [198, -1, 519, undef],
);

foreach my $t (@rootmods) {
    say "Testing: kth_root_mod($t->[1], $t->[0], $t->[2])";
    is_deeply([kth_root_mod($t->[1], $t->[0], $t->[2])], (defined($t->[3]) ? $t->[3] : []));
}

# ----- CLI usage -----
if (@ARGV == 3) {
    my ($k, $v, $m) = @ARGV;
    my @sol = kth_root_mod($k, $v, $m);
    if (!@sol) {
        print "No solution: x^$k ≡ $v (mod $m) has no solution.\n";
    }
    else {
        print scalar(@sol),                        " solution(s) mod $m:\n";
        print join(", ", sort { $a <=> $b } @sol), "\n";
    }
    exit 0;
}
