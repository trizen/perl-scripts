#!/usr/bin/env perl

# Daniel "Trizen" Șuteu
# Date: 12 November 2026
# Edit: 19 November 2026 (Carmichael numbers that are multiples of a given value m)
# https://github.com/trizen

# Generate all Carmichael numbers with exactly k distinct prime factors
# in the inclusive interval [A, B] that are divisible by a given value m, using
# Korselt's criterion:
#
#   n = p_1 * ... * p_k  (distinct odd primes, k >= 3)  is a Carmichael number
#   iff  (p_i - 1) | (n - 1)  for every i.
#
# Usage:
#   perl carmichael_multiples_in_range_mpz_fast.pl [options] A B k [m]
#
# With m = 1 (the default) all the k-factor Carmichael numbers in [A, B] are
# generated.  The prime factors of m count towards the k prime factors of n.
#
# Options:
#   --force-bits=N    Factor cofactors only when q_max has at most N bits
#                     (default: 64; 0 disables forced completion)
#   --force-count=N   Always factor directly when at most N candidates remain
#                     (default: 16; 0 disables forced completion)
#   --force-ratio=X   Also factor directly whenever the number of candidates is
#                     at most X * (estimated number of primes the ordinary loop
#                     would visit) (default: 0.75; 0 = use only --force-count)
#   --step-div=N      Use the divisors of (m-1) for the terminal prime when its
#                     progression has at least N steps (default: 64; 0 disables)
#   --verbose         Print search statistics to STDERR
#   --help            Show this help
#
# Requires Math::Prime::Util >= 0.74 (divisors($n, $limit)) and Math::GMPz.
#
# How the search works
# --------------------
# Let m_0 be the given multiple, with r distinct prime factors: n = m_0 * q, where
# q is a product of c = k - r further distinct primes q_1 < ... < q_c.  The
# search starts from m = m_0 and L = lcm(p - 1 : p | m_0); the q_i are chosen by
# depth-first search, and with m the product of the primes chosen so far and
# L = lcm of all (p - 1), every completion n = m*q needs n == 1 (mod L).  Two
# shortcuts finish a subtree without enumerating it:
#
#   * forced completion: q must be one of the numbers  first + t*L  in
#     [q_min, q_max], where first = m^(-1) mod L; if there are few of them they
#     are factored directly.
#   * the last prime q_c: (q_c - 1) | (m - 1) and q_c == m^(-1) (mod lcm), so it
#     is either the single residue in its window, or found via divisors(m - 1).
#
# The last two levels (the loop over q_(c-1) and the terminal prime) are inlined,
# because that is where nearly all the nodes are.
#
# Facts used (all primes are odd: an even Carmichael number cannot exist):
#   * m_0 must be odd, squarefree and coprime to L_0 = lcm(p - 1 : p | m_0),
#     otherwise there is no solution;
#   * gcd(m, p-1) = 1 is necessary: a prime r | m with r | (p-1) would divide
#     both n and n-1;
#   * the new primes are not necessarily larger than the primes of m_0, so they
#     must not divide m_0 (squarefree) nor L_0 (a prime of n cannot divide n - 1):
#     such primes are removed from the prime list;
#   * the terminal prime can coincide with a prime of m_0: it is checked;
#   * L divides n-1, hence L < B;
#   * (q_c - 1) divides (m - 1) with q_c != m, so q_c - 1 <= (m - 1) / 2;
#   * c = 0 (n = m_0) and c = 1 (only the terminal prime) are solved directly.

use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Time::HiRes  qw(time);

use Math::GMPz qw(:mpz);
use Math::Prime::Util 0.74 qw(:all);

# ---------------------------------------------------------------------------
# Small GMP helpers
# ---------------------------------------------------------------------------

sub z_from_dec ($value) {
    my $z = Rmpz_init();
    Rmpz_set_str($z, "$value", 10);
    return $z;
}

sub z_string ($z) {
    return Rmpz_get_str($z, 10);
}

sub parse_nonnegative_native ($name, $value) {
    die "$name must be a non-negative integer\n"
      if !defined($value) || $value !~ /\A\d+\z/;

    my $z = z_from_dec($value);
    die "$name is too large for a native unsigned integer\n"
      if !Rmpz_fits_ulong_p($z);

    return Rmpz_get_ui($z);
}

# primality test of a (possibly large) mpz value
sub z_is_prime ($z) {
    return is_prime(Rmpz_fits_ulong_p($z) ? Rmpz_get_ui($z) : $z);
}

# ---------------------------------------------------------------------------
# Generate all k-factor Carmichael numbers in [A, B] divisible by m.
# ---------------------------------------------------------------------------

sub generate_carmichael_multiples ($A_input, $B_input, $k_input, $m_input = 1, $force_bits = 64, $force_count = 16, $verbose = 0, %opt) {

    die "A must be a decimal integer\n"
      if !defined($A_input) || "$A_input" !~ /\A[+-]?\d+\z/;
    die "B must be a decimal integer\n"
      if !defined($B_input) || "$B_input" !~ /\A[+-]?\d+\z/;
    die "m must be a positive decimal integer\n"
      if !defined($m_input) || "$m_input" !~ /\A\+?0*[1-9]\d*\z/;

    die "k must be an integer >= 3\n"
      if !defined($k_input) || "$k_input" !~ /\A\d+\z/;

    my $k_z = z_from_dec($k_input);
    die "k is too large for native indexing\n"
      if !Rmpz_fits_ulong_p($k_z);
    my $k = Rmpz_get_ui($k_z);
    die "k must be an integer >= 3\n" if $k < 3;

    $force_bits  = parse_nonnegative_native('--force-bits',  $force_bits);
    $force_count = parse_nonnegative_native('--force-count', $force_count);

    my $force_ratio = $opt{force_ratio} // 0.75;
    my $step_div    = $opt{step_div}    // 64;

    die "--force-ratio must be a non-negative number\n" if $force_ratio !~ /\A\d+(?:\.\d+)?\z/;
    $step_div = parse_nonnegative_native('--step-div', $step_div);

    my $started = time();

    (my $A_str = "$A_input") =~ s/\A\+//;
    (my $B_str = "$B_input") =~ s/\A\+//;
    (my $m_str = "$m_input") =~ s/\A\+//;
    $m_str =~ s/\A0+(?=\d)//;

    my $A     = z_from_dec($A_str);
    my $B     = z_from_dec($B_str);
    my $mbase = z_from_dec($m_str);

    my @results;
    return \@results if Rmpz_cmp($A,     $B) > 0;
    return \@results if Rmpz_cmp($mbase, $B) > 0;    # no multiple of m is <= B

    # ---- the given multiple: must be odd and squarefree --------------------
    return \@results if Rmpz_divisible_ui_p($mbase, 2);

    my $m_nontrivial = (Rmpz_cmp_ui($mbase, 1) > 0) ? 1 : 0;

    my @m_factors = $m_nontrivial ? factor_exp($m_str) : ();
    foreach my $pe (@m_factors) {
        return \@results if $pe->[1] != 1;
    }

    my $r = scalar(@m_factors);
    return \@results if $r > $k;
    my $c = $k - $r;    # number of primes still to be found

    # L0 = lcm(p - 1 : p | m); m must be coprime to it
    my ($tmp, $T, $T2, $T3, $T4) = map { Rmpz_init() } 1 .. 5;
    my $L0 = Rmpz_init_set_ui(1);
    foreach my $pe (@m_factors) {
        Rmpz_set_str($tmp, "$pe->[0]", 10);
        Rmpz_sub_ui($tmp, $tmp, 1);
        Rmpz_lcm($L0, $L0, $tmp);
    }
    Rmpz_gcd($tmp, $mbase, $L0);
    return \@results if Rmpz_cmp_ui($tmp, 1) != 0;

    # ---- c = 0: the only candidate is m itself -----------------------------------
    if ($c == 0) {
        Rmpz_sub_ui($tmp, $mbase, 1);
        if (Rmpz_cmp($mbase, $A) >= 0 && Rmpz_divisible_p($tmp, $L0)) {
            push @results, Rmpz_init_set($mbase);
        }
        return \@results;
    }

    # ---- the c smallest allowed primes (not dividing m and not dividing L0) --------
    # prefix[j] = m * (product of the j smallest allowed primes): the smallest possible
    # value of m * (product of j further primes).
    my @prefix = (Rmpz_init_set($mbase));
    my $p0     = 2;
    for my $j (1 .. $c) {
        do { $p0 = next_prime($p0) } while (Rmpz_divisible_ui_p($mbase, $p0) || Rmpz_divisible_ui_p($L0, $p0));
        my $z = Rmpz_init();
        Rmpz_mul_ui($z, $prefix[$j - 1], $p0);
        return \@results if Rmpz_cmp($z, $B) > 0;
        push @prefix, $z;
    }

    # The bound A matters only if it is above the smallest possible value.
    my $A_matters = (Rmpz_cmp($A, $prefix[$c]) > 0) ? 1 : 0;
    Rmpz_set($A, $prefix[$c]) if !$A_matters;

    # Scratch values
    my ($F, $Q, $N1, $N) = map { Rmpz_init() } 1 .. 4;
    my ($L2, $M2, $H, $LO, $M2M1, $TT, $NN) = map { Rmpz_init() } 1 .. 7;

    my $NULL = $Math::GMPz::NULL;

    my ($visited_nodes, $tail_nodes, $tail_primes, $forced_nodes, $factorizations, $terminal_hits) = (0) x 6;
    my $sieve_max = 0;

    # ---- c = 1: only the terminal prime q is missing ---------------------------------
    #   n = m*q,  q not dividing m,  (q - 1) | (m - 1),  q == m^(-1) (mod L0)
    if ($c == 1) {

        # q <= floor(B / m), and (q - 1) is a proper divisor of the even number m - 1
        Rmpz_fdiv_q($H, $B, $mbase);
        Rmpz_add_ui($T2, $mbase, 1);
        Rmpz_fdiv_q_2exp($T2, $T2, 1);
        Rmpz_set($H, $T2) if Rmpz_cmp($T2, $H) < 0;

        Rmpz_set_ui($LO, 3);
        if ($A_matters) {
            Rmpz_cdiv_q($T2, $A, $mbase);
            Rmpz_set($LO, $T2) if Rmpz_cmp($T2, $LO) > 0;
        }

        Rmpz_invert($TT, $mbase, $L0) or die "Internal error: modular inverse does not exist\n";

        if (Rmpz_cmp($TT, $LO) < 0) {
            Rmpz_sub($T2, $LO, $TT);
            Rmpz_cdiv_q($T2, $T2, $L0);
            Rmpz_addmul($TT, $T2, $L0);
        }

        if (Rmpz_cmp($TT, $H) <= 0) {

            Rmpz_sub_ui($M2M1, $mbase, 1);

            Rmpz_sub($T2, $H, $TT);
            Rmpz_fdiv_q($T2, $T2, $L0);

            if ($step_div > 0 && Rmpz_fits_ulong_p($T2) && Rmpz_get_ui($T2) >= $step_div) {

                # many steps: enumerate the divisors of m - 1 (q - 1 is one of them)
                Rmpz_sub_ui($T3, $H, 1);
                my $dlimit = Rmpz_fits_ulong_p($T3)   ? Rmpz_get_ui($T3)   : z_string($T3);
                my $dvalue = Rmpz_fits_ulong_p($M2M1) ? Rmpz_get_ui($M2M1) : z_string($M2M1);

                foreach my $dv (divisors($dvalue, $dlimit)) {
                    Rmpz_set_str($T3, "$dv", 10);
                    Rmpz_add_ui($T3, $T3, 1);    # q
                    next if Rmpz_cmp($T3, $TT) < 0;
                    last if Rmpz_cmp($T3, $H) > 0;
                    Rmpz_sub($T4, $T3, $TT);
                    next if !Rmpz_divisible_p($T4,   $L0);
                    next if Rmpz_divisible_p($mbase, $T3);
                    if (z_is_prime($T3)) {
                        ++$terminal_hits;
                        Rmpz_mul($NN, $mbase, $T3);
                        push @results, Rmpz_init_set($NN);
                    }
                }
            }
            else {
                while (Rmpz_cmp($TT, $H) <= 0) {
                    Rmpz_sub_ui($T2, $TT, 1);    # q >= 3, so q - 1 >= 2
                    if (Rmpz_divisible_p($M2M1, $T2) && !Rmpz_divisible_p($mbase, $TT) && z_is_prime($TT)) {
                        ++$terminal_hits;
                        Rmpz_mul($NN, $mbase, $TT);
                        push @results, Rmpz_init_set($NN);
                    }
                    Rmpz_add($TT, $TT, $L0);
                }
            }
        }

        @results = sort { Rmpz_cmp($a, $b) } @results;

        if ($verbose) {
            printf STDERR "k=%d, m=%s, c=1, terminal=%d, results=%d, time=%.3f s\n", $k, $m_str, $terminal_hits, scalar(@results), time() - $started;
        }

        return \@results;
    }

    # ---- c >= 2: depth-first search ----------------------------------------------------

    # Largest prime that can appear in a non-terminal position.
    my $sieve_limit = Rmpz_init_set_ui(3);
    for my $depth (0 .. $c - 2) {
        Rmpz_fdiv_q($tmp, $B, $prefix[$depth]);
        Rmpz_root($tmp, $tmp, $c - $depth);
        Rmpz_set($sieve_limit, $tmp) if Rmpz_cmp($tmp, $sieve_limit) > 0;
    }

    die "Range too large"
      if !Rmpz_fits_ulong_p($sieve_limit);

    $sieve_max = Rmpz_get_ui($sieve_limit);

    # Allowed odd primes; the last element is a sentinel larger than every loop bound.
    my @P = @{primes(3, $sieve_max)};
    if ($m_nontrivial) {
        @P = grep { !Rmpz_divisible_ui_p($mbase, $_) && !Rmpz_divisible_ui_p($L0, $_) } @P;
    }
    push @P, next_prime($sieve_max);

    # Per-depth state
    my @M  = map { Rmpz_init() } 0 .. $c;    # m
    my @LL = map { Rmpz_init() } 0 .. $c;    # lcm(p - 1)
    my @QM = map { Rmpz_init() } 0 .. $c;    # floor(B / m)
    my @QN = map { Rmpz_init() } 0 .. $c;    # lower bound for the cofactor
    my @AQ = map { Rmpz_init() } 0 .. $c;    # ceil(A / m)
    Rmpz_set($M[0],  $mbase);
    Rmpz_set($LL[0], $L0);

    my $force_ok = ($force_bits > 0 && $force_count > 0) ? 1 : 0;

    # Search node: m = $M[$d], L = $LL[$d]; $rem primes are still missing; they are
    # all >= $P[$i0].
    my $search = sub ($d, $i0, $rem) {

        ++$visited_nodes;

        my $m    = $M[$d];
        my $L    = $LL[$d];
        my $qmax = $QM[$d];
        my $qmin = $QN[$d];
        my $aq   = $AQ[$d];

        Rmpz_fdiv_q($qmax, $B, $m);

        my $lo = $P[$i0];

        # Bound of the loop over primes: p^rem <= qmax.  lo > hi means dead node.
        Rmpz_root($T, $qmax, $rem);
        my $hi = Rmpz_get_ui($T);    # fits: qmax^(1/rem) <= sieve limit
        return if $lo > $hi;

        # Lower bound for the cofactor: lo * (lo+2) * (lo+4) * ...
        Rmpz_set_ui($qmin, $lo);
        Rmpz_mul_ui($qmin, $qmin, $lo + 2 * $_) for 1 .. $rem - 1;
        return if Rmpz_cmp($qmin, $qmax) > 0;

        if ($A_matters) {
            Rmpz_cdiv_q($aq, $A, $m);
            if (Rmpz_cmp($aq, $qmin) > 0) {
                Rmpz_set($qmin, $aq);
                return if Rmpz_cmp($qmin, $qmax) > 0;
            }
        }

        # ---- forced completion -------------------------------------------
        # Every completion is n = m*q with m*q == 1 (mod L), i.e.
        # q = F + t*L, where F = m^(-1) mod L.
        if ($force_ok && Rmpz_cmp_ui($L, 1) > 0) {

            Rmpz_invert($F, $m, $L) or die "Internal error: modular inverse does not exist\n";

            if (Rmpz_cmp($F, $qmin) < 0) {
                Rmpz_sub($T, $qmin, $F);
                Rmpz_cdiv_q($T, $T, $L);
                Rmpz_addmul($F, $T, $L);
            }

            return if Rmpz_cmp($F, $qmax) > 0;    # no candidate at all

            Rmpz_sub($T, $qmax, $F);
            Rmpz_fdiv_q($T, $T, $L);

            if (Rmpz_fits_ulong_p($T) && Rmpz_sizeinbase($qmax, 2) <= $force_bits) {

                my $cnt = Rmpz_get_ui($T) + 1;

                # Cost model: factoring one candidate costs about as much as visiting
                # one prime of the ordinary loop; estimate how many primes that is.
                my $thr = $force_count;
                if ($force_ratio > 0) {
                    my $N_est = $hi > $lo ? ($hi / log($hi) - $lo / log($lo > 2 ? $lo : 3)) : 1;
                    $N_est = 1 if $N_est < 1;
                    my $by_cost = $force_ratio * $N_est;
                    $thr = $by_cost if $by_cost > $thr;
                }

                if ($cnt <= $thr) {

                    ++$forced_nodes;
                    Rmpz_set($Q, $F);

                    while (Rmpz_cmp($Q, $qmax) <= 0) {
                        ++$factorizations;

                        my $qs = Rmpz_fits_ulong_p($Q) ? Rmpz_get_ui($Q) : Rmpz_get_str($Q, 10);

                        if (is_rough($qs, $lo) and is_almost_prime($rem, $qs)) {
                            my @f = factor_exp($qs);
                            if (@f == $rem && $f[0][0] >= $lo) {
                                my $ok = 1;
                                Rmpz_mul($N, $m, $Q);
                                Rmpz_sub_ui($N1, $N, 1);
                                for my $pe (@f) {
                                    my ($s, $e) = @$pe;
                                    if ($e != 1) { $ok = 0; last }
                                    Rmpz_set_str($T3, "$s", 10);
                                    if ($m_nontrivial && Rmpz_divisible_p($mbase, $T3)) { $ok = 0; last }
                                    Rmpz_sub_ui($T3, $T3, 1);
                                    if (!Rmpz_divisible_p($N1, $T3)) { $ok = 0; last }

                                }
                                push @results, Rmpz_init_set($N) if $ok;
                            }
                        }
                        Rmpz_add($Q, $Q, $L);
                    }
                    return;
                }
            }
        }

        # ---- ordinary recursion ---------------------------------------------
        if ($rem > 2) {

            my $child_m   = $M[$d + 1];
            my $child_lcm = $LL[$d + 1];

            for (my $i = $i0 ; ; ++$i) {
                my $p = $P[$i];
                last if $p > $hi;
                my $pm1 = $p - 1;

                # p-1 must be coprime to m (a prime of m cannot divide both n and n-1)
                next if Rmpz_gcd_ui($NULL, $m, $pm1) != 1;

                Rmpz_lcm_ui($child_lcm, $L, $pm1);

                # L divides n-1, hence L < n <= B
                next if Rmpz_cmp($child_lcm, $B) >= 0;

                Rmpz_mul_ui($child_m, $m, $p);
                __SUB__->($d + 1, $i + 1, $rem - 1);
            }

            return;
        }

        # ---- tail: two primes left, p and the terminal prime p4 -------------------
        #
        # For m2 = m*p and L2 = lcm(L, p-1):
        #   p4 == m2^(-1) (mod L2),   (p4 - 1) | (m2 - 1),   p < p4 <= floor(qmax / p)
        ++$tail_nodes;

        my $i;
        for ($i = $i0 ; ; ++$i) {
            my $p = $P[$i];
            last if $p > $hi;
            my $pm1 = $p - 1;

            Rmpz_lcm_ui($L2, $L, $pm1);
            Rmpz_mul_ui($M2, $m, $p);

            # m2 has no inverse modulo L2 exactly when gcd(m, p-1) != 1: such primes are
            # rejected here, so no separate gcd test is needed in this loop.
            Rmpz_invert($TT, $M2, $L2) or next;

            # common case: the residue is above the window -> no terminal prime
            Rmpz_fdiv_q_ui($H, $qmax, $p);
            next if Rmpz_cmp($TT, $H) > 0;

            # ---- rare path: the residue is inside the window ----
            Rmpz_sub_ui($M2M1, $M2, 1);

            # exactly one candidate (p4 = t): test the divisibility first
            Rmpz_add($T2, $TT, $L2);
            if (Rmpz_cmp($T2, $H) > 0) {
                next if Rmpz_cmp_ui($TT, $p + 1) <= 0;                       # p4 must exceed p (this also excludes t = 1)
                Rmpz_sub_ui($T2, $TT, 1);
                next if !Rmpz_divisible_p($M2M1, $T2);
                Rmpz_mul($NN, $M2, $TT);
                next if Rmpz_cmp($NN, $A) < 0;
                next if ($m_nontrivial && Rmpz_divisible_p($mbase, $TT));    # p4 must not be a prime of m_0
                if (z_is_prime($TT)) {
                    ++$terminal_hits;
                    push @results, Rmpz_init_set($NN);
                }
                next;
            }

            # several candidates: (p4 - 1) is a proper divisor of the even number
            # m2 - 1, hence p4 <= (m2 + 1) / 2
            Rmpz_add_ui($T2, $M2, 1);
            Rmpz_fdiv_q_2exp($T2, $T2, 1);
            Rmpz_set($H, $T2) if Rmpz_cmp($T2, $H) < 0;

            Rmpz_set_ui($LO, $p + 2);
            if ($A_matters) {
                Rmpz_cdiv_q_ui($T2, $aq, $p);
                Rmpz_set($LO, $T2) if Rmpz_cmp($T2, $LO) > 0;
            }

            if (Rmpz_cmp($TT, $LO) < 0) {
                Rmpz_sub($T2, $LO, $TT);
                Rmpz_cdiv_q($T2, $T2, $L2);
                Rmpz_addmul($TT, $T2, $L2);
            }
            next if Rmpz_cmp($TT, $H) > 0;

            Rmpz_sub($T2, $H, $TT);
            Rmpz_fdiv_q($T2, $T2, $L2);

            my $native = Rmpz_fits_ulong_p($M2M1) && Rmpz_fits_ulong_p($H) && Rmpz_fits_ulong_p($L2);

            # many steps: enumerate the divisors of m2 - 1 instead
            if (   $native
                && $step_div > 0
                && Rmpz_fits_ulong_p($T2)
                && Rmpz_get_ui($T2) >= $step_div) {

                my $Hn = Rmpz_get_ui($H);
                my $Tn = Rmpz_get_ui($TT);
                my $Ln = Rmpz_get_ui($L2);

                foreach my $dv (divisors(Rmpz_get_ui($M2M1), $Hn - 1)) {
                    my $p4 = $dv + 1;
                    next if $p4 < $Tn;
                    last if $p4 > $Hn;
                    if (($p4 - $Tn) % $Ln == 0 and is_prime($p4)) {
                        next if ($m_nontrivial && Rmpz_divisible_ui_p($mbase, $p4));
                        ++$terminal_hits;
                        Rmpz_mul_ui($NN, $M2, $p4);
                        push @results, Rmpz_init_set($NN);
                    }
                }
                next;
            }

            # few steps: walk the progression
            if ($native) {
                my ($tn, $hn, $ln, $mn) = (Rmpz_get_ui($TT), Rmpz_get_ui($H), Rmpz_get_ui($L2), Rmpz_get_ui($M2M1));
                for (; $tn <= $hn ; $tn += $ln) {
                    if ($mn % ($tn - 1) == 0 and is_prime($tn)) {
                        next if ($m_nontrivial && Rmpz_divisible_ui_p($mbase, $tn));
                        ++$terminal_hits;
                        Rmpz_mul_ui($NN, $M2, $tn);
                        push @results, Rmpz_init_set($NN);
                    }
                }
                next;
            }

            while (Rmpz_cmp($TT, $H) <= 0) {
                Rmpz_sub_ui($T2, $TT, 1);
                if (Rmpz_divisible_p($M2M1, $T2)) {
                    if (!($m_nontrivial && Rmpz_divisible_p($mbase, $TT)) && z_is_prime($TT)) {
                        ++$terminal_hits;
                        Rmpz_mul($NN, $M2, $TT);
                        push @results, Rmpz_init_set($NN);
                    }
                }
                Rmpz_add($TT, $TT, $L2);
            }
        }

        $tail_primes += $i - $i0;
        return;
    };

    $search->(0, 0, $c);

    @results = sort { Rmpz_cmp($a, $b) } @results;

    if ($verbose) {
        my $elapsed = time() - $started;
        printf STDERR "k=%d, m=%s, c=%d, sieve=%s, nodes=%d, tails=%d, tail_primes=%d, forced=%d, factorizations=%d, terminal=%d, results=%d, time=%.3f s\n",
          $k, $m_str, $c, $sieve_max, $visited_nodes, $tail_nodes, $tail_primes, $forced_nodes, $factorizations, $terminal_hits, scalar(@results), $elapsed;
    }

    return \@results;
}

# ---------------------------------------------------------------------------
# Command-line interface and examples
# ---------------------------------------------------------------------------

sub usage () {
    print <<'USAGE';
Usage:
  perl carmichael_multiples_in_range_mpz_fast.pl [options] A B k [m]

Generate every Carmichael number with exactly k distinct prime factors
in the inclusive range [A, B] that is a multiple of m (default: m = 1, i.e. all
of them). A, B and m may be arbitrarily large decimal integers (the prime list
needed is about sqrt(B / m / 3 / 5 / ...) long, so very large B needs a large k
or a large m). The prime factors of m count towards the k prime factors.

Options:
  --force-bits=N    Maximum bit length for forced cofactor factoring (64)
  --force-count=N   Always factor directly when at most N candidates remain (16)
  --force-ratio=X   Also factor directly when candidates <= X * estimated loop
                    size (0.75; 0 = use only --force-count)
  --step-div=N      Use divisors(m-1) when the terminal progression has at
                    least N steps (64; 0 disables)
  --verbose         Print search statistics to STDERR
  --help            Show this help

With no positional arguments, run default examples.
A negative or "+"-prefixed A must follow "--" (e.g.: ... -- -50 1000 3).
USAGE
}

my $force_bits  = 64;
my $force_count = 16;
my $force_ratio = 0.75;
my $step_div    = 64;
my $verbose     = 0;
my $help        = 0;

GetOptions(
           'force-bits=s'  => \$force_bits,
           'force-count=s' => \$force_count,
           'force-ratio=s' => \$force_ratio,
           'step-div=s'    => \$step_div,
           'verbose!'      => \$verbose,
           'help|h'        => \$help,
          )
  or die "Try --help for usage.\n";

if ($help) {
    usage();
    exit 0;
}

$force_bits  = parse_nonnegative_native('--force-bits',  $force_bits);
$force_count = parse_nonnegative_native('--force-count', $force_count);

sub print_result ($label, $A, $B, $k, $m, $force_bits, $force_count, $verbose) {
    say $label;
    my $numbers = generate_carmichael_multiples(
                                                $A, $B, $k, $m, $force_bits, $force_count, $verbose,
                                                force_ratio => $force_ratio,
                                                step_div    => $step_div,
                                               );
    say '[', join(', ', map { z_string($_) } @$numbers), ']';
}

if (!@ARGV) {
    print_result('3-factor Carmichael numbers in [1, 100000]:', 1, 100_000, 3, 1, $force_bits, $force_count, $verbose);
    say '';
    print_result('3-factor Carmichael numbers in [1, 100000] that are multiples of 5:', 1, 100_000, 3, 5, $force_bits, $force_count, $verbose);
    say '';
    print_result('4-factor Carmichael numbers in [1, 1000000] that are multiples of 15:', 1, 1_000_000, 4, 15, $force_bits, $force_count, $verbose);
}
else {
    die "Expected three or four positional arguments: A B k [m]\n" if (@ARGV < 3 || @ARGV > 4);
    my ($A, $B, $k, $m) = @ARGV;
    $m //= 1;
    print_result("$k-factor Carmichael numbers in [$A, $B] that are multiples of $m:", $A, $B, $k, $m, $force_bits, $force_count, $verbose);
}
