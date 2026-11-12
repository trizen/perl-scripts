#!/usr/bin/env perl

# Daniel "Trizen" Șuteu
# Date: 12 November 2026
# https://github.com/trizen

# Generate all Carmichael numbers with exactly k distinct prime factors
# in the inclusive interval [A, B], using Korselt's criterion.
#
# Usage:
#   perl carmichael_numbers_in_range.pl [options] A B k
#
# With no positional arguments, run the three examples from the Sidef source.
#
# Options:
#   --force-bits=N    Factor cofactors only when q_max has at most N bits
#                    (default: 64; 0 disables forced completion)
#   --force-count=N   Factor cofactors only when at most N candidates remain
#                    (default: 16; 0 disables forced completion)
#   --verbose         Print search statistics to STDERR
#   --help            Show this help
#
# The interval endpoints and all search arithmetic use arbitrary-precision
# Math::GMPz integers.  Native prime sieving is used when possible; if the
# required bound exceeds native precision, the GMP prime backend is used.  In
# either case, the complete prime list must fit in available memory.

use v5.36;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Time::HiRes  qw(time);

use Math::GMPz             qw(:mpz);
use Math::Prime::Util      qw(primes next_prime is_prime factor_exp);
use Math::Prime::Util::GMP ();

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

# ---------------------------------------------------------------------------
# Generate all k-factor Carmichael numbers in [A, B].
#
# A and B may be decimal strings of arbitrary length.  The returned array
# contains Math::GMPz objects, sorted numerically.
# ---------------------------------------------------------------------------

sub generate_carmichael ($A_input, $B_input, $k_input, $force_bits = 64, $force_count = 16, $verbose = 0) {

    die "A must be a decimal integer\n"
      if !defined($A_input) || "$A_input" !~ /\A[+-]?\d+\z/;
    die "B must be a decimal integer\n"
      if !defined($B_input) || "$B_input" !~ /\A[+-]?\d+\z/;

    die "k must be an integer >= 3\n"
      if !defined($k_input) || "$k_input" !~ /\A\d+\z/;

    my $k_z = z_from_dec($k_input);
    die "k is too large for native indexing\n"
      if !Rmpz_fits_ulong_p($k_z);
    my $k = Rmpz_get_ui($k_z);
    die "k must be an integer >= 3\n" if $k < 3;

    $force_bits  = parse_nonnegative_native('--force-bits',  $force_bits);
    $force_count = parse_nonnegative_native('--force-count', $force_count);

    my $started = time();
    my $A       = z_from_dec($A_input);
    my $B       = z_from_dec($B_input);
    my @results;

    return \@results if Rmpz_cmp($A, $B) > 0;

    # The first k odd primes give the absolute lower bound for a number with
    # k distinct odd prime factors.  Carmichael numbers are necessarily odd.
    my @first_primes;
    my $p = 2;
    while (@first_primes < $k) {
        $p = next_prime($p);
        push @first_primes, $p;
    }

    # prefix_product[i] = product of the first i odd primes.
    my @prefix_product = map { Rmpz_init() } 0 .. $k;
    Rmpz_set_ui($prefix_product[0], 1);

    for my $i (1 .. $k) {
        Rmpz_mul_ui($prefix_product[$i], $prefix_product[$i - 1], $first_primes[$i - 1],);
    }

    # Restrict the searched interval to values that can possibly have k
    # distinct odd prime factors.
    my $lower = Rmpz_init();
    my $upper = Rmpz_init_set($B);
    if (Rmpz_cmp($A, $prefix_product[$k]) > 0) {
        Rmpz_set($lower, $A);
    }
    else {
        Rmpz_set($lower, $prefix_product[$k]);
    }

    return \@results if Rmpz_cmp($lower, $upper) > 0;

    my $upper_minus1 = Rmpz_init();
    Rmpz_sub_ui($upper_minus1, $upper, 1);

    # Compute a global upper bound for every non-terminal prime loop.
    my $sieve_limit = Rmpz_init_set_ui($first_primes[-1]);
    my ($tmp, $root) = (Rmpz_init(), Rmpz_init());

    for my $depth (0 .. $k - 2) {
        my $remaining = $k - $depth;
        Rmpz_fdiv_q($tmp, $upper, $prefix_product[$depth]);
        Rmpz_root($root, $tmp, $remaining);
        Rmpz_set($sieve_limit, $root)
          if Rmpz_cmp($root, $sieve_limit) > 0;
    }

    # Extend the sieve limit by k+2 *proven* primes.  The GMP prime iterator
    # uses BPSW for values above 64 bits, so verify each extension before
    # counting it as a prime.
    my $sieve_max    = Rmpz_init_set($sieve_limit);
    my $extra_primes = 0;
    while ($extra_primes < $k + 2) {
        my $next = next_prime($sieve_max);
        Rmpz_set_str($sieve_max, "$next", 10);
        ++$extra_primes if is_prime($next);
    }

    my $prime_ref = primes(3, $sieve_max);

    # Keep native primes as UVs for the fast path, and promote only primes
    # outside native precision to Math::GMPz objects.
    my (@odd_primes, @odd_primes_z);
    my $proven_suffix_primes = 0;

    for my $prime (@$prime_ref) {
        my $prime_z = z_from_dec($prime);

        ++$proven_suffix_primes if Rmpz_cmp($prime_z, $sieve_limit) > 0;

        if (Rmpz_fits_ulong_p($prime_z)) {
            push @odd_primes,   Rmpz_get_ui($prime_z);
            push @odd_primes_z, undef;
        }
        else {
            push @odd_primes,   undef;
            push @odd_primes_z, $prime_z;
        }
    }

    die "Internal error: insufficient primes generated by the sieve\n"
      if @odd_primes < $k || $proven_suffix_primes < $k + 2;

    # -----------------------------------------------------------------------
    # Scratch objects.  DFS state is kept per depth because a recursive call
    # must not overwrite objects still needed by its parent.
    # -----------------------------------------------------------------------

    my (@M, @LCM, @QMIN, @QMAX, @ROOT, @GCD, @MIN_FULL, @LOWER_FACTOR, @P_MINUS1);

    for my $depth (0 .. $k) {
        $M[$depth]            = Rmpz_init();
        $LCM[$depth]          = Rmpz_init();
        $QMIN[$depth]         = Rmpz_init();
        $QMAX[$depth]         = Rmpz_init();
        $ROOT[$depth]         = Rmpz_init();
        $GCD[$depth]          = Rmpz_init();
        $MIN_FULL[$depth]     = Rmpz_init();
        $LOWER_FACTOR[$depth] = Rmpz_init();
        $P_MINUS1[$depth]     = Rmpz_init();
    }

    Rmpz_set_ui($M[0],            1);
    Rmpz_set_ui($LCM[0],          1);
    Rmpz_set_ui($LOWER_FACTOR[0], 3);

    # Terminal-loop scratch objects.
    my ($T_PMAX, $T_PMIN, $T_RESIDUE, $T_STEP, $T_TMP, $T_M_MINUS1, $T_P_MINUS1, $T_N, $T_P) =
      map { Rmpz_init() } 1 .. 9;

    # Forced-completion scratch objects.
    my ($F_QMIN, $F_STEP, $F_FIRST, $F_Q, $F_TMP, $F_FACTOR, $F_FULL_LCM, $F_D, $F_N, $F_N_MINUS1) =
      map { Rmpz_init() } 1 .. 10;
    my @F_FACTORS = map { Rmpz_init() } 0 .. $k - 1;

    my ($visited_nodes, $terminal_nodes, $forced_nodes, $factorizations) = (0, 0, 0, 0);

    # -----------------------------------------------------------------------
    # Check one cofactor q by factoring it completely and applying Korselt.
    #
    # Return values:
    #   0  candidate rejected
    #   1  candidate accepted (a copy is appended to $out)
    # -----------------------------------------------------------------------

    my $test_forced_product = sub ($m, $old_lcm, $q, $remaining, $smallest_factor, $out) {

        return 0 if Rmpz_cmp_ui($q, 1) <= 0;
        ++$factorizations;

        my @factors = factor_exp(Math::GMPz::Rmpz_get_str($q, 10));

        for my $pp (@factors) {
            my ($factor, $exponent) = @$pp;
            $exponent == 1 or return 0;    # must be squarefree
        }

        return 0 if @factors != $remaining;

        Rmpz_set($F_FULL_LCM, $old_lcm);

        for my $i (0 .. $#factors) {
            Rmpz_set_str($F_FACTORS[$i], "$factors[$i][0]", 10);
            return 0 if Rmpz_cmp($F_FACTORS[$i], $smallest_factor) < 0;

            Rmpz_sub_ui($F_D, $F_FACTORS[$i], 1);
            Rmpz_lcm($F_FULL_LCM, $F_FULL_LCM, $F_D);
            return 0 if Rmpz_cmp($F_FULL_LCM, $upper_minus1) > 0;
        }

        Rmpz_mul($F_N, $m, $q);
        return 0
          if Rmpz_cmp($F_N, $lower) < 0
          || Rmpz_cmp($F_N, $upper) > 0;

        Rmpz_sub_ui($F_N_MINUS1, $F_N, 1);
        return 0 if !Rmpz_divisible_p($F_N_MINUS1, $F_FULL_LCM);

        push @$out, Rmpz_init_set($F_N);
        return 1;
    };

    # -----------------------------------------------------------------------
    # Try to complete a subtree by factoring the few possible q values
    # satisfying m*q == 1 (mod old_lcm).
    #
    # Return true if the entire subtree has been handled (including the case
    # where the interval contains no admissible q); false means DFS should
    # continue.  If a cofactor has an unproved probable-prime factor, no
    # partial results are committed and DFS is used instead.
    # -----------------------------------------------------------------------

    my $try_forced_completion = sub ($m, $old_lcm, $smallest_factor, $remaining, $q_min_in, $q_max) {

        return 0 if $force_bits == 0 || $force_count == 0;
        return 0
          if Rmpz_cmp_ui($old_lcm, 1) <= 0
          || Rmpz_cmp_ui($q_max,   0) <= 0;

        Rmpz_set($F_QMIN, $q_min_in);

        # q >= ceil(lower / m).
        Rmpz_cdiv_q($F_TMP, $lower, $m);
        Rmpz_set($F_QMIN, $F_TMP)
          if Rmpz_cmp($F_TMP, $F_QMIN) > 0;
        return 1 if Rmpz_cmp($F_QMIN, $q_max) > 0;

        # q == m^(-1) (mod old_lcm).
        Rmpz_set($F_STEP, $old_lcm);
        Rmpz_invert($F_FIRST, $m, $old_lcm)
          or die "Internal error: modular inverse does not exist\n";

        if (Rmpz_cmp($F_FIRST, $F_QMIN) < 0) {
            Rmpz_sub($F_TMP, $F_QMIN, $F_FIRST);
            Rmpz_cdiv_q($F_TMP, $F_TMP, $F_STEP);
            Rmpz_addmul($F_FIRST, $F_TMP, $F_STEP);
        }

        return 1 if Rmpz_cmp($F_FIRST, $q_max) > 0;
        return 0 if Rmpz_sizeinbase($q_max, 2) > $force_bits;

        # Number of candidates is floor((q_max - first)/step) + 1.
        Rmpz_sub($F_TMP, $q_max, $F_FIRST);
        Rmpz_fdiv_q($F_TMP, $F_TMP, $F_STEP);
        return 0 if Rmpz_cmp_ui($F_TMP, $force_count - 1) > 0;

        ++$forced_nodes;
        Rmpz_set($F_Q, $F_FIRST);

        my @pending_results;
        my $inconclusive = 0;

        while (Rmpz_cmp($F_Q, $q_max) <= 0) {
            my $status = $test_forced_product->($m, $old_lcm, $F_Q, $remaining, $smallest_factor, \@pending_results,);
            $inconclusive = 1 if $status < 0;
            Rmpz_add($F_Q, $F_Q, $F_STEP);
        }

        return 0 if $inconclusive;
        push @results, @pending_results;
        return 1;
    };

    # -----------------------------------------------------------------------
    # Depth-first search.
    #
    # m, old_lcm are GMP integers and are read-only in this call.
    # smallest_factor and prime_index refer to the next allowed prime.
    # -----------------------------------------------------------------------

    sub ($m, $old_lcm, $smallest_factor, $prime_index, $remaining, $depth) {

        ++$visited_nodes;

        # ---- Final prime: solve p == m^(-1) (mod old_lcm).
        if ($remaining == 1) {
            ++$terminal_nodes;

            Rmpz_fdiv_q($T_PMAX, $upper, $m);
            Rmpz_set($T_PMAX, $m)
              if Rmpz_cmp($T_PMAX, $m) > 0;

            Rmpz_cdiv_q($T_PMIN, $lower, $m);
            Rmpz_set($T_PMIN, $smallest_factor)
              if Rmpz_cmp($T_PMIN, $smallest_factor) < 0;
            return if Rmpz_cmp($T_PMIN, $T_PMAX) > 0;

            Rmpz_invert($T_RESIDUE, $m, $old_lcm)
              or die "Internal error: terminal modular inverse does not exist\n";
            Rmpz_set($T_STEP, $old_lcm);

            if (Rmpz_cmp($T_RESIDUE, $T_PMIN) < 0) {
                Rmpz_sub($T_TMP, $T_PMIN, $T_RESIDUE);
                Rmpz_cdiv_q($T_TMP, $T_TMP, $T_STEP);
                Rmpz_addmul($T_RESIDUE, $T_TMP, $T_STEP);
            }
            return if Rmpz_cmp($T_RESIDUE, $T_PMAX) > 0;

            # Since p-1 | m*p-1 iff p-1 | m-1, this is the last Korselt
            # condition that remains to be checked for the terminal prime.
            Rmpz_sub_ui($T_M_MINUS1, $m, 1);

            # Fast path when the entire progression fits native unsigned long.
            if (   Rmpz_fits_ulong_p($T_PMAX)
                && Rmpz_fits_ulong_p($T_RESIDUE)
                && Rmpz_fits_ulong_p($T_STEP)) {

                my $p_native = Rmpz_get_ui($T_RESIDUE);
                my $p_max    = Rmpz_get_ui($T_PMAX);
                my $step     = Rmpz_get_ui($T_STEP);

                while ($p_native <= $p_max) {
                    if (Rmpz_divisible_ui_p($T_M_MINUS1, $p_native - 1)) {
                        if (is_prime($p_native)) {
                            Rmpz_mul_ui($T_N, $m, $p_native);
                            push @results, Rmpz_init_set($T_N);
                        }
                    }

                    last if $step > $p_max - $p_native;
                    $p_native += $step;
                }
            }
            else {
                # Fully GMP-backed path for candidates or progression steps
                # beyond the native unsigned-integer range.
                my $p = $T_P;
                Rmpz_set($p, $T_RESIDUE);

                while (Rmpz_cmp($p, $T_PMAX) <= 0) {
                    Rmpz_sub_ui($T_P_MINUS1, $p, 1);

                    if (Rmpz_divisible_p($T_M_MINUS1, $T_P_MINUS1)) {
                        if (is_prime($p)) {
                            Rmpz_mul($T_N, $m, $p);
                            push @results, Rmpz_init_set($T_N);
                        }
                    }

                    Rmpz_add($p, $p, $T_STEP);
                }
            }

            return;
        }

        # ---- Minimum possible product of the remaining distinct odd primes.
        my $q_min = $QMIN[$depth];
        Rmpz_set_ui($q_min, 1);

        my $last_needed = $prime_index + $remaining - 1;
        return if $last_needed > $#odd_primes;

        for my $i ($prime_index .. $last_needed) {
            if (defined $odd_primes[$i]) {
                Rmpz_mul_ui($q_min, $q_min, $odd_primes[$i]);
            }
            else {
                Rmpz_mul($q_min, $q_min, $odd_primes_z[$i]);
            }
            return if Rmpz_cmp($q_min, $upper) > 0;
        }

        my $q_max = $QMAX[$depth];
        Rmpz_fdiv_q($q_max, $upper, $m);
        return if Rmpz_cmp($q_min, $q_max) > 0;

        # Direct factoring can be cheaper than branching when only a few
        # cofactor candidates remain in the required congruence class.
        return if $try_forced_completion->($m, $old_lcm, $smallest_factor, $remaining, $q_min, $q_max,);

        my $root = $ROOT[$depth];
        Rmpz_root($root, $q_max, $remaining);

        my $child_m   = $M[$depth + 1];
        my $child_lcm = $LCM[$depth + 1];
        my $min_full  = $MIN_FULL[$depth];
        my $gcd       = $GCD[$depth];
        my $last      = $#odd_primes;

        my $child_lower = $LOWER_FACTOR[$depth + 1];
        my $p_minus1    = $P_MINUS1[$depth];

        for (my $i = $prime_index ; $i <= $last ; ++$i) {
            my $p_ui = $odd_primes[$i];
            my $p_z  = $odd_primes_z[$i];

            my $p_is_native = defined $p_ui;
            if ($p_is_native) {
                last if Rmpz_cmp_ui($root, $p_ui) < 0;

                my $pm1 = $p_ui - 1;

                # Necessary for m*q == 1 (mod p-1): gcd(m,p-1) = 1.
                next if Rmpz_gcd_ui($gcd, $m, $pm1) != 1;

                Rmpz_lcm_ui($child_lcm, $old_lcm, $pm1);
                next if Rmpz_cmp($child_lcm, $upper) >= 0;

                Rmpz_mul_ui($child_m, $m, $p_ui);
                Rmpz_set_ui($child_lower, $p_ui + 1);
            }
            else {
                last if Rmpz_cmp($p_z, $root) > 0;

                Rmpz_sub_ui($p_minus1, $p_z, 1);
                Rmpz_gcd($gcd, $m, $p_minus1);
                next if Rmpz_cmp_ui($gcd, 1) != 0;

                Rmpz_lcm($child_lcm, $old_lcm, $p_minus1);
                next if Rmpz_cmp($child_lcm, $upper) >= 0;

                Rmpz_mul($child_m, $m, $p_z);
                Rmpz_add_ui($child_lower, $p_z, 1);
            }

            # Complete this branch with the smallest available suffix primes.
            Rmpz_set($min_full, $child_m);
            my $impossible = 0;

            for my $j ($i + 1 .. $i + $remaining - 1) {
                if ($j > $last) {
                    $impossible = 1;
                    last;
                }

                if (defined $odd_primes[$j]) {
                    Rmpz_mul_ui($min_full, $min_full, $odd_primes[$j]);
                }
                else {
                    Rmpz_mul($min_full, $min_full, $odd_primes_z[$j]);
                }

                if (Rmpz_cmp($min_full, $upper) > 0) {
                    $impossible = 1;
                    last;
                }
            }

            # Later choices of p can only make the minimum completion larger.
            last if $impossible;

            __SUB__->($child_m, $child_lcm, $child_lower, $i + 1, $remaining - 1, $depth + 1);
        }
      }
      ->($M[0], $LCM[0], $LOWER_FACTOR[0], 0, $k, 0);

    @results = sort { Rmpz_cmp($a, $b) } @results;

    if ($verbose) {
        my $elapsed = time() - $started;
        printf STDERR
          "k=%d, sieve=%s, nodes=%d, forced=%d, factorizations=%d, terminal=%d, results=%d, time=%.3f s\n", $k, $sieve_max, $visited_nodes, $forced_nodes,
          $factorizations, $terminal_nodes, scalar(@results), $elapsed;
    }

    return \@results;
}

# ---------------------------------------------------------------------------
# Command-line interface and examples
# ---------------------------------------------------------------------------

sub usage () {
    print <<'USAGE';
Usage:
  perl carmichael_numbers_in_range.pl [options] A B k

Generate every Carmichael number with exactly k distinct prime factors
in the inclusive range [A, B]. A and B may be arbitrarily large decimal
integers.

Options:
  --force-bits=N    Maximum bit length for forced cofactor factoring (64)
  --force-count=N   Maximum number of forced cofactor candidates (16)
  --verbose         Print search statistics to STDERR
  --help            Show this help

With no positional arguments, run the three examples from the Sidef source.
USAGE
}

my $force_bits  = 64;
my $force_count = 16;
my $verbose     = 0;
my $help        = 0;

GetOptions(
           'force-bits=s'  => \$force_bits,
           'force-count=s' => \$force_count,
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

sub print_result ($label, $A, $B, $k, $force_bits, $force_count, $verbose) {
    say $label;
    my $numbers = generate_carmichael($A, $B, $k, $force_bits, $force_count, $verbose,);
    say '[', join(', ', map { z_string($_) } @$numbers), ']';
}

if (!@ARGV) {
    print_result('3-factor Carmichael numbers in [1, 10000]:', 1, 10000, 3, $force_bits, $force_count, $verbose,);
    say '';
    print_result('4-factor Carmichael numbers in [1, 1000000]:', 1, 1_000_000, 4, $force_bits, $force_count, $verbose,);
    say '';
    print_result('5-Carmichael numbers in the range [1050986, 18162001]:', 1_050_986, 18_162_001, 5, $force_bits, $force_count, $verbose,);
}
else {
    die "Expected exactly three positional arguments: A B k\n" if @ARGV != 3;
    my ($A, $B, $k) = @ARGV;
    print_result("$k-factor Carmichael numbers in [$A, $B]:", $A, $B, $k, $force_bits, $force_count, $verbose,);
}
