#!/usr/bin/env perl

# Daniel "Trizen" Șuteu
# https://github.com/trizen

# Smallest even Fermat pseudoprime to base 2 with exactly n distinct prime factors
# (OEIS A006935):  the least even composite m with omega(m) = n and 2^m == 2 (mod m).
#
# Usage:
#   perl even_fermat_psp_base2_smallest.pl [options] [n]
#
# As a library:
#   my $z = even_fermat_psp_base2_smallest($n);    # n >= 3, returns a Math::GMPz
#
# Options:
#   --force-bits=N    Factor cofactors only when q_max has at most N bits
#                     (default: 64; 0 disables forced completion)
#   --force-count=N   Always factor directly when at most N candidates remain
#                     (default: 16; 0 disables forced completion)
#   --force-ratio=X   Also factor directly whenever the number of candidates is
#                     at most X * (estimated number of primes the ordinary loop
#                     would visit) (default: 0.75; 0 = use only --force-count)
#   --upper=N         Start with the (known) upper bound N: one exact pass finds the
#                     smallest term <= N
#   --cap=N           Prime cap of the heuristic first phase (default: 8192;
#                     0 = exact search only)
#   --verbose         Print search statistics to STDERR
#   --help            Show this help
#
# Requires Math::Prime::Util >= 0.74 and Math::GMPz.
#
# How the search works
# --------------------
# An even n with 2^n == 2 (mod n) is n = 2*m with m odd (4 | n is impossible: 2^n == 0 mod 4)
# and 2^(n-1) == 1 (mod p^e) for every p^e || m, i.e. ord_{p^e}(2) | n-1.  Since n-1 is odd:
#
#   * every ord_p(2) = z_p must be odd, so only the primes with an odd order of 2 (about 29%
#     of the primes) can occur; the other ones are never put in the prime table;
#   * with L = lcm(z_p) (odd), n == 1 (mod L);
#   * the odd prime powers p^e (e >= 2) need ord_{p^e}(2) = z_p, i.e. p is a Wieferich prime
#     (3511 is the only known one with an odd order; 1093 has the even order 364).
#
# The search is the base-2 Fermat search started from m = 2 (the prime 2 counts as one of the
# k prime factors).  The odd primes p_1 < ... < p_(k-2) are chosen by depth-first search;
# with m = 2*p_1*...*p_j and L = lcm(z_p_1, ..., z_p_j), every completion n = m*q needs
# n == 1 (mod L).  Shortcuts:
#
#   * forced completion: q must be one of the (odd) numbers  first + t*(2L)  in [q_min, q_max],
#     where first = m^(-1) mod L; if there are few of them they are factored directly and
#     every prime s of q is tested with 2^(n-1) == 1 (mod s);
#   * the last prime p: since z_p | p-1, the condition z_p | n-1 is equivalent to
#     z_p | m-1, i.e. 2^(m-1) == 1 (mod p) (m-1 is odd, so the order of p is automatically odd);
#     together with p == m^(-1) (mod L) this is a short progression that is walked;
#   * the last two levels (the loop over p_(k-2) and the terminal prime) are inlined;
#   * the cofactor lower bound uses the consecutive primes of the (odd-order) prime list.
#
# Prime powers.  Each combination "w^e | n" (w a Wieferich prime with an odd order) is a
# separate run that starts from the given multiple m_0 = 2 * prod w^e, with the primes dividing
# m_0 or lcm(z_w) removed from the list.  Every prime that can occur is checked while the
# prime table is built, so the code stays correct if another Wieferich prime were ever found.
#
# Interval search.  The intervals [lower, upper] are contiguous and doubling, so the first
# interval containing a solution contains the global minimum.  Inside an interval the upper
# bound is lowered to (best - 1) every time something is found, which prunes the rest of
# the search (including the loop bounds of the nodes that are already on the stack).
#
# Two phases.  The terms are made of small primes (all but the largest prime are tiny compared
# to the sieve bound that a complete search needs), so
#   1. a heuristic search limits the non-terminal primes to <= cap: it is very fast and gives a
#      valid upper bound U (the terminal prime is never limited);
#   2. one exact pass over [smallest possible n, U - 1] either finds a smaller term or proves
#      that U is the least one.
# With --upper=N the first phase is skipped and N is used as U.
#
# Facts used:
#   * gcd(m, z_p) = 1 is necessary (a prime of m would divide both n and n-1);
#   * L divides n-1, hence L < B;
#   * there is no even term with two prime factors (n = 2p: 2^n == 2 (mod p) would give
#     2^2 == 2).

use v5.36;
use strict;
use warnings;
no warnings 'recursion';

use Getopt::Long qw(GetOptions);
use Time::HiRes  qw(time);

use Math::GMPz        qw(:mpz);
use Math::Prime::Util qw(:all);

# ---------------------------------------------------------------------------
# The smallest even Fermat pseudoprime to base 2 with exactly $k distinct prime factors.
# ---------------------------------------------------------------------------

sub even_fermat_psp_base2_smallest ($k, %opt) {

    die "n must be an integer >= 3\n" if !defined($k) || "$k" !~ /\A\d+\z/ || $k < 3;
    $k = 0 + $k;

    my $force_bits  = $opt{force_bits}  // 64;
    my $force_count = $opt{force_count} // 16;
    my $force_ratio = $opt{force_ratio} // 0.75;
    my $verbose     = $opt{verbose}     // 0;

    die "force_bits must be a non-negative integer\n"  if $force_bits  !~ /\A\d+\z/;
    die "force_count must be a non-negative integer\n" if $force_count !~ /\A\d+\z/;
    die "force_ratio must be a non-negative number\n"  if $force_ratio !~ /\A\d+(?:\.\d+)?\z/;

    my $force_ok = ($force_bits > 0 && $force_count > 0) ? 1 : 0;

    my $upper_seed = $opt{upper};
    my $heur_cap   = $opt{cap} // 8192;    # prime cap of the heuristic phase (0 disables it)

    die "upper must be a positive integer\n"   if defined($upper_seed) && "$upper_seed" !~ /\A\+?0*[1-9]\d*\z/;
    die "cap must be a non-negative integer\n" if $heur_cap                             !~ /\A\d+\z/;
    $heur_cap = 0 + $heur_cap;

    # ---- state ----------------------------------------------------------------

    my $TWO  = Rmpz_init_set_ui(2);
    my $NULL = $Math::GMPz::NULL;

    my $B         = Rmpz_init();           # current inclusive upper bound; lowered on every find
    my $best      = Rmpz_init();
    my $have_best = 0;
    my $gen       = 0;                     # incremented whenever B is lowered

    # Odd primes with an odd order of 2, their orders ord_p(2), and the Wieferich primes
    # among them seen so far.
    my (@GP, @GZ, @WIEF);
    my $have = 2;    # all primes <= $have are in the tables

    # Heuristic phase: when $cap > 0 the non-terminal primes are limited to <= $cap (the
    # terminal prime is not limited), so the search is incomplete but everything it finds is
    # a valid term; $truncated tells whether the cap ever removed something.
    my ($cap, $truncated) = (0, 0);

    my ($visited_nodes, $tail_nodes, $tail_primes, $forced_nodes, $factorizations, $terminal_hits) = (0) x 6;

    # Scratch values shared by all nodes (a node never needs them across a recursive call)
    my ($T,  $T2, $T3, $F,  $Q,    $N1, $N,  $R) = map { Rmpz_init() } 1 .. 8;
    my ($L2, $M2, $H,  $LO, $M2M1, $TT, $NN, $S) = map { Rmpz_init() } 1 .. 8;

    # ---- helpers --------------------------------------------------------------

    my sub record ($n) {
        Rmpz_set($best, $n);
        Rmpz_sub_ui($B, $n, 1);    # from now on only strictly smaller numbers matter
        $have_best = 1;
        ++$gen;
    }

    my sub z_is_prime ($z) {
        return is_prime(Rmpz_fits_ulong_p($z) ? Rmpz_get_ui($z) : Rmpz_get_str($z, 10));
    }

    # Largest e >= 1 with 2^z == 1 (mod p^e), where z = ord_p(2).  e >= 2: Wieferich prime.
    my sub wieferich_exp ($p, $z) {

        if ($p < 4294967296) {     # p*p fits into 64 bits
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
        return if $limit <= $have;

        foreach my $p (@{primes($have + 1, $limit)}) {

            # the order of 2 must be odd (it divides n-1, which is odd): 2^(odd part of p-1) == 1
            powmod(2, ($p - 1) >> valuation($p - 1, 2), $p) == 1 or next;

            my $z = znorder(2, $p);
            push @GP, $p;
            push @GZ, $z;
            my $e = wieferich_exp($p, $z);
            push @WIEF, [$p, $e, $z] if $e > 1;
        }

        $have = $limit;
    }

    # The $count smallest odd primes with an odd order of 2 that divide neither $mbase nor $L0:
    # the smallest primes that can occur in the odd part of a term.
    my sub smallest_primes ($count, $mbase, $L0) {
        my (@r, $p);
        $p = 2;
        while (@r < $count) {
            $p = next_prime($p);
            next if Rmpz_divisible_ui_p($mbase, $p) || Rmpz_divisible_ui_p($L0, $p);
            next if powmod(2, ($p - 1) >> valuation($p - 1, 2), $p) != 1;
            push @r, $p;
        }
        return @r;
    }

    # Largest prime that can appear in a non-terminal position, given prefix[j] = the
    # smallest possible value of m after j primes; extends the prime tables up to it.
    my sub sieve_for ($prefix, $c) {

        my $limit = Rmpz_init_set_ui(3);
        for my $depth (0 .. $c - 2) {
            Rmpz_fdiv_q($T, $B, $prefix->[$depth]);
            Rmpz_root($T, $T, $c - $depth);
            Rmpz_set($limit, $T) if Rmpz_cmp($T, $limit) > 0;
        }

        die "Range too large\n" if !Rmpz_fits_ulong_p($limit);

        my $s = Rmpz_get_ui($limit);

        if ($cap > 0 and $s > $cap) {
            $s         = $cap;
            $truncated = 1;
        }

        extend_primes($s);
        return $s;
    }

    # ---- search of the numbers  n = mbase * q  in [A, B], where mbase = 2 * prod w^e
    # (Wieferich powers, r distinct odd primes) and q is a squarefree product of c = k - 1 - r
    # odd primes not dividing mbase.  Lowers B whenever it finds something.

    my sub search_combo ($A_in, $mbase, $L0, $r) {

        my $c = $k - 1 - $r;

        # c < 2 cannot happen for a useful interval: it needs m_0 >= 2 * 3511^2 (k = 3), but
        # a(3) = 161038 is found long before.
        return if $c < 2;
        return if Rmpz_cmp($mbase, $B) > 0;

        # the primes of m_0 other than 2 (the list contains only odd primes)
        my $m_nontrivial = ($r > 0) ? 1 : 0;

        Rmpz_gcd($T, $mbase, $L0);
        return if Rmpz_cmp_ui($T, 1) != 0;

        # prefix[j] = mbase * (product of the j smallest allowed primes): the smallest possible
        # value of m after j odd primes (the allowed primes have an odd order of 2)
        my @prefix = (Rmpz_init_set($mbase));
        my @small  = smallest_primes($c, $mbase, $L0);
        for my $j (1 .. $c) {
            my $z = Rmpz_init();
            Rmpz_mul_ui($z, $prefix[$j - 1], $small[$j - 1]);
            return if Rmpz_cmp($z, $B) > 0;
            push @prefix, $z;
        }

        # The bound A matters only if it is above the smallest possible value.
        my $A         = Rmpz_init_set($A_in);
        my $A_matters = (Rmpz_cmp($A, $prefix[$c]) > 0) ? 1 : 0;
        Rmpz_set($A, $prefix[$c]) if !$A_matters;

        my $sieve_max = sieve_for(\@prefix, $c);

        # Allowed primes (and their orders); the last element is a sentinel larger than every
        # loop bound (and a lower bound for every prime that is not in the list).
        my (@P, @Z);
        for my $i (0 .. $#GP) {
            my $p = $GP[$i];
            last if $p > $sieve_max;
            next if $m_nontrivial && (Rmpz_divisible_ui_p($mbase, $p) || Rmpz_divisible_ui_p($L0, $p));
            push @P, $p;
            push @Z, $GZ[$i];
        }
        push @P, $sieve_max + 1;
        push @Z, 1;

        # Per-depth state
        my @M  = map { Rmpz_init() } 0 .. $c;    # m
        my @LL = map { Rmpz_init() } 0 .. $c;    # lcm(z_p)
        my @QM = map { Rmpz_init() } 0 .. $c;    # floor(B / m)
        my @QN = map { Rmpz_init() } 0 .. $c;    # lower bound for the cofactor
        my @AQ = map { Rmpz_init() } 0 .. $c;    # ceil(A / m)
        Rmpz_set($M[0],  $mbase);
        Rmpz_set($LL[0], $L0);

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
            my $hi = Rmpz_get_ui($T);                # fits: qmax^(1/rem) <= sieve limit
            $hi = $sieve_max if $hi > $sieve_max;    # only in the heuristic phase
            return if $lo > $hi;

            # Lower bound for the cofactor: the product of the next primes of the list
            Rmpz_set_ui($qmin, $lo);
            Rmpz_mul_ui($qmin, $qmin, $P[$i0 + $_ > $#P ? $#P : $i0 + $_]) for 1 .. $rem - 1;
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
            # q = F + t*L, where F = m^(-1) mod L; q is odd and L is odd, so only every
            # second term of the progression is needed (the step is 2*L).
            if ($force_ok && Rmpz_cmp_ui($L, 1) > 0) {

                Rmpz_invert($F, $m, $L) or die "Internal error: modular inverse does not exist\n";

                if (Rmpz_cmp($F, $qmin) < 0) {
                    Rmpz_sub($T, $qmin, $F);
                    Rmpz_cdiv_q($T, $T, $L);
                    Rmpz_addmul($F, $T, $L);
                }

                Rmpz_add($F, $F, $L) if !Rmpz_tstbit($F, 0);
                Rmpz_mul_2exp($S, $L, 1);

                return if Rmpz_cmp($F, $qmax) > 0;    # no candidate at all

                Rmpz_sub($T, $qmax, $F);
                Rmpz_fdiv_q($T, $T, $S);

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
                                        Rmpz_powm($R, $TWO, $N1, $T3);    # ord_s(2) | n-1
                                        if (Rmpz_cmp_ui($R, 1) != 0) { $ok = 0; last }
                                    }
                                    if ($ok) {
                                        record($N);
                                        return;                           # the candidates are increasing
                                    }
                                }
                            }
                            Rmpz_add($Q, $Q, $S);
                        }
                        return;
                    }
                }
            }

            # ---- ordinary recursion ---------------------------------------------
            if ($rem > 2) {

                my $child_m   = $M[$d + 1];
                my $child_lcm = $LL[$d + 1];
                my $g         = $gen;

                for (my $i = $i0 ; ; ++$i) {
                    my $p = $P[$i];
                    last if $p > $hi;
                    my $z = $Z[$i];

                    # z must be coprime to m (a prime of m cannot divide both n and n-1)
                    next if Rmpz_gcd_ui($NULL, $m, $z) != 1;

                    Rmpz_lcm_ui($child_lcm, $L, $z);

                    # L divides n-1, hence L < n <= B
                    next if Rmpz_cmp($child_lcm, $B) >= 0;

                    Rmpz_mul_ui($child_m, $m, $p);
                    __SUB__->($d + 1, $i + 1, $rem - 1);

                    if ($g != $gen) {    # B was lowered: tighten this node's loop bound
                        $g = $gen;
                        Rmpz_fdiv_q($qmax, $B, $m);
                        Rmpz_root($T, $qmax, $rem);
                        $hi = Rmpz_get_ui($T);
                        $hi = $sieve_max if $hi > $sieve_max;
                    }
                }

                return;
            }

            # ---- tail: two primes left, p and the terminal prime q --------------------
            #
            # For m2 = m*p and L2 = lcm(L, z_p):
            #   q == m2^(-1) (mod L2),   2^(m2-1) == 1 (mod q),   p < q <= floor(qmax / p)
            # (z_q | q-1, so z_q | m2*q - 1  <=>  z_q | m2 - 1  <=>  q | 2^(m2-1) - 1)
            ++$tail_nodes;

            my $i;
            for ($i = $i0 ; ; ++$i) {
                my $p = $P[$i];
                last if $p > $hi;

                Rmpz_lcm_ui($L2, $L, $Z[$i]);
                Rmpz_mul_ui($M2, $m, $p);

                # m2 has no inverse modulo L2 exactly when gcd(m, z_p) != 1: such primes are
                # rejected here, so no separate gcd test is needed in this loop.
                Rmpz_invert($TT, $M2, $L2) or next;

                # common case: the residue is above the window -> no terminal prime
                Rmpz_fdiv_q_ui($H, $qmax, $p);
                next if Rmpz_cmp($TT, $H) > 0;

                # ---- rare path: the residue is inside the window ----

                # q is odd: with an odd modulus only every second term of the progression is
                if (Rmpz_tstbit($L2, 0)) {
                    Rmpz_add($TT, $TT, $L2) if !Rmpz_tstbit($TT, 0);
                    Rmpz_mul_2exp($S, $L2, 1);
                }
                else {
                    Rmpz_set($S, $L2);
                }

                Rmpz_set_ui($LO, $p + 2);
                if ($A_matters) {
                    Rmpz_cdiv_q_ui($T2, $aq, $p);
                    Rmpz_set($LO, $T2) if Rmpz_cmp($T2, $LO) > 0;
                }

                if (Rmpz_cmp($TT, $LO) < 0) {
                    Rmpz_sub($T2, $LO, $TT);
                    Rmpz_cdiv_q($T2, $T2, $S);
                    Rmpz_addmul($TT, $T2, $S);
                }
                next if Rmpz_cmp($TT, $H) > 0;

                Rmpz_sub_ui($M2M1, $M2, 1);

                my $hit = 0;

                if (Rmpz_fits_ulong_p($M2M1) && Rmpz_fits_ulong_p($H) && Rmpz_fits_ulong_p($S)) {
                    my ($tn, $hn, $sn, $en) = (Rmpz_get_ui($TT), Rmpz_get_ui($H), Rmpz_get_ui($S), Rmpz_get_ui($M2M1));
                    for (; $tn <= $hn ; $tn += $sn) {
                        if (powmod(2, $en, $tn) == 1 and is_prime($tn)) {
                            next if ($m_nontrivial && Rmpz_divisible_ui_p($mbase, $tn));
                            Rmpz_mul_ui($NN, $M2, $tn);
                            $hit = 1;
                            last;
                        }
                    }
                }
                else {
                    while (Rmpz_cmp($TT, $H) <= 0) {
                        Rmpz_powm($R, $TWO, $M2M1, $TT);
                        if (   Rmpz_cmp_ui($R, 1) == 0
                            && !($m_nontrivial && Rmpz_divisible_p($mbase, $TT))
                            && z_is_prime($TT)) {
                            Rmpz_mul($NN, $M2, $TT);
                            $hit = 1;
                            last;
                        }
                        Rmpz_add($TT, $TT, $S);
                    }
                }

                if ($hit) {
                    ++$terminal_hits;
                    record($NN);

                    # B was lowered: tighten the bounds of this node
                    Rmpz_fdiv_q($qmax, $B, $m);
                    Rmpz_root($T, $qmax, 2);
                    $hi = Rmpz_get_ui($T);
                    $hi = $sieve_max if $hi > $sieve_max;
                }
            }

            $tail_primes += $i - $i0;
            return;
        };

        $search->(0, 0, $c);

        return;
    }

    # ---- one interval: the squarefree numbers and the numbers divisible by some w^e ------

    my $one = Rmpz_init_set_ui(1);
    my $two = Rmpz_init_set_ui(2);

    my sub search_interval ($A) {

        # n = 2 * (squarefree odd part)
        search_combo($A, $two, $one, 0);

        # numbers divisible by w^e (e >= 2) for some Wieferich primes w; each w either appears
        # squarefree (above / left in the prime list) or with an exponent 2 <= e <= emax
        my @combos = ([$two, $one, 0]);

        foreach my $w (@WIEF) {
            my ($p, $emax, $z) = @$w;
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

        shift @combos;    # the squarefree run is done

        foreach my $cb (@combos) {
            search_combo($A, @$cb);
        }
    }

    # ---- main ---------------------------------------------------------------------------

    # the smallest possible n: 2 times the product of the k-1 smallest odd-order primes
    my $lower0 = Rmpz_init_set_ui(2);
    Rmpz_mul_ui($lower0, $lower0, $_) for smallest_primes($k - 1, $two, $one);

    # search the interval [$lo, $hi]; returns true if a term was found (the smallest one in
    # the interval, when the search is not truncated)
    my sub run_interval ($lo, $hi) {

        Rmpz_set($B, $hi);
        $have_best = 0;
        $truncated = 0;

        my $started = time();
        search_interval($lo);

        if ($verbose) {
            printf STDERR "[%s, %s]%s nodes=%d tails=%d tail_primes=%d forced=%d factorizations=%d terminal=%d time=%.3f s%s\n",
              Rmpz_get_str($lo, 10), Rmpz_get_str($hi, 10), ($cap ? " cap=$cap" : ''), $visited_nodes, $tail_nodes,
              $tail_primes, $forced_nodes, $factorizations, $terminal_hits, time() - $started, ($have_best ? ' FOUND' : '');
        }

        return $have_best;
    }

    my $lower = Rmpz_init_set($lower0);
    my $upper = Rmpz_init();
    Rmpz_mul_2exp($upper, $lower, 1);

    if (defined($upper_seed)) {

        # a known upper bound: one exact pass finds the smallest term <= bound
        (my $u = "$upper_seed") =~ s/\A\+//;
        Rmpz_set_str($upper, $u, 10);

        return Rmpz_init_set($best) if run_interval($lower0, $upper);

        # the given number is not an upper bound: continue above it
        Rmpz_add_ui($lower, $upper, 1);
        Rmpz_mul_2exp($upper, $upper, 1);
    }
    elsif ($heur_cap > 0) {

        # Phase 1 (heuristic): doubling intervals with the non-terminal primes limited to
        # <= cap.  The terms of this kind are found very quickly and are usually the answer;
        # they give a valid upper bound U.
        $cap = $heur_cap;

        my $any_truncated = 0;

        while (1) {
            my $found = run_interval($lower, $upper);
            $any_truncated ||= $truncated;

            if ($found) {

                # the cap never removed anything: the interval search was exact
                return Rmpz_init_set($best) if !$any_truncated;

                last;
            }

            Rmpz_add_ui($lower, $upper, 1);
            Rmpz_mul_2exp($upper, $upper, 1);
        }

        # Phase 2 (exact): one pass below U with no cap; it either finds a smaller term or
        # proves that U is the least one.
        my $U   = Rmpz_init_set($best);
        my $bnd = Rmpz_init();
        Rmpz_sub_ui($bnd, $U, 1);

        $cap = 0;

        return run_interval($lower0, $bnd) ? Rmpz_init_set($best) : $U;
    }

    # exact doubling intervals [lower, upper]
    $cap = 0;

    while (1) {

        return Rmpz_init_set($best) if run_interval($lower, $upper);

        Rmpz_add_ui($lower, $upper, 1);
        Rmpz_mul_2exp($upper, $upper, 1);
    }
}

# ---------------------------------------------------------------------------
# Command-line interface
# ---------------------------------------------------------------------------

sub usage ($status = 0) {
    my $fh = $status ? *STDERR : *STDOUT;
    print {$fh} <<'USAGE';
Usage:
  perl even_fermat_psp_base2_smallest.pl [options] [n]

Find the smallest even Fermat pseudoprime to base 2 with exactly n >= 3 distinct
prime factors (OEIS A006935).  Without n, print the terms for n = 3..10.

Options:
  --force-bits=N    Maximum bit length for forced cofactor factoring (64)
  --force-count=N   Always factor directly when at most N candidates remain (16)
  --force-ratio=X   Also factor directly when candidates <= X * estimated loop
                    size (0.75; 0 = use only --force-count)
  --upper=N         Start with the (known) upper bound N: one exact pass finds the
                    smallest term <= N
  --cap=N           Prime cap of the heuristic first phase (8192; 0 = exact search only)
  --verbose         Print search statistics to STDERR
  --help            Show this help
USAGE
    exit $status;
}

my $force_bits  = 64;
my $force_count = 16;
my $force_ratio = 0.75;
my $upper       = undef;
my $cap         = 8192;
my $verbose     = 0;
my $help        = 0;

GetOptions(
           'force-bits=i'  => \$force_bits,
           'force-count=i' => \$force_count,
           'force-ratio=f' => \$force_ratio,
           'upper=s'       => \$upper,
           'cap=i'         => \$cap,
           'verbose!'      => \$verbose,
           'help|h'        => \$help,
          )
  or usage(2);

usage(0) if $help;
usage(2) if @ARGV > 1;

my @ns = @ARGV ? ($ARGV[0]) : (3 .. 10);

foreach my $n (@ns) {
    usage(2) if $n !~ /\A\d+\z/ || $n < 3;
    my $term = even_fermat_psp_base2_smallest(
                                              $n,
                                              force_bits  => $force_bits,
                                              force_count => $force_count,
                                              force_ratio => $force_ratio,
                                              upper       => $upper,
                                              cap         => $cap,
                                              verbose     => $verbose,
                                             );
    say "a($n) = $term";
    say STDERR "factorization: ", join(' * ', map { $_->[1] > 1 ? "$_->[0]^$_->[1]" : $_->[0] } factor_exp("$term")) if $verbose;
}
