#!/usr/bin/env perl

# Daniel "Trizen" Șuteu
# https://github.com/trizen

# Smallest Fermat overpseudoprime to base 2 with exactly n distinct prime factors
# (OEIS A141232).
#
# Usage:
#   perl fermat_overpsp_base2_smallest.pl [options] [n]
#
# As a library:
#   my $z = fermat_overpsp_base2_smallest($n);    # n >= 2, returns a Math::GMPz
#
# Options:
#   --upper=N         Start with the (known) upper bound N instead of the doubling
#                     search; the search then finds the smallest term <= N
#   --scan-steps=N    Resolve a multiplier by factoring a cyclotomic cofactor when more
#                     than N progression steps would otherwise be scanned (default: 5000)
#   --factor-bits=N   Largest cofactor (in bits) handed to the factoring routine (160)
#   --verbose         Print search statistics to STDERR
#   --help            Show this help
#
# Requires Math::GMPz, Math::Prime::Util and Math::Prime::Util::GMP.
#
# How the search works
# --------------------
# An overpseudoprime n = prod p^e (base 2) is a Fermat pseudoprime whose prime powers all
# have the same multiplicative order lambda = ord_{p^e}(2), with lambda | n-1.  Every such
# prime p is a primitive prime divisor of 2^lambda - 1 (ord_p(2) = lambda exactly), so
# p == 1 (mod lambda); then n == 1 (mod lambda) comes for free, and *any* product of
# k >= 2 distinct primes of
#
#     S_lambda = { p prime : ord_p(2) = lambda }
#
# is an overpseudoprime.  A prime power p^e with e >= 2 only makes n larger (p already
# has the right order), so the smallest term with k distinct prime factors is
#
#     a(k) = min over lambda of  (the product of the k smallest primes of S_lambda).
#
# Hence the search runs over lambda (not over a tree of primes):
#
#   * the primes of S_lambda are p = j*lambda + 1 (j even when lambda is odd), and they
#     are tested in increasing order with  2^lambda == 1 (mod p),  2^(lambda/r) != 1 (mod p)
#     for the primes r | lambda,  and a primality test (only done for the rare hits);
#   * the shared upper bound B is lowered to (n - 1) whenever a smaller term is found;
#   * lambda is limited by the product of the k smallest allowed values j*lambda + 1 <= B;
#   * the next prime is limited by  q*(q+s)*(q+2s)*... <= B / (product found so far)  (s is
#     the progression step), which is the only place where the scan can become long: the
#     last prime may be as large as B / (product of the other k-1);
#   * when the scan would be long, the cyclotomic number Phi_lambda(2) is used instead
#     (it is the product of the primes of S_lambda, up to the primes of lambda): the primes
#     found so far are divided out, and the cofactor is either 1 (dead), a prime (it is the
#     last prime, or dead) or is factored with Math::Prime::Util::GMP, which gives the
#     remaining primes of S_lambda at once;
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
# The smallest Fermat overpseudoprime to base 2 with exactly $k distinct prime factors.
# ---------------------------------------------------------------------------

sub fermat_overpsp_base2_smallest ($k, %opt) {

    die "n must be an integer >= 2\n" if !defined($k) || "$k" !~ /\A\d+\z/ || $k < 2;
    $k = 0 + $k;

    my $verbose     = $opt{verbose}     // 0;
    my $scan_steps  = $opt{scan_steps}  // 5000;
    my $factor_bits = $opt{factor_bits} // 160;
    my $upper       = $opt{upper};

    die "scan_steps must be a non-negative integer\n"  if $scan_steps                 !~ /\A\d+\z/;
    die "factor_bits must be a non-negative integer\n" if $factor_bits                !~ /\A\d+\z/;
    die "upper must be a positive integer\n"           if defined($upper) && "$upper" !~ /\A\+?0*[1-9]\d*\z/;

    my $NATIVE_MAX = 1.7e19;    # largest progression term tested with native integers

    # ---- state ----------------------------------------------------------------

    my $B         = Rmpz_init();    # current inclusive upper bound; lowered on every find
    my $logB      = 0;              # natural logarithm of B
    my $best      = Rmpz_init();
    my $have_best = 0;

    my ($P, $R, $NUM, $DEN, $TM, $TN) = map { Rmpz_init() } 1 .. 6;

    my ($lambdas, $tested, $resolved, $factored) = (0) x 4;

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
    # bound for the next prime of S_lambda when rem primes are still missing.
    my sub next_hi ($rem, $step, $log_prod) {
        my $target = $logB - $log_prod + 1e-9;
        return exp($target) + 1 if $rem == 1;

        my $q = exp($target / $rem) - 0.5 * ($rem - 1) * $step;
        $q = 1.0 if $q < 1.0;
        my $lo = 1.0;
        my $hi = exp($target / $rem) + 1.0;

        for (1 .. 25) {
            my ($f, $df) = (-$target, 0.0);
            for my $i (0 .. $rem - 1) {
                my $term = $q + $i * $step;
                $f  += log($term);
                $df += 1.0 / $term;
            }

            if (abs($f) <= 1e-12) {
                $hi = $q;
                last;
            }

            if   ($f < 0) { $lo = $q if $q > $lo }
            else          { $hi = $q if $q < $hi }

            my $next = ($df > 0) ? ($q - $f / $df) : (0.5 * ($lo + $hi));
            if ($next <= $lo || $next >= $hi) {
                $next = 0.5 * ($lo + $hi);
            }

            last if abs($next - $q) <= 1e-7 * ($q > 1.0 ? $q : 1.0);
            $q  = $next;
            $hi = $q if $f > 0 && $q < $hi;
        }

        return (($hi > $q ? $hi : $q) + 1);
    }

    # R = Phi_lambda(2) = prod_{s | rad(lambda)} (2^(lambda/s) - 1)^mu(s), with the primes of
    # lambda and the primes found so far divided out; all that is left are the primes of
    # S_lambda that are larger than the found ones.
    my sub reduced_phi ($lam, $pf, $found) {

        my $w = scalar(@$pf);

        Rmpz_set_ui($NUM, 1);
        Rmpz_set_ui($DEN, 1);

        foreach my $mask (0 .. (1 << $w) - 1) {
            my ($d, $odd) = ($lam, 0);
            foreach my $i (0 .. $w - 1) {
                if (($mask >> $i) & 1) { $d = int($d / $pf->[$i]); ++$odd }
            }
            Rmpz_set_ui($TM, 1);
            Rmpz_mul_2exp($TM, $TM, $d);
            Rmpz_sub_ui($TM, $TM, 1);
            if   ($odd & 1) { Rmpz_mul($DEN, $DEN, $TM) }
            else            { Rmpz_mul($NUM, $NUM, $TM) }
        }

        Rmpz_divexact($R, $NUM, $DEN);

        foreach my $r (@$pf, @$found) {
            while (Rmpz_divisible_ui_p($R, $r)) {
                Rmpz_divexact_ui($R, $R, $r);
            }
        }
    }

    # Finish a multiplier lambda with the cyclotomic cofactor.  Returns 1 if lambda is
    # finished (a candidate may have been recorded), 0 if the caller should keep scanning.
    my sub resolve ($lam, $pf, $found, $force) {

        ++$resolved;
        reduced_phi($lam, $pf, $found);

        return 1 if Rmpz_cmp_ui($R, 1) == 0;    # S_lambda is exhausted

        my $rem = $k - scalar(@$found);
        my $Rs  = Rmpz_get_str($R, 10);

        if (Math::Prime::Util::GMP::is_prime($Rs)) {
            if ($rem == 1) {
                Rmpz_mul($TN, $P, $R);
                record($TN);
            }
            return 1;
        }

        return 0 if !$force && Rmpz_sizeinbase($R, 2) > $factor_bits;

        ++$factored;

        my (%seen, @q);
        foreach my $s (Math::Prime::Util::GMP::factor($Rs)) {
            push @q, Rmpz_init_set_str($s, 10) if !$seen{$s}++;
        }

        return 1 if @q < $rem;

        @q = sort { Rmpz_cmp($a, $b) } @q;

        Rmpz_set($TN, $P);
        Rmpz_mul($TN, $TN, $q[$_]) for 0 .. $rem - 1;
        record($TN);

        return 1;
    }

    # ---- one pass: all multipliers lambda with the current bound --------------------

    my sub pass () {

      LAMBDA: for (my $lam = 2 ; ; ++$lam) {

            # the k smallest candidates j*lambda+1 (j even if lambda is odd) must have a
            # product <= B
            my $lb = 0;
            $lb += log($_ * $lam + 1) for 1 .. $k;
            last if $lb > $logB + 1e-9;

            my $step = ($lam & 1) ? 2 * $lam : $lam;

            if ($step != $lam) {
                my $lb2 = 0;
                $lb2 += log($_ * $step + 1) for 1 .. $k;
                next if $lb2 > $logB + 1e-9;
            }

            ++$lambdas;

            my @found;
            my $logP = 0;
            Rmpz_set_ui($P, 1);

            my $hi = next_hi($k, $step, 0);
            my $p  = $step + 1;

            my ($pf, @ldiv);    # prime factors of lambda, and lambda/r (computed on demand)
            my $tried = 0;

            my $need_resolve = sub ($force_only = 0) {
                $pf //= [map { $_->[0] } factor_exp($lam)];
                return resolve($lam, $pf, \@found, $hi > $NATIVE_MAX);
            };

            # long scan: use Phi_lambda(2) from the start
            if ($p <= $hi and ((($hi - $p) / $step > $scan_steps) or $hi > $NATIVE_MAX)) {
                $tried = 1;
                next LAMBDA if $need_resolve->();
            }

            while ($p <= $hi) {

                ++$tested;

                if (powmod(2, $lam, $p) == 1) {

                    if (!defined($pf)) {
                        $pf   = [map { $_->[0] } factor_exp($lam)];
                        @ldiv = map { int($lam / $_) } @$pf;
                    }
                    elsif (!@ldiv) {
                        @ldiv = map { int($lam / $_) } @$pf;
                    }

                    # ord_p(2) = lambda exactly (not a proper divisor of it), p prime
                    my $exact = 1;
                    foreach my $d (@ldiv) {
                        if (powmod(2, $d, $p) == 1) { $exact = 0; last }
                    }

                    if ($exact and is_prime($p)) {

                        push @found, $p;
                        Rmpz_mul_ui($P, $P, $p);
                        $logP += log($p);

                        if (@found == $k) {
                            record($P);
                            next LAMBDA;
                        }

                        $hi = next_hi($k - @found, $step, $logP);

                        if (!$tried and ((($hi - $p) / $step > $scan_steps) or $hi > $NATIVE_MAX)) {
                            $tried = 1;
                            next LAMBDA if $need_resolve->();
                        }
                    }
                }

                $p += $step;
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
        ($lambdas, $tested, $resolved, $factored) = (0) x 4;

        my $pass_bound = Rmpz_get_str($B, 10);
        pass();

        if ($verbose) {
            printf STDERR "[<= %s] lambdas=%d tested=%d phi_resolved=%d factored=%d time=%.3f s%s\n",
              $pass_bound, $lambdas, $tested, $resolved, $factored, time() - $started, ($have_best ? ' FOUND' : '');
        }

        return Rmpz_init_set($best) if $have_best;

        # nothing <= B: the multiplier range doubles with this growth of the bound
        Rmpz_mul_2exp($TM, $B, $k);
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
  perl fermat_overpsp_base2_smallest.pl [options] [n]

Find the smallest Fermat overpseudoprime to base 2 with exactly n >= 2 distinct
prime factors (OEIS A141232).  Without n, print the terms for n = 2..4.

Options:
  --upper=N         Start with the known upper bound N (the search finds the
                    smallest term <= N)
  --scan-steps=N    Use the cyclotomic cofactor when more than N progression
                    steps would be scanned (5000)
  --factor-bits=N   Largest cofactor (in bits) handed to the factoring routine (160)
  --verbose         Print search statistics to STDERR
  --help            Show this help
USAGE
    exit $status;
}

my $upper       = undef;
my $scan_steps  = 5000;
my $factor_bits = 160;
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

my @ns = @ARGV ? ($ARGV[0]) : (2 .. 6);

foreach my $n (@ns) {
    usage(2) if $n !~ /\A\d+\z/ || $n < 2;
    my $term = fermat_overpsp_base2_smallest(
                                             $n,
                                             upper       => $upper,
                                             scan_steps  => $scan_steps,
                                             factor_bits => $factor_bits,
                                             verbose     => $verbose,
                                            );
    say "a($n) = $term";
    say STDERR "factorization: ", join(' * ', map { $_->[1] > 1 ? "$_->[0]^$_->[1]" : $_->[0] } factor_exp("$term")) if $verbose;
}
