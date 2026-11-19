#!/usr/bin/env perl

# Daniel "Trizen" Șuteu
# Date: 12 November 2026
# Edit: 16 November 2026 (native 64-bit integer version, Carmichael numbers)
# https://github.com/trizen

# Generate all Carmichael numbers with exactly k distinct prime factors
# in the inclusive interval [A, B], with B < 2^64, using native integers only.
#
# Korselt's criterion:
#
#   n = p_1 * ... * p_k  (distinct odd primes, k >= 3)  is a Carmichael number
#   iff  (p_i - 1) | (n - 1)  for every i.
#
# Usage:
#   perl carmichael_numbers_in_range_native.pl [options] A B k
#
# Options:
#   --force-bits=N    Factor cofactors only when q_max has at most N bits
#                     (default: 64; 0 disables forced completion)
#   --force-count=N   Always factor directly when at most N candidates remain
#                     (default: 16; 0 disables forced completion)
#   --force-ratio=X   Also factor directly whenever the number of candidates is
#                     at most X * (estimated number of primes the ordinary loop
#                     would visit) (default: 1.0; 0 = use only --force-count)
#   --step-div=N      Use the divisors of (m-1) for the terminal prime when its
#                     progression has at least N steps (default: 64; 0 disables)
#   --verbose         Print search statistics to STDERR
#   --help            Show this help
#
# Requires Math::Prime::Util >= 0.74 (divint, cdivint, divisors($n, $limit)).
#
# Native-integer notes
# --------------------
# Everything is a plain Perl integer (UV), so B must be below 2^64.  Perl turns an
# overflowing product into an inexact floating point number, therefore:
#
#   * m*p and m*q never overflow: they are bounded by B by construction;
#   * lcm(L, p-1) can overflow: it is computed as (L / gcd) * (p-1) only after
#     checking that it stays <= B (a Carmichael number n satisfies L | n-1, so L < n);
#   * m+1 can be 2^64, so the bound p <= (m+1)/2 is computed as (m-1)/2 + 1;
#   * progressions are walked with "last if H - t < L", never by adding L past H.
#
# How the search works
# --------------------
# The primes p_1 < p_2 < ... < p_(k-1) are chosen by depth-first search; with
# m = p_1*...*p_j and L = lcm(p_1-1, ..., p_j-1), every completion n = m*q needs
# n == 1 (mod L).  Two shortcuts finish a subtree without enumerating it:
#
#   * forced completion: q must be one of the numbers  first + t*L  in
#     [q_min, q_max], where first = m^(-1) mod L; if there are few of them they
#     are factored directly.
#   * the last prime p_k: (p_k - 1) | (m - 1) and p_k == m^(-1) (mod lcm), so it
#     is either the single residue in its window, or found via divisors(m - 1).
#
# The last two levels (the loop over p_(k-1) and the terminal prime) are inlined,
# because that is where nearly all the nodes are.
#
# Facts used (all primes are odd: an even Carmichael number cannot exist):
#   * gcd(m, p-1) = 1 is necessary: a prime r | m with r | (p-1) would divide
#     both n and n-1;
#   * L divides n-1, hence L < B;
#   * (p_k - 1) divides (m - 1) with p_k != m, so p_k - 1 <= (m - 1) / 2.

use v5.36;
use strict;
use warnings;

use Getopt::Long      qw(GetOptions);
use Time::HiRes       qw(time);
use Math::Prime::Util 0.74 qw(:all);

use constant UV_MAX     => ~0;                       # 2^64 - 1
use constant UV_MAX_STR => '18446744073709551615';

# ---------------------------------------------------------------------------
# Input parsing
# ---------------------------------------------------------------------------

# Parse a decimal integer; returns (is_negative, value) where value < 2^64.
sub parse_uv ($name, $input) {

    die "$name must be a decimal integer\n"
      if !defined($input) || "$input" !~ /\A([+-]?)(\d+)\z/;

    my ($sign, $digits) = ($1, $2);
    $digits =~ s/\A0+(?=\d)//;

    die "$name must be below 2^64: this version works with native integers only\n"
      if (length($digits) > 20 || (length($digits) == 20 && $digits gt UV_MAX_STR));

    my $negative = ($sign eq '-' && $digits ne '0') ? 1 : 0;
    return ($negative, $digits + 0);
}

sub parse_nonnegative_native ($name, $value) {
    die "$name must be a non-negative integer\n"
      if !defined($value) || "$value" !~ /\A\d+\z/;
    my ($neg, $v) = parse_uv($name, $value);
    return $v;
}

# ---------------------------------------------------------------------------
# Generate all k-factor Carmichael numbers in [A, B], B < 2^64.
# ---------------------------------------------------------------------------

sub generate_carmichael ($A_input, $B_input, $k_input, $force_bits = 64, $force_count = 16, $verbose = 0, %opt) {

    my ($A_neg, $A) = parse_uv('A', $A_input);
    my ($B_neg, $B) = parse_uv('B', $B_input);

    die "k must be an integer >= 3\n"
      if !defined($k_input) || "$k_input" !~ /\A\d+\z/;
    my $k = parse_nonnegative_native('k', $k_input);
    die "k must be an integer >= 3\n" if $k < 3;

    $force_bits  = parse_nonnegative_native('--force-bits',  $force_bits);
    $force_count = parse_nonnegative_native('--force-count', $force_count);

    my $force_ratio = $opt{force_ratio} // 1.0;
    my $step_div    = $opt{step_div}    // 64;

    die "--force-ratio must be a non-negative number\n" if $force_ratio !~ /\A\d+(?:\.\d+)?\z/;
    $step_div = parse_nonnegative_native('--step-div', $step_div);

    my $started = time();
    my @results;

    $A = 0           if $A_neg;
    return \@results if $B_neg;
    return \@results if $A > $B;

    # prefix[j] = product of the j smallest odd primes: the smallest possible
    # product of j distinct odd primes.  (prefix <= B  <=>  prefix_prev <= B / p.)
    my @prefix = (1);
    my $p0     = 2;
    for my $j (1 .. $k) {
        $p0 = next_prime($p0);
        return \@results if $prefix[-1] > divint($B, $p0);
        push @prefix, $prefix[-1] * $p0;
    }

    # The bound A matters only if it is above the smallest possible product.
    my $A_matters = ($A > $prefix[$k]) ? 1 : 0;
    $A = $prefix[$k] if !$A_matters;

    # Largest prime that can appear in a non-terminal position.
    my $sieve_max = 3;
    for my $depth (0 .. $k - 2) {
        my $r = rootint(divint($B, $prefix[$depth]), $k - $depth);
        $sieve_max = $r if $r > $sieve_max;
    }

    # Odd primes; the last element is a sentinel larger than every loop bound.
    my @P = @{primes(3, next_prime($sieve_max))};

    die "Internal error: insufficient primes generated by the sieve\n" if (@P < 2);

    # Largest cofactor that forced completion may factor.
    my $force_limit = ($force_bits >= 64)                   ? UV_MAX : ((1 << $force_bits) - 1);
    my $force_ok    = ($force_bits > 0 && $force_count > 0) ? 1      : 0;

    my ($visited_nodes, $tail_nodes, $tail_primes, $forced_nodes, $factorizations, $terminal_hits) = (0) x 6;

    # Search node: m = product of the chosen primes, L = lcm of (p - 1); $rem primes
    # are still missing and they are all >= $P[$i0].
    sub ($m, $L, $i0, $rem) {

        ++$visited_nodes;

        my $qmax = divint($B, $m);
        my $lo   = $P[$i0];

        # Bound of the loop over primes: p^rem <= qmax.  lo > hi means dead node.
        my $hi = rootint($qmax, $rem);
        return if $lo > $hi;

        # Lower bound for the cofactor: lo * (lo+2) * (lo+4) * ...
        # (an overflow turns into a float >= 2^64, which is larger than qmax)
        my $qmin = $lo;
        for my $j (1 .. $rem - 1) { $qmin *= $P[$i0 + $j] }
        return if ($qmin > $qmax || $qmin >= 1.8446744073709552e19);

        if ($A_matters) {
            my $aq = cdivint($A, $m);
            if ($aq > $qmin) {
                $qmin = $aq;
                return if $qmin > $qmax;
            }
        }

        # ---- forced completion -------------------------------------------
        # Every completion is n = m*q with m*q == 1 (mod L), i.e.
        # q = first + t*L, where first = m^(-1) mod L.
        if ($force_ok && $L > 1 && $qmax <= $force_limit) {

            my $first = invmod($m, $L) // die "Internal error: modular inverse does not exist\n";

            if ($first < $qmin) {
                my $c = cdivint($qmin - $first, $L);
                return if $c > divint($qmax - $first, $L);    # first + c*L would exceed qmax
                $first += $c * $L;
            }
            elsif ($first > $qmax) {
                return;                                       # no candidate at all
            }

            my $cnt = divint($qmax - $first, $L) + 1;

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

                for (my $q = $first ; ; $q += $L) {
                    ++$factorizations;

                    if (is_almost_prime($rem, $q)) {
                        my @f = factor_exp($q);
                        if (@f == $rem && $f[0][0] >= $lo) {
                            my $n  = $m * $q;
                            my $ok = 1;
                            foreach my $pe (@f) {
                                my ($s, $e) = @$pe;
                                if ($e != 1 or ($n - 1) % ($s - 1) != 0) { $ok = 0; last }    # (s-1) | (n-1)
                            }
                            push @results, $n if $ok;
                        }
                    }

                    last if $qmax - $q < $L;
                }
                return;
            }
        }

        # ---- ordinary recursion ---------------------------------------------
        if ($rem > 2) {

            for (my $i = $i0 ; ; ++$i) {
                my $p = $P[$i];
                last if $p > $hi;

                # p-1 must be coprime to m (a prime of m cannot divide both n and n-1)
                next if gcd($m, $p - 1) != 1;

                my $L2 = lcm($L, $p - 1);

                # L divides n-1, hence L < n <= B
                next if $L2 >= $B;

                __SUB__->($m * $p, $L2, $i + 1, $rem - 1);
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

            my $L2 = lcm($L, $p - 1);
            next if $L2 >= $B;
            my $m2 = $m * $p;

            # t = m2^(-1) mod L2.  There is no inverse (undef) exactly when m2 and L2
            # share a factor, i.e. when gcd(m, p-1) != 1: such p are rejected here, so
            # a separate gcd() call is not needed in this loop.
            my $t = invmod($m2, $L2) // next;

            # common case: the residue is above the window -> no terminal prime
            my $H = divint($qmax, $p);
            next if $t > $H;

            # ---- rare path: the residue is inside the window ----
            my $m2m1 = $m2 - 1;

            # exactly one candidate (p4 = t): test the divisibility first
            if ($H - $t < $L2) {
                next if $t <= $p + 1;            # p4 must exceed p (this also excludes t = 1)
                next if $m2m1 % ($t - 1) != 0;
                my $n = $m2 * $t;
                next if $n < $A;
                if (is_prime($t)) {
                    ++$terminal_hits;
                    push @results, $n;
                }
                next;
            }

            # several candidates: (p4 - 1) is a proper divisor of the even number
            # m2 - 1, hence p4 <= (m2 + 1) / 2 = (m2 - 1) / 2 + 1
            my $cap = divint($m2m1, 2) + 1;
            $H = $cap if $cap < $H;

            my $lo4 = $p + 2;
            if ($A_matters) {
                my $aq = cdivint($A,  $m);
                my $x  = cdivint($aq, $p);
                $lo4 = $x if $x > $lo4;
            }

            if ($t < $lo4) {
                next if $t > $H;
                my $c = cdivint($lo4 - $t, $L2);
                next if $c > divint($H - $t, $L2);    # t + c*L2 would exceed H
                $t += $c * $L2;
            }
            next if $t > $H;

            # many steps: enumerate the divisors of m2 - 1 instead
            if ($step_div > 0 && divint($H - $t, $L2) >= $step_div) {

                foreach my $dv (divisors($m2m1, $H - 1)) {
                    my $p4 = $dv + 1;
                    next if $p4 < $t;
                    last if $p4 > $H;
                    if (($p4 - $t) % $L2 == 0 and is_prime($p4)) {
                        ++$terminal_hits;
                        push @results, $m2 * $p4;
                    }
                }
                next;
            }

            # few steps: walk the progression
            for (; ; $t += $L2) {
                if ($m2m1 % ($t - 1) == 0 and is_prime($t)) {
                    ++$terminal_hits;
                    push @results, $m2 * $t;
                }
                last if $H - $t < $L2;
            }
        }

        $tail_primes += $i - $i0;
        return;
      }
      ->(1, 1, 0, $k);

    @results = sort { $a <=> $b } @results;

    if ($verbose) {
        my $elapsed = time() - $started;
        printf STDERR "k=%d, sieve=%s, nodes=%d, tails=%d, tail_primes=%d, forced=%d, factorizations=%d, terminal=%d, results=%d, time=%.3f s\n",
          $k, $sieve_max, $visited_nodes, $tail_nodes, $tail_primes, $forced_nodes, $factorizations, $terminal_hits, scalar(@results), $elapsed;
    }

    return \@results;
}

# ---------------------------------------------------------------------------
# Command-line interface and examples
# ---------------------------------------------------------------------------

sub usage () {
    print <<'USAGE';
Usage:
  perl carmichael_numbers_in_range_native.pl [options] A B k

Generate every Carmichael number with exactly k distinct prime factors
in the inclusive range [A, B], using native integers only: B must be below 2^64
(use the Math::GMPz version for larger ranges).

Options:
  --force-bits=N    Maximum bit length for forced cofactor factoring (64)
  --force-count=N   Always factor directly when at most N candidates remain (16)
  --force-ratio=X   Also factor directly when candidates <= X * estimated loop
                    size (1.0; 0 = use only --force-count)
  --step-div=N      Use divisors(m-1) when the terminal progression has at
                    least N steps (64; 0 disables)
  --verbose         Print search statistics to STDERR
  --help            Show this help

With no positional arguments, run default Carmichael examples.
A negative or "+"-prefixed A must follow "--" (e.g.: ... -- -50 1000 3).
USAGE
}

my $force_bits  = 64;
my $force_count = 16;
my $force_ratio = 1.0;
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

sub print_result ($label, $A, $B, $k, $force_bits, $force_count, $verbose) {
    say $label;
    my $numbers = generate_carmichael(
                                      $A, $B, $k, $force_bits, $force_count, $verbose,
                                      force_ratio => $force_ratio,
                                      step_div    => $step_div,
                                     );
    say '[', join(', ', @$numbers), ']';
}

sub A182490($n) {

    my $from  = powint(2, $n);
    my $upto  = powint(2, $n + 1);
    my $total = 0;

    for (my $k = 3 ; ; ++$k) {
        my @arr = @{generate_carmichael($from, $upto, $k)};
        $total += scalar(@arr) || last;
    }

    return $total;
}

if (!@ARGV) {
    local $| = 1;
    foreach my $n (1 .. 37) {
        print(A182490($n), ", ");
    }
}
else {
    die "Expected exactly three positional arguments: A B k\n" if @ARGV != 3;
    my ($A, $B, $k) = @ARGV;
    print_result("$k-factor Carmichael numbers in [$A, $B]:", $A, $B, $k, $force_bits, $force_count, $verbose);
}
