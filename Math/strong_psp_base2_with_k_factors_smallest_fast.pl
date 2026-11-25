#!/usr/bin/env perl

# Daniel "Trizen" Șuteu
# https://github.com/trizen
#
# Smallest strong pseudoprime to base 2 with exactly n distinct prime factors
# (OEIS A180065).
#
# Requires Math::Prime::Util >= 0.74 and Math::GMPz.

use v5.36;
use strict;
use warnings;
no warnings 'recursion';

use Math::GMPz        qw(:mpz);
use Math::Prime::Util qw(:all);

sub strong_psp_base2_smallest ($k) {

    die "n must be an integer >= 2\n" if !defined($k) || "$k" !~ /\A\d+\z/ || $k < 2;
    $k = 0 + $k;

    my $force_bits  = 64;
    my $force_count = 16;
    my $force_ratio = 0.75;

    my $TWO  = Rmpz_init_set_ui(2);
    my $ONE  = Rmpz_init_set_ui(1);
    my $NULL = $Math::GMPz::NULL;

    my $bound     = Rmpz_init();
    my $best      = Rmpz_init();
    my $have_best = 0;
    my $gen       = 0;

    # Compact per-class tables. Elements are unsigned 32-bit values while the
    # table fits below 2^32, then upgraded to unsigned 64-bit values.
    my (@class_primes, @class_orders, @wief_idx, @wief_list);
    my $have_primes  = 2;
    my $record_bytes = 4;
    my $pack_fmt     = 'L<';
    my $unpack_fmt   = 'L<';
    my $prime_chunk  = 1_000_000;

    my ($class_exp, $class_res) = (0, 1);

    my ($tmp1, $tmp2, $tmp3, $inv, $cand, $n_minus_1, $prod, $rem_val, $chk1, $chk2) =
      map { Rmpz_init() } 1 .. 10;
    my ($tail_lcm, $tail_prod, $q_hi, $q_lo, $tail_m1, $prog_start, $cand_prod, $prog_step) =
      map { Rmpz_init() } 1 .. 8;
    my ($ord_m, $ord_l, $ord_q, $ord_inv, $ord_tmp, $ord_max_q) =
      map { Rmpz_init() } 1 .. 6;

    my sub record_best ($n) {
        Rmpz_set($best, $n);
        Rmpz_sub_ui($bound, $n, 1);
        $have_best = 1;
        ++$gen;
    }

    my sub upgrade_prime_tables {
        return if $record_bytes == 8;

        for my $t (0 .. $#class_primes) {
            my $old_p = $class_primes[$t] // '';
            my $old_z = $class_orders[$t] // '';
            my $count = int(length($old_p) / 4);
            my ($new_p, $new_z) = ('', '');

            for (my $off = 0 ; $off < $count ; $off += 100_000) {
                my $take = $count - $off;
                $take = 100_000 if $take > 100_000;
                my @p = unpack('L<*', substr($old_p, $off * 4, $take * 4));
                my @z = unpack('L<*', substr($old_z, $off * 4, $take * 4));
                $new_p .= pack('Q<*', @p);
                $new_z .= pack('Q<*', @z);
            }

            $class_primes[$t] = $new_p;
            $class_orders[$t] = $new_z;
        }

        $record_bytes = 8;
        $pack_fmt     = 'Q<';
        $unpack_fmt   = 'Q<';
    }

    my sub prime_at ($t, $i) {
        return unpack($unpack_fmt, substr($class_primes[$t], $i * $record_bytes, $record_bytes));
    }

    my sub order_at ($t, $i) {
        return unpack($unpack_fmt, substr($class_orders[$t], $i * $record_bytes, $record_bytes));
    }

    my sub class_size ($t) {
        return defined($class_primes[$t]) ? int(length($class_primes[$t]) / $record_bytes) : 0;
    }

    my sub mpz_is_prime ($z) {
        my $zs = Rmpz_fits_ulong_p($z) ? Rmpz_get_ui($z) : Rmpz_get_str($z, 10);
        return is_prime($zs);
    }

    my sub in_class_ui ($p) {
        my $tv = valuation($p - 1, 2);
        return 0 if $tv <= $class_exp;
        my $x = powmod(2, ($p - 1) >> ($tv - $class_exp), $p);
        return $class_res == 1 ? ($x == 1) : ($x == $p - 1);
    }

    my sub in_class_mpz ($z) {
        Rmpz_sub_ui($chk1, $z, 1);
        my $tv = Rmpz_scan1($chk1, 0);
        return 0 if $tv <= $class_exp;
        Rmpz_fdiv_q_2exp($chk1, $chk1, $tv - $class_exp);
        Rmpz_powm($chk2, $TWO, $chk1, $z);
        return (Rmpz_cmp_ui($chk2, 1) == 0) if $class_res == 1;
        Rmpz_add_ui($chk2, $chk2, 1);
        return (Rmpz_cmp($chk2, $z) == 0);
    }

    my sub wieferich_exp ($p, $z) {
        if ($p < 4294967296) {
            return 1 if powmod(2, $z, $p * $p) != 1;
        }

        my $pe = Rmpz_init_set_ui($p);
        my $zz = Rmpz_init_set_ui($z);
        my $r  = Rmpz_init();
        my $e  = 1;

        while (1) {
            Rmpz_mul_ui($pe, $pe, $p);
            Rmpz_powm($r, $TWO, $zz, $pe);
            last if Rmpz_cmp_ui($r, 1) != 0;
            ++$e;
        }

        return $e;
    }

    my sub extend_primes ($limit) {
        return if $limit <= $have_primes;

        for (my $lo = $have_primes + 1 ; $lo <= $limit ; $lo += $prime_chunk) {
            my $hi = $lo + $prime_chunk - 1;
            $hi = $limit if $hi > $limit;
            upgrade_prime_tables() if $hi > 0xffffffff && $record_bytes == 4;

            my $list = primes($lo, $hi);
            my (%new_p, %new_z);

            foreach my $p (@$list) {
                my $z = znorder(2, $p);
                my $t = valuation($z, 2);
                $new_p{$t} .= pack($pack_fmt, $p);
                $new_z{$t} .= pack($pack_fmt, $z);
            }

            foreach my $t (keys %new_p) {
                $class_primes[$t] .= $new_p{$t};
                $class_orders[$t] .= $new_z{$t};
            }
        }

        $have_primes = $limit;
    }

    my sub extend_wieferich ($limit) {
        for my $t (0 .. $#class_primes) {
            my $i = $wief_idx[$t] // 0;
            my $n = class_size($t);

            while ($i < $n) {
                my $p = prime_at($t, $i);
                last if $p > $limit;
                my $z = order_at($t, $i);
                my $e = wieferich_exp($p, $z);
                push @wief_list, [$p, $e, $z, $t] if $e > 1;
                ++$i;
            }

            $wief_idx[$t] = $i;
        }
    }

    my sub forbidden_base_prime ($p, $mbase, $L0, $m_nontrivial) {
        return 0 if !$m_nontrivial;
        return 1 if Rmpz_divisible_ui_p($mbase, $p);
        return 1 if Rmpz_divisible_ui_p($L0,    $p);
        return 0;
    }

    my sub class_prefix ($t, $mbase, $L0, $c) {
        my @prefix       = (Rmpz_init_set($mbase));
        my $idx          = 0;
        my $found        = 0;
        my $m_nontrivial = Rmpz_cmp_ui($mbase, 1) > 0 ? 1 : 0;

        while ($found < $c) {
            my $count = class_size($t);

            while ($idx < $count && $found < $c) {
                my $p = prime_at($t, $idx++);
                next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);

                my $ord = order_at($t, $idx - 1);
                next if $m_nontrivial && Rmpz_gcd_ui($NULL, $mbase, $ord) != 1;

                my $z = Rmpz_init();
                Rmpz_mul_ui($z, $prefix[-1], $p);
                return if Rmpz_cmp($z, $bound) > 0;
                push @prefix, $z;
                ++$found;
            }

            last if $found >= $c;

            my $next = $have_primes < 10_000 ? 10_000 : $have_primes * 2;
            extend_primes($next);
        }

        return if $found < $c;
        return \@prefix;
    }

    my sub sieve_for ($prefix, $c) {
        my $limit = Rmpz_init_set_ui(3);

        for my $depth (0 .. $c - 2) {
            Rmpz_fdiv_q($tmp1, $bound, $prefix->[$depth]);
            Rmpz_root($tmp1, $tmp1, $c - $depth);
            Rmpz_set($limit, $tmp1) if Rmpz_cmp($tmp1, $limit) > 0;
        }

        die "Range too large for the native prime table\n" if !Rmpz_fits_ulong_p($limit);

        my $s = Rmpz_get_ui($limit);
        extend_primes($s);
        return $s;
    }

    my sub upper_index ($t, $x) {
        my $n = class_size($t);
        my ($lo, $hi) = (0, $n);
        while ($lo < $hi) {
            my $mid = ($lo + $hi) >> 1;
            if   (prime_at($t, $mid) <= $x) { $lo = $mid + 1 }
            else                            { $hi = $mid }
        }
        return $lo - 1;
    }

    my sub next_allowed_index ($t, $i, $mbase, $L0, $m_nontrivial, $last) {
        my $n = class_size($t);
        while ($i < $n && $i <= $last) {
            my $p = prime_at($t, $i);
            return $i if !forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
            ++$i;
        }
        return $n;
    }

    my sub child_priority ($t, $m, $L, $i, $p, $z, $left, $min_n, $min_n_matters, $mbase, $L0, $m_nontrivial, $bound_ref, $sieve_max) {

        Rmpz_mul_ui($ord_m, $m, $p);
        Rmpz_lcm_ui($ord_l, $L, $z);
        return if Rmpz_cmp($ord_l, $bound_ref) >= 0;
        Rmpz_gcd($ord_tmp, $ord_m, $ord_l);
        return if Rmpz_cmp_ui($ord_tmp, 1) != 0;

        Rmpz_set_ui($ord_q, 1);
        my $idx   = $i + 1;
        my $got   = 0;
        my $count = class_size($t);

        while ($idx < $count && $got < $left) {
            my $j = $idx++;
            my $q = prime_at($t, $j);
            last if $q > $sieve_max;
            next if forbidden_base_prime($q, $mbase, $L0, $m_nontrivial);
            next if Rmpz_gcd_ui($NULL, $ord_m, order_at($t, $j)) != 1;
            Rmpz_mul_ui($ord_q, $ord_q, $q);
            ++$got;
        }
        my $sentinel = $sieve_max + 1;
        while ($got < $left) {
            Rmpz_mul_ui($ord_q, $ord_q, $sentinel);
            ++$got;
        }

        if ($min_n_matters) {
            Rmpz_cdiv_q($ord_tmp, $min_n, $ord_m);
            Rmpz_set($ord_q, $ord_tmp) if Rmpz_cmp($ord_tmp, $ord_q) > 0;
        }

        if (Rmpz_cmp_ui($ord_l, 1) > 0) {
            Rmpz_invert($ord_inv, $ord_m, $ord_l) or return;

            if (Rmpz_cmp($ord_inv, $ord_q) < 0) {
                Rmpz_sub($ord_tmp, $ord_q, $ord_inv);
                Rmpz_cdiv_q($ord_tmp, $ord_tmp, $ord_l);
                Rmpz_addmul($ord_inv, $ord_tmp, $ord_l);
            }

            if (Rmpz_tstbit($ord_l, 0) && !Rmpz_tstbit($ord_inv, 0)) {
                Rmpz_add($ord_inv, $ord_inv, $ord_l);
            }
            Rmpz_set($ord_q, $ord_inv);
        }
        elsif (!Rmpz_tstbit($ord_q, 0)) {
            Rmpz_add_ui($ord_q, $ord_q, 1);
        }

        Rmpz_fdiv_q($ord_max_q, $bound_ref, $ord_m);
        return if Rmpz_cmp($ord_q, $ord_max_q) > 0;

        Rmpz_mul($ord_tmp, $ord_m, $ord_q);
        return Rmpz_get_str($ord_tmp, 10);
    }

    my sub search_combo ($t, $min_n_in, $mbase, $L0, $r, $prefix_override = undef, $sieve_override = undef) {

        my $c = $k - $r;
        return if $c < 2;
        return if Rmpz_cmp($mbase, $bound) > 0;

        my $m_nontrivial = Rmpz_cmp_ui($mbase, 1) > 0 ? 1 : 0;
        Rmpz_gcd($tmp1, $mbase, $L0);
        return if Rmpz_cmp_ui($tmp1, 1) != 0;

        my $prefix = $prefix_override // class_prefix($t, $mbase, $L0, $c);
        return if !$prefix;

        my $min_n         = Rmpz_init_set($min_n_in);
        my $min_n_matters = Rmpz_cmp($min_n, $prefix->[$c]) > 0 ? 1 : 0;
        Rmpz_set($min_n, $prefix->[$c]) if !$min_n_matters;

        my $sieve_max = defined($sieve_override) ? $sieve_override : sieve_for($prefix, $c);
        extend_primes($sieve_max);
        my $nclass = class_size($t);
        return if !$nclass;

        my @M  = map { Rmpz_init() } 0 .. $c;
        my @LL = map { Rmpz_init() } 0 .. $c;
        my @QM = map { Rmpz_init() } 0 .. $c;
        my @QN = map { Rmpz_init() } 0 .. $c;
        my @AQ = map { Rmpz_init() } 0 .. $c;
        Rmpz_set($M[0],  $mbase);
        Rmpz_set($LL[0], $L0);

        my $search = sub ($d, $i0, $rem) {

            my $m    = $M[$d];
            my $L    = $LL[$d];
            my $qmax = $QM[$d];
            my $qmin = $QN[$d];
            my $aq   = $AQ[$d];

            Rmpz_fdiv_q($qmax, $bound, $m);

            Rmpz_root($tmp1, $qmax, $rem);
            my $hi = Rmpz_get_ui($tmp1);
            $hi = $sieve_max if $hi > $sieve_max;

            my $hi_idx = upper_index($t, $hi);
            return if $hi_idx < $i0;

            my $first_idx = next_allowed_index($t, $i0, $mbase, $L0, $m_nontrivial, $hi_idx);
            return if $first_idx > $hi_idx;

            my $lo = prime_at($t, $first_idx);

            Rmpz_set_ui($qmin, 1);
            my $idx = $first_idx;
            my $got = 0;
            while ($idx < $nclass && $got < $rem) {
                my $j = $idx++;
                my $p = prime_at($t, $j);
                last if $p > $sieve_max;
                next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
                next if Rmpz_gcd_ui($NULL, $m, order_at($t, $j)) != 1;
                Rmpz_mul_ui($qmin, $qmin, $p);
                ++$got;
            }
            my $sentinel = $sieve_max + 1;
            while ($got < $rem) {
                Rmpz_mul_ui($qmin, $qmin, $sentinel);
                ++$got;
            }
            return if Rmpz_cmp($qmin, $qmax) > 0;

            if ($min_n_matters) {
                Rmpz_cdiv_q($aq, $min_n, $m);
                Rmpz_set($qmin, $aq) if Rmpz_cmp($aq,   $qmin) > 0;
                return               if Rmpz_cmp($qmin, $qmax) > 0;
            }

            Rmpz_add_ui($qmin, $qmin, 1)
              if Rmpz_cmp_ui($L, 1) == 0
              && !Rmpz_tstbit($qmin, 0);

            my $step_is_2L = 0;
            if (Rmpz_cmp_ui($L, 1) > 0) {
                Rmpz_invert($inv, $m, $L) or return;

                if (Rmpz_cmp($inv, $qmin) < 0) {
                    Rmpz_sub($tmp1, $qmin, $inv);
                    Rmpz_cdiv_q($tmp1, $tmp1, $L);
                    Rmpz_addmul($inv, $tmp1, $L);
                }

                if (Rmpz_tstbit($L, 0)) {
                    $step_is_2L = 1;
                    Rmpz_add($inv, $inv, $L) if !Rmpz_tstbit($inv, 0);
                }
                Rmpz_set($qmin, $inv);
                return if Rmpz_cmp($qmin, $qmax) > 0;
            }

            # Forced completion when few cofactor candidates remain.
            if (Rmpz_cmp_ui($L, 1) > 0) {

                Rmpz_set($inv, $qmin);
                if ($step_is_2L) {
                    Rmpz_mul_2exp($prog_step, $L, 1);
                }
                else {
                    Rmpz_set($prog_step, $L);
                }

                Rmpz_sub($tmp1, $qmax, $inv);
                Rmpz_fdiv_q($tmp1, $tmp1, $prog_step);

                if (Rmpz_fits_ulong_p($tmp1) && Rmpz_sizeinbase($qmax, 2) <= $force_bits) {
                    my $cnt = Rmpz_get_ui($tmp1) + 1;

                    my $thr = $force_count;
                    if ($force_ratio > 0) {
                        my $n_est =
                          $hi > $lo
                          ? ($hi / log($hi) - $lo / log($lo > 2 ? $lo : 3))
                          : 1;
                        $n_est = 1 if $n_est < 1;
                        my $by_cost = $force_ratio * $n_est;
                        $thr = $by_cost if $by_cost > $thr;
                    }

                    if ($cnt <= $thr) {
                        Rmpz_set($cand, $inv);

                        while (Rmpz_cmp($cand, $qmax) <= 0) {
                            my $qs =
                                Rmpz_fits_ulong_p($cand)
                              ? Rmpz_get_ui($cand)
                              : Rmpz_get_str($cand, 10);

                            if (is_rough($qs, $lo) && is_almost_prime($rem, $qs)) {
                                my @f = factor_exp($qs);
                                if (@f == $rem && $f[0][0] >= $lo) {
                                    my $ok = 1;
                                    Rmpz_mul($prod, $m, $cand);
                                    Rmpz_sub_ui($n_minus_1, $prod, 1);

                                    for my $pe (@f) {
                                        my ($s, $e) = @$pe;
                                        if ($e != 1) { $ok = 0; last }
                                        Rmpz_set_str($tmp3, "$s", 10);
                                        if ($m_nontrivial && Rmpz_divisible_p($mbase, $tmp3)) {
                                            $ok = 0;
                                            last;
                                        }
                                        if (!in_class_mpz($tmp3)) { $ok = 0; last }
                                        Rmpz_powm($rem_val, $TWO, $n_minus_1, $tmp3);
                                        if (Rmpz_cmp_ui($rem_val, 1) != 0) { $ok = 0; last }
                                    }

                                    if ($ok) {
                                        record_best($prod);
                                        return;
                                    }
                                }
                            }

                            Rmpz_add($cand, $cand, $prog_step);
                        }
                        return;
                    }
                }
            }

            # Ordinary recursion.
            if ($rem > 2) {

                my $raw_width = $hi_idx - $first_idx + 1;
                if ($rem <= 4 && $raw_width <= 64) {
                    my @choices;

                    for (my $i = $first_idx ; $i <= $hi_idx ; ++$i) {
                        my $p = prime_at($t, $i);
                        next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
                        my $z = order_at($t, $i);
                        next if Rmpz_gcd_ui($NULL, $m, $z) != 1;

                        my $key = child_priority($t, $m, $L, $i, $p, $z, $rem - 1, $min_n, $min_n_matters, $mbase, $L0, $m_nontrivial, $bound, $sieve_max);
                        push @choices, [$key, $i] if defined $key;
                    }

                    @choices = sort { length($a->[0]) <=> length($b->[0]) || $a->[0] cmp $b->[0] } @choices;

                    for my $choice (@choices) {
                        my $i = $choice->[1];
                        my $p = prime_at($t, $i);
                        next if $p > $hi;
                        my $z = order_at($t, $i);

                        Rmpz_lcm_ui($LL[$d + 1], $L, $z);
                        next if Rmpz_cmp($LL[$d + 1], $bound) >= 0;
                        Rmpz_mul_ui($M[$d + 1], $m, $p);
                        Rmpz_gcd($tmp1, $M[$d + 1], $LL[$d + 1]);
                        next if Rmpz_cmp_ui($tmp1, 1) != 0;

                        my $g = $gen;
                        __SUB__->($d + 1, $i + 1, $rem - 1);

                        if ($g != $gen) {
                            Rmpz_fdiv_q($qmax, $bound, $m);
                            Rmpz_root($tmp1, $qmax, $rem);
                            $hi     = Rmpz_get_ui($tmp1);
                            $hi     = $sieve_max if $hi > $sieve_max;
                            $hi_idx = upper_index($t, $hi);
                        }
                    }

                    return;
                }

                my $g = $gen;
                for (my $i = $first_idx ; $i <= $hi_idx ; ++$i) {
                    my $p = prime_at($t, $i);
                    next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
                    my $z = order_at($t, $i);
                    next if Rmpz_gcd_ui($NULL, $m, $z) != 1;

                    Rmpz_lcm_ui($LL[$d + 1], $L, $z);
                    next if Rmpz_cmp($LL[$d + 1], $bound) >= 0;

                    Rmpz_mul_ui($M[$d + 1], $m, $p);
                    Rmpz_gcd($tmp1, $M[$d + 1], $LL[$d + 1]);
                    next if Rmpz_cmp_ui($tmp1, 1) != 0;

                    __SUB__->($d + 1, $i + 1, $rem - 1);

                    if ($g != $gen) {
                        $g = $gen;
                        Rmpz_fdiv_q($qmax, $bound, $m);
                        Rmpz_root($tmp1, $qmax, $rem);
                        $hi     = Rmpz_get_ui($tmp1);
                        $hi     = $sieve_max if $hi > $sieve_max;
                        $hi_idx = upper_index($t, $hi);
                    }
                }

                return;
            }

            # Tail: two primes left, p and terminal prime q.
            for (my $i = $first_idx ; $i <= $hi_idx ; ++$i) {
                my $p = prime_at($t, $i);
                next if forbidden_base_prime($p, $mbase, $L0, $m_nontrivial);
                my $z = order_at($t, $i);

                Rmpz_lcm_ui($tail_lcm, $L, $z);
                Rmpz_mul_ui($tail_prod, $m, $p);

                Rmpz_invert($prog_start, $tail_prod, $tail_lcm) or next;
                Rmpz_fdiv_q_ui($q_hi, $qmax, $p);
                next if Rmpz_cmp($prog_start, $q_hi) > 0;

                if (Rmpz_tstbit($tail_lcm, 0)) {
                    Rmpz_add($prog_start, $prog_start, $tail_lcm) if !Rmpz_tstbit($prog_start, 0);
                    Rmpz_mul_2exp($prog_step, $tail_lcm, 1);
                }
                else {
                    Rmpz_set($prog_step, $tail_lcm);
                }

                Rmpz_set_ui($q_lo, $p + 2);
                if ($min_n_matters) {
                    Rmpz_cdiv_q_ui($tmp2, $aq, $p);
                    Rmpz_set($q_lo, $tmp2) if Rmpz_cmp($tmp2, $q_lo) > 0;
                }

                if (Rmpz_cmp($prog_start, $q_lo) < 0) {
                    Rmpz_sub($tmp2, $q_lo, $prog_start);
                    Rmpz_cdiv_q($tmp2, $tmp2, $prog_step);
                    Rmpz_addmul($prog_start, $tmp2, $prog_step);
                }
                next if Rmpz_cmp($prog_start, $q_hi) > 0;

                Rmpz_sub_ui($tail_m1, $tail_prod, 1);
                my $hit = 0;

                if (Rmpz_fits_ulong_p($tail_m1) && Rmpz_fits_ulong_p($q_hi) && Rmpz_fits_ulong_p($prog_step)) {
                    my ($tn, $hn, $sn, $en) = (Rmpz_get_ui($prog_start), Rmpz_get_ui($q_hi), Rmpz_get_ui($prog_step), Rmpz_get_ui($tail_m1));
                    for (; $tn <= $hn ; $tn += $sn) {
                        if (powmod(2, $en, $tn) == 1 && in_class_ui($tn) && is_prime($tn)) {
                            next if $m_nontrivial && Rmpz_divisible_ui_p($mbase, $tn);
                            Rmpz_mul_ui($cand_prod, $tail_prod, $tn);
                            $hit = 1;
                            last;
                        }
                    }
                }
                else {
                    while (Rmpz_cmp($prog_start, $q_hi) <= 0) {
                        Rmpz_powm($rem_val, $TWO, $tail_m1, $prog_start);
                        if (   Rmpz_cmp_ui($rem_val, 1) == 0
                            && !($m_nontrivial && Rmpz_divisible_p($mbase, $prog_start))
                            && mpz_is_prime($prog_start)
                            && in_class_mpz($prog_start)) {
                            Rmpz_mul($cand_prod, $tail_prod, $prog_start);
                            $hit = 1;
                            last;
                        }
                        Rmpz_add($prog_start, $prog_start, $prog_step);
                    }
                }

                if ($hit) {
                    record_best($cand_prod);

                    Rmpz_fdiv_q($qmax, $bound, $m);
                    Rmpz_root($tmp1, $qmax, 2);
                    $hi     = Rmpz_get_ui($tmp1);
                    $hi     = $sieve_max if $hi > $sieve_max;
                    $hi_idx = upper_index($t, $hi);
                }
            }
        };

        $search->(0, 0, $c);
    }

    my sub search_class ($t, $min_n, $seed_prefix, $seed_sieve) {

        search_combo($t, $min_n, $ONE, $ONE, 0, $seed_prefix, $seed_sieve);

        my @combos = ([$ONE, $ONE, 0]);

        foreach my $w (@wief_list) {
            my ($p, $emax, $z, $wt) = @$w;
            next if $wt != $t;

            my @new;
            foreach my $cb (@combos) {
                my ($m0, $l0, $r) = @$cb;
                for my $e (2 .. $emax) {
                    my $nm = Rmpz_init();
                    Rmpz_ui_pow_ui($nm, $p, $e);
                    Rmpz_mul($nm, $nm, $m0);
                    my $nl = Rmpz_init_set_ui($z);
                    Rmpz_lcm($nl, $nl, $l0);
                    push @new, [$nm, $nl, $r + 1];
                }
            }
            push @combos, @new;
        }

        shift @combos;
        foreach my $cb (@combos) {
            search_combo($t, $min_n, @$cb);
        }
    }

    my @prefix0 = (Rmpz_init_set_ui(1));
    {
        my $p = 2;
        for my $j (1 .. $k) {
            $p = next_prime($p);
            my $z = Rmpz_init();
            Rmpz_mul_ui($z, $prefix0[$j - 1], $p);
            push @prefix0, $z;
        }
    }

    my $lower = Rmpz_init_set($prefix0[$k]);
    my $upper = Rmpz_init();
    Rmpz_mul_2exp($upper, $lower, 1);

    while (1) {

        Rmpz_set($bound, $upper);
        $have_best = 0;

        my $bits  = Rmpz_sizeinbase($bound, 2);
        my $max_t = int(($bits - 1) / $k);

        my (@seed_prefix, @seed_sieve);
        my $global_sieve_max = 3;

        for my $t (0 .. $max_t) {
            last if $t * $k >= Rmpz_sizeinbase($bound, 2);
            if ($t == 0) { ($class_exp, $class_res) = (0, 1) }
            else         { ($class_exp, $class_res) = ($t - 1, -1) }

            my $pref = class_prefix($t, $ONE, $ONE, $k);
            next if !$pref;
            my $s = sieve_for($pref, $k);
            $seed_prefix[$t]  = $pref;
            $seed_sieve[$t]   = $s;
            $global_sieve_max = $s if $s > $global_sieve_max;
        }

        extend_primes($global_sieve_max);
        extend_wieferich($global_sieve_max);

        for my $t (0 .. $max_t) {
            next if !$seed_prefix[$t];
            last if $t * $k >= Rmpz_sizeinbase($bound, 2);
            if ($t == 0) { ($class_exp, $class_res) = (0, 1) }
            else         { ($class_exp, $class_res) = ($t - 1, -1) }
            search_class($t, $lower, $seed_prefix[$t], $seed_sieve[$t]);
        }

        return Rmpz_init_set($best) if $have_best;

        Rmpz_add_ui($lower, $upper, 1);
        Rmpz_mul_2exp($upper, $upper, 1);
    }
}

for my $n (2 .. 12) {
    say "a($n) = ", strong_psp_base2_smallest($n);
}
