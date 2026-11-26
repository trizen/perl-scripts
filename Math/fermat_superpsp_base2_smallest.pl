#!/usr/bin/env perl

# Daniel "Trizen" Șuteu
# https://github.com/trizen

# Smallest Fermat superpseudoprime to base 2 (super-Poulet number) with exactly n distinct
# prime factors (OEIS A050217): the least Poulet number n with omega(n) = k, all of whose
# divisors d satisfy d | 2^d - 2.
#
# Usage:
#   perl fermat_superpsp_base2_smallest.pl [options] [n]
#
# As a library:
#   my $z = fermat_superpsp_base2_smallest($n);    # n >= 2, returns a Math::GMPz
#
# Options:
#   --upper=N         Start with the (known) upper bound N instead of the doubling
#                     search; the search then finds the smallest term <= N
#   --scan-steps=N    Resolve a multiplier by factoring 2^d-1 when more than N progression
#                     steps would otherwise be scanned (default: 5000)
#   --factor-bits=N   Largest d for which 2^d-1 is handed to the factoring routine (128)
#   --verbose         Print search statistics to STDERR
#   --help            Show this help
#
# Requires Math::GMPz, Math::Prime::Util and Math::Prime::Util::GMP.
#
# How the search works
# --------------------
# Let z_p = ord_p(2).  For a squarefree n = p_1 * ... * p_k a divisor d' = prod_{p in S} p
# satisfies d' | 2^d' - 2 iff z_p | d'-1 for every p in S, and since p == 1 (mod z_p) this is
# the same as z_p | (d'/p) - 1.  Taking S = {p, q} shows that
#
#     n is super-Poulet   <=>   z_p | q - 1  for all primes p != q dividing n,
#
# and then every divisor is automatically fine (a product of numbers == 1 mod z_p is
# == 1 mod z_p).  With d = lcm(z_p) this says that  p == 1 (mod d)  and  z_p | d  for all
# the primes of n, i.e. all the primes of n lie in
#
#     A_d = { p prime : p == 1 (mod d)  and  p | 2^d - 1 },
#
# and, conversely, any k distinct primes of A_d give a super-Poulet number (every divisor
# is == 1 mod d, and the order of 2 divides d).  So the squarefree terms are exactly the
# products of k primes of some A_d (this is the family of the generation algorithm).
#
# The least term is squarefree: if p^2 | n then n/p is again a super-Poulet number (its
# divisors are divisors of n) with the same number of distinct prime factors, and it is
# smaller.  Hence
#
#     a(k) = min over d of (the product of the k smallest primes of A_d),
#
# and the search runs over d (not over a tree of primes):
#
#   * the primes of A_d are p = j*d + 1 (j even when d is odd); they are tested in increasing
#     order with 2^d == 1 (mod p) and a primality test (only for the rare hits);
#   * the shared upper bound B is lowered to (n - 1) whenever a smaller term is found;
#   * d is limited by the product of the k smallest allowed values j*d + 1 <= B;
#   * the next prime is limited by  q*(q+s)*(q+2s)*... <= B / (product found so far)  (s is
#     the progression step); the last prime may be as large as B / (product of the other
#     k-1), which is the only place where the scan can become long;
#   * when the scan would be long, 2^d - 1 is factored with Math::Prime::Util::GMP instead
#     (the found primes are divided out; the primes q == 1 (mod d) of the cofactor are the
#     remaining elements of A_d);
#   * doubling bound B: a pass with the bound B finds the smallest term <= B (if any).

use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Time::HiRes  qw(time);

use Math::GMPz             qw(:mpz);
use Math::Prime::Util      qw(factor_exp powmod is_prime);
use Math::Prime::Util::GMP ();

# ---------------------------------------------------------------------------
# The smallest super-Poulet number with exactly $k distinct prime factors.
# ---------------------------------------------------------------------------

sub fermat_superpsp_base2_smallest ($k, %opt) {

    die "n must be an integer >= 2\n" if !defined($k) || "$k" !~ /\A\d+\z/ || $k < 2;
    $k = 0 + $k;

    my $verbose     = $opt{verbose}     // 0;
    my $scan_steps  = $opt{scan_steps}  // 5000;
    my $factor_bits = $opt{factor_bits} // 128;
    my $upper       = $opt{upper};
    my $growth      = 0 + ($opt{growth} // $k);    # the bound grows by 2^growth per pass

    die "scan_steps must be a non-negative integer\n"  if $scan_steps                 !~ /\A\d+\z/;
    die "factor_bits must be a non-negative integer\n" if $factor_bits                !~ /\A\d+\z/;
    die "upper must be a positive integer\n"           if defined($upper) && "$upper" !~ /\A\+?0*[1-9]\d*\z/;

    my $NATIVE_MAX = 1.7e19;                       # largest progression term tested with native integers

    # ---- state ----------------------------------------------------------------

    my $B         = Rmpz_init();                   # current inclusive upper bound; lowered on every find
    my $logB      = 0;                             # natural logarithm of B
    my $best      = Rmpz_init();
    my $have_best = 0;

    my ($P, $R, $TM, $TN) = map { Rmpz_init() } 1 .. 4;

    my ($mults, $tested, $resolved, $factored) = (0) x 4;

    # ---- helpers --------------------------------------------------------------

    # natural logarithm of a (possibly huge) positive mpz
    my sub mpz_log ($z) {
        my $s   = Rmpz_get_str($z, 10);
        my $len = length($s);
        return log($s) if $len <= 15;
        return log(substr($s, 0, 15)) + ($len - 15) * log(10);
    }

    my sub set_bound ($z) {
        Rmpz_set($B, $z);
        $logB = mpz_log($B);
    }

    my sub record ($n) {
        return if Rmpz_cmp($n, $B) > 0;
        Rmpz_set($best, $n);
        $have_best = 1;
        Rmpz_sub_ui($TM, $n, 1);    # from now on only strictly smaller numbers matter
        set_bound($TM);
    }

    # Largest q (as a float) such that q*(q+s)*...*(q+(rem-1)*s) <= B / P, i.e. an upper
    # bound for the next prime of A_d when rem primes are still missing.
    my sub next_hi ($rem, $step, $log_prod) {
        my $target = $logB - $log_prod + 1e-9;
        return 1.0              if $target <= -700;
        return exp($target) + 1 if $rem == 1;

        my $lo = 1.0;
        my $hi = exp($target / $rem) + 1;

        for (1 .. 56) {
            my $mid = 0.5 * ($lo + $hi);
            last if $mid == $lo || $mid == $hi;

            my $sum = log($mid);
            my $cur = $mid;
            for (1 .. $rem - 1) {
                $cur += $step;
                $sum += log($cur);
            }

            if   ($sum <= $target) { $lo = $mid }
            else                   { $hi = $mid }
        }

        return $hi + 1;
    }

    # Finish a multiplier d by factoring 2^d - 1.  Returns 1 if d is finished (a candidate
    # may have been recorded), 0 if the caller should keep scanning.
    my sub resolve ($d, $found, $force) {

        return 0 if !$force && $d > $factor_bits;

        ++$resolved;
        ++$factored;

        Rmpz_set_ui($R, 1);
        Rmpz_mul_2exp($R, $R, $d);
        Rmpz_sub_ui($R, $R, 1);

        foreach my $p (@$found) {
            while (Rmpz_divisible_ui_p($R, $p)) {
                Rmpz_divexact_ui($R, $R, $p);
            }
        }

        return 1 if Rmpz_cmp_ui($R, 1) == 0;

        my $rem = $k - scalar(@$found);

        # the primes q == 1 (mod d) of the cofactor: the remaining elements of A_d
        my (%seen, @q);
        foreach my $s (Math::Prime::Util::GMP::factor(Rmpz_get_str($R, 10))) {
            next if $seen{$s}++;
            Rmpz_set_str($TM, $s, 10);
            Rmpz_sub_ui($TM, $TM, 1);
            next if !Rmpz_divisible_ui_p($TM, $d);
            push @q, Rmpz_init_set_str($s, 10);
        }

        return 1 if @q < $rem;

        @q = sort { Rmpz_cmp($a, $b) } @q;

        Rmpz_set($TN, $P);
        Rmpz_mul($TN, $TN, $q[$_]) for 0 .. $rem - 1;
        record($TN);

        return 1;
    }

    # ---- one pass: all multipliers d with the current bound ----------------------------

    my sub pass () {

      DIV: for (my $d = 2 ; ; ++$d) {

            # the k smallest candidates j*d+1 (j even if d is odd) must have a product <= B
            my $lb = 0;
            $lb += log($_ * $d + 1) for 1 .. $k;
            last if $lb > $logB + 1e-9;

            my $step = ($d & 1) ? 2 * $d : $d;

            if ($step != $d) {
                my $lb2 = 0;
                $lb2 += log($_ * $step + 1) for 1 .. $k;
                next if $lb2 > $logB + 1e-9;
            }

            ++$mults;

            my @found;
            my $logP = 0;
            Rmpz_set_ui($P, 1);

            my $hi    = next_hi($k, $step, 0);
            my $p     = $step + 1;
            my $tried = 0;

            # long scan: factor 2^d - 1 from the start
            if ($p <= $hi and ((($hi - $p) / $step > $scan_steps) or $hi > $NATIVE_MAX)) {
                $tried = 1;
                next DIV if resolve($d, \@found, $hi > $NATIVE_MAX);
            }

            for (; $p <= $hi ; $p += $step) {

                ++$tested;

                # p | 2^d - 1 (the order of 2 divides d), then p prime
                if (powmod(2, $d, $p) == 1 and is_prime($p)) {

                    push @found, $p;
                    Rmpz_mul_ui($P, $P, $p);
                    $logP += log($p);

                    if (@found == $k) {
                        record($P);
                        next DIV;
                    }

                    $hi = next_hi($k - @found, $step, $logP);

                    if (!$tried and ((($hi - $p) / $step > $scan_steps) or $hi > $NATIVE_MAX)) {
                        $tried = 1;
                        next DIV if resolve($d, \@found, $hi > $NATIVE_MAX);
                    }
                }
            }
        }
    }

    # ---- main: doubling bound B; a pass finds the smallest term <= B ------------------

    if (defined($upper)) {
        (my $u = "$upper") =~ s/\A\+//;
        Rmpz_set_str($TM, $u, 10);
        set_bound($TM);
    }
    else {
        Rmpz_set_ui($TM, 1);
        Rmpz_mul_2exp($TM, $TM, 4 * $k + 4);
        set_bound($TM);
    }

    while (1) {

        my $started = time();
        ($mults, $tested, $resolved, $factored) = (0) x 4;

        my $pass_bound = Rmpz_get_str($B, 10);
        pass();

        if ($verbose) {
            printf STDERR "[<= %s] d=%d tested=%d resolved=%d time=%.3f s%s\n",
              $pass_bound, $mults, $tested, $resolved, time() - $started, ($have_best ? ' FOUND' : '');
        }

        return Rmpz_init_set($best) if $have_best;

        # nothing <= B: the multiplier range doubles with this growth of the bound
        Rmpz_mul_2exp($TM, $B, $growth);
        set_bound($TM);
    }
}

# ---------------------------------------------------------------------------
# Command-line interface
# ---------------------------------------------------------------------------

sub usage ($status = 0) {
    my $fh = $status ? *STDERR : *STDOUT;
    print {$fh} <<'USAGE';
Usage:
  perl fermat_superpsp_base2_smallest.pl [options] [n]

Find the smallest Fermat superpseudoprime to base 2 (super-Poulet number) with
exactly n >= 2 distinct prime factors (OEIS A050217).  Without n, print the
terms for n = 2..6.

Options:
  --upper=N         Start with the known upper bound N (the search finds the
                    smallest term <= N)
  --scan-steps=N    Factor 2^d-1 when more than N progression steps would be
                    scanned (5000)
  --factor-bits=N   Largest d for which 2^d-1 is factored (128)
  --verbose         Print search statistics to STDERR
  --help            Show this help
USAGE
    exit $status;
}

my $upper       = undef;
my $scan_steps  = 5000;
my $factor_bits = 128;
my $verbose     = 0;
my $help        = 0;

GetOptions(
           'upper=s'       => \$upper,
           'scan-steps=i'  => \$scan_steps,
           'factor-bits=i' => \$factor_bits,
           'verbose!'      => \$verbose,
           'help|h'        => \$help,
          )
  or usage(2);

usage(0) if $help;
usage(2) if @ARGV > 1;

my @ns = @ARGV ? ($ARGV[0]) : (2 .. 8);

foreach my $n (@ns) {
    usage(2) if $n !~ /\A\d+\z/ || $n < 2;
    my $term = fermat_superpsp_base2_smallest(
                                              $n,
                                              upper       => $upper,
                                              scan_steps  => $scan_steps,
                                              factor_bits => $factor_bits,
                                              verbose     => $verbose,
                                             );
    say "a($n) = $term";
    say STDERR "factorization: ", join(' * ', map { $_->[1] > 1 ? "$_->[0]^$_->[1]" : $_->[0] } factor_exp("$term")) if $verbose;
}
