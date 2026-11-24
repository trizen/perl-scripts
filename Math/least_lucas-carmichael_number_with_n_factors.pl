#!/usr/bin/perl

# Generate the least Lucas-Carmichael number with n prime factors.
# https://oeis.org/A216928

use 5.036;
use strict;
use warnings;

no warnings 'recursion';

use Math::GMPz             qw(:mpz);
use Math::Prime::Util      qw(factor_exp is_prime primes);
use Math::Prime::Util::GMP ();

sub least_lucas_carmichael ($target_n) {
    my sub new_z () { Rmpz_init() }

    my @primes_odd;

    my $lower       = new_z();
    my $upper       = new_z();
    my $upper_plus1 = new_z();
    my $best        = new_z();
    my $have_best   = 0;

    my @product_at_depth = map { new_z() } 0 .. $target_n;
    my @lcm_at_depth     = map { new_z() } 0 .. $target_n;
    my @min_completion   = map { new_z() } 0 .. $target_n;

    Rmpz_set_ui($product_at_depth[0], 1);
    Rmpz_set_ui($lcm_at_depth[0],     1);

    my ($q_min, $q_max, $next_prime_max, $gcd_scratch, $best_q_max)                          = map { new_z() } 1 .. 5;
    my ($p_max, $p_min, $residue, $step, $terminal_t, $m_minus1, $terminal_p, $terminal_pp1) = map { new_z() } 1 .. 8;
    my ($forced_q_min, $forced_q_max, $forced_t, $forced_step, $forced_first, $forced_q)     = map { new_z() } 1 .. 6;
    my ($full_lcm, $factor_plus1, $candidate_n, $candidate_np1)                              = map { new_z() } 1 .. 4;
    my @forced_factors = map { new_z() } 0 .. $target_n;

    my $tmp = new_z();

    my sub test_forced_product ($m, $old_lcm, $q, $remaining, $smallest_factor) {
        return if Rmpz_sgn($q) <= 0;

        my @factorization = factor_exp(Math::GMPz::Rmpz_get_str($q, 10));
        return unless @factorization == $remaining;

        for my $i (0 .. $#factorization) {
            my ($factor, $exponent) = @{$factorization[$i]};
            return unless $exponent == 1;
            Rmpz_set_str($forced_factors[$i], "$factor", 10);
            return if Rmpz_cmp_ui($forced_factors[$i], $smallest_factor) < 0;
        }

        Rmpz_set($full_lcm, $old_lcm);
        for my $i (0 .. $remaining - 1) {
            Rmpz_add_ui($factor_plus1, $forced_factors[$i], 1);
            Rmpz_lcm($full_lcm, $full_lcm, $factor_plus1);
            return if Rmpz_cmp($full_lcm, $upper_plus1) > 0;
        }

        Rmpz_mul($candidate_n, $m, $q);
        return if Rmpz_cmp($candidate_n, $lower) < 0;
        return if Rmpz_cmp($candidate_n, $upper) > 0;

        Rmpz_add_ui($candidate_np1, $candidate_n, 1);
        return unless Rmpz_divisible_p($candidate_np1, $full_lcm);

        if (!$have_best || Rmpz_cmp($candidate_n, $best) < 0) {
            Rmpz_set($best, $candidate_n);
            $have_best = 1;
        }

        return 1;
    }

    my sub try_forced_completion ($m, $old_lcm, $smallest_factor, $remaining, $q_min_in, $q_max_in) {
        return 0 if Rmpz_cmp_ui($old_lcm, 1) <= 0;
        return 0 if Rmpz_sgn($q_max_in) <= 0;

        Rmpz_set($forced_q_min, $q_min_in);
        Rmpz_set($forced_q_max, $q_max_in);

        Rmpz_cdiv_q($forced_t, $lower, $m);
        Rmpz_set($forced_q_min, $forced_t)
          if Rmpz_cmp($forced_q_min, $forced_t) < 0;

        return 1 if Rmpz_cmp($forced_q_min, $forced_q_max) > 0;

        Rmpz_set($forced_step, $old_lcm);

        Rmpz_invert($forced_first, $m, $old_lcm)
          or die "No modular inverse for m modulo old_lcm\n";
        Rmpz_sub($forced_first, $old_lcm, $forced_first);

        if (Rmpz_cmp($forced_first, $forced_q_min) < 0) {
            Rmpz_sub($forced_t, $forced_q_min, $forced_first);
            Rmpz_cdiv_q($forced_t, $forced_t, $forced_step);
            Rmpz_addmul($forced_first, $forced_t, $forced_step);
        }

        return 1 if Rmpz_cmp($forced_first, $forced_q_max) > 0;

        Rmpz_sub($forced_t, $forced_q_max, $forced_first);
        Rmpz_fdiv_q($forced_t, $forced_t, $forced_step);

        return 0 if Rmpz_sizeinbase($forced_q_max, 2) > 64;
        return 0 if Rmpz_cmp_ui($forced_t, 16 - 1) > 0;

        Rmpz_set($forced_q, $forced_first);

        while (Rmpz_cmp($forced_q, $forced_q_max) <= 0) {
            if ($have_best) {
                Rmpz_mul($forced_t, $m, $forced_q);
                last if Rmpz_cmp($forced_t, $best) >= 0;
            }

            test_forced_product($m, $old_lcm, $forced_q, $remaining, $smallest_factor);
            Rmpz_add($forced_q, $forced_q, $forced_step);
        }

        return 1;
    }

    my sub search_dfs ($m, $old_lcm, $smallest_factor, $prime_index, $remaining, $depth) {
        if ($remaining == 1) {
            Rmpz_fdiv_q($p_max, $upper, $m);
            Rmpz_sub_ui($terminal_t, $m, 2);
            Rmpz_set($p_max, $terminal_t) if Rmpz_cmp($p_max, $terminal_t) > 0;

            if ($have_best) {
                Rmpz_sub_ui($terminal_t, $best, 1);
                Rmpz_fdiv_q($terminal_t, $terminal_t, $m);
                Rmpz_set($p_max, $terminal_t)
                  if Rmpz_cmp($terminal_t, $p_max) < 0;
            }

            Rmpz_cdiv_q($p_min, $lower, $m);
            Rmpz_set_ui($p_min, $smallest_factor)
              if Rmpz_cmp_ui($p_min, $smallest_factor) < 0;
            return if Rmpz_cmp($p_min, $p_max) > 0;

            Rmpz_invert($residue, $m, $old_lcm)
              or die "No modular inverse for m modulo old_lcm\n";
            Rmpz_sub($residue, $old_lcm, $residue);
            Rmpz_set($step, $old_lcm);

            if (Rmpz_cmp($residue, $p_min) < 0) {
                Rmpz_sub($terminal_t, $p_min, $residue);
                Rmpz_cdiv_q($terminal_t, $terminal_t, $step);
                Rmpz_addmul($residue, $terminal_t, $step);
            }

            return if Rmpz_cmp($residue, $p_max) > 0;

            Rmpz_sub_ui($m_minus1, $m, 1);

            if (   Rmpz_fits_ulong_p($p_max)
                && Rmpz_fits_ulong_p($step)) {
                my $p  = Rmpz_get_ui($residue);
                my $hi = Rmpz_get_ui($p_max);
                my $by = Rmpz_get_ui($step);

                while (1) {
                    if (Rmpz_divisible_ui_p($m_minus1, $p + 1) && is_prime($p)) {
                        Rmpz_mul_ui($best, $m, $p);
                        $have_best = 1;
                        last;
                    }

                    last if $by > $hi - $p;
                    $p += $by;
                }
            }
            else {
                Rmpz_set($terminal_p, $residue);

                while (Rmpz_cmp($terminal_p, $p_max) <= 0) {
                    Rmpz_add_ui($terminal_pp1, $terminal_p, 1);

                    if (Rmpz_divisible_p($m_minus1, $terminal_pp1) && is_prime($terminal_p)) {
                        Rmpz_mul($best, $m, $terminal_p);
                        $have_best = 1;
                        last;
                    }

                    Rmpz_add($terminal_p, $terminal_p, $step);
                }
            }

            return;
        }

        Rmpz_set_ui($q_min, 1);
        for my $i ($prime_index .. $prime_index + $remaining - 1) {
            return if $i > $#primes_odd;

            Rmpz_mul_ui($q_min, $q_min, $primes_odd[$i]);
            return if Rmpz_cmp($q_min, $upper) > 0;
        }

        Rmpz_fdiv_q($q_max, $upper, $m);
        if ($have_best) {
            Rmpz_sub_ui($best_q_max, $best, 1);
            Rmpz_fdiv_q($best_q_max, $best_q_max, $m);
            Rmpz_set($q_max, $best_q_max) if Rmpz_cmp($best_q_max, $q_max) < 0;
        }

        return if Rmpz_cmp($q_min, $q_max) > 0;

        return if try_forced_completion($m, $old_lcm, $smallest_factor, $remaining, $q_min, $q_max);

        Rmpz_root($next_prime_max, $q_max, $remaining);
        return if Rmpz_cmp_ui($next_prime_max, $smallest_factor) < 0;

        die "Internal error: DFS prime bound exceeds the native sieve range\n"
          unless Rmpz_fits_ulong_p($next_prime_max);
        my $p_max_native = Rmpz_get_ui($next_prime_max);

        my $child_m   = $product_at_depth[$depth + 1];
        my $child_lcm = $lcm_at_depth[$depth + 1];
        my $min_full  = $min_completion[$depth];
        my $last      = $#primes_odd;

        for (my $i = $prime_index ; $i <= $last ; ++$i) {
            my $p = $primes_odd[$i];
            last if $p > $p_max_native;

            my $p_plus1 = $p + 1;

            next if Rmpz_gcd_ui($gcd_scratch, $m, $p_plus1) != 1;

            Rmpz_lcm_ui($child_lcm, $old_lcm, $p_plus1);
            next if Rmpz_cmp($child_lcm, $upper_plus1) > 0;

            Rmpz_mul_ui($child_m, $m, $p);

            Rmpz_set($min_full, $child_m);
            my $impossible = 0;

            for my $j ($i + 1 .. $i + $remaining - 1) {
                if ($j > $last) {
                    $impossible = 1;
                    last;
                }

                Rmpz_mul_ui($min_full, $min_full, $primes_odd[$j]);
                if (Rmpz_cmp($min_full, $upper) > 0) {
                    $impossible = 1;
                    last;
                }
            }

            last if $impossible;

            __SUB__->($child_m, $child_lcm, $p + 1, $i + 1, $remaining - 1, $depth + 1);

            last if $have_best && Rmpz_cmp($min_full, $best) >= 0;
        }
    }

    my @first_primes;
    for (my $p = 3 ; @first_primes < $target_n ; $p += 2) {
        push @first_primes, $p if is_prime($p);
    }

    my @prefix_product = map { new_z() } 0 .. $target_n;
    Rmpz_set_ui($prefix_product[0], 1);

    for my $i (1 .. $target_n) {
        Rmpz_mul_ui($prefix_product[$i], $prefix_product[$i - 1], $first_primes[$i - 1]);
    }

    Rmpz_set($lower, $prefix_product[$target_n]);
    Rmpz_mul_2exp($upper, $lower, 1);

    while (1) {
        Rmpz_add_ui($upper_plus1, $upper, 1);

        my $sieve_limit = $first_primes[-1];

        for my $depth (0 .. $target_n - 2) {
            my $remaining = $target_n - $depth;

            Rmpz_fdiv_q($tmp, $upper, $prefix_product[$depth]);
            Rmpz_root($tmp, $tmp, $remaining);

            die "The required prime sieve limit exceeds the native integer range\n"
              unless Rmpz_fits_ulong_p($tmp);

            my $limit = Rmpz_get_ui($tmp);
            $sieve_limit = $limit if $limit > $sieve_limit;
        }

        my $sieve_max = $sieve_limit;
        my $extra     = 0;
        my $candidate = $sieve_limit + 1;

        ++$candidate if ($candidate & 1) == 0;

        while ($extra < $target_n + 2) {
            if (is_prime($candidate)) {
                $sieve_max = $candidate;
                ++$extra;
            }
            $candidate += 2;
        }

        @primes_odd = @{primes(3, $sieve_max)};

        $have_best = 0;

        search_dfs($product_at_depth[0], $lcm_at_depth[0], 3, 0, $target_n, 0);

        if ($have_best) {
            return Rmpz_get_str($best, 10);
        }

        Rmpz_add_ui($lower, $upper, 1);
        Rmpz_mul_2exp($upper, $upper, 1);
    }
}

say least_lucas_carmichael($ARGV[0] // die "usage: $0 [n]\n");
