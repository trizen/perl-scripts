#!/usr/bin/perl

=begin

This script factorizes a natural number given as a command line
parameter into its prime factors. It first attempts to use trial
division to find very small factors, then uses other special-purpose
factorization methods to find slightly larger factors. If any large
factors remain, it uses the Self-Initializing Quadratic Sieve (SIQS) [2]
to factorize those.

[2] Contini, Scott Patrick. 'Factoring integers with the self-
    initializing quadratic sieve.' (1997).

=cut

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use POSIX qw(ULONG_MAX);
use experimental qw(signatures);

use ntheory qw(
  urandomm valuation sqrtmod invmod random_prime factor_exp vecmin
);

use Math::Prime::Util::GMP qw(
  is_power powmod vecprod sqrtint rootint logint is_prime
  gcd sieve_primes consecutive_integer_lcm lucas_sequence
);

my $ZERO = Math::GMPz->new(0);
my $ONE  = Math::GMPz->new(1);

local $| = 1;

# Tuning parameters
use constant {
              MASK_LIMIT                => 200,         # show Cn if n > MASK_LIMIT, where n ~ log_10(N)
              LOOK_FOR_SMALL_FACTORS    => 1,
              TRIAL_DIVISION_LIMIT      => 1_000_000,
              PHI_FINDER_ITERATIONS     => 100_000,
              FERMAT_ITERATIONS         => 100_000,
              NEAR_POWER_ITERATIONS     => 1_000,
              CFRAC_ITERATIONS          => 50_000,
              ORDER_ITERATIONS          => 200_000,
              HOLF_ITERATIONS           => 100_000,
              MBE_ITERATIONS            => 100,
              MILLER_RABIN_ITERATIONS   => 100,
              LUCAS_MILLER_ITERATIONS   => 50,
              SIQS_TRIAL_DIVISION_EPS   => 25,
              SIQS_MIN_PRIME_POLYNOMIAL => 400,
              SIQS_MAX_PRIME_POLYNOMIAL => 4000,
             };

my @small_primes = sieve_primes(2, TRIAL_DIVISION_LIMIT);

package Polynomial {

    sub new ($class, $coeff, $A = undef, $B = undef) {
        bless {
               a     => $A,
               b     => $B,
               coeff => $coeff,
              }, $class;
    }

    sub eval ($self, $x) {
        my $res = $ZERO;

        foreach my $k (@{$self->{coeff}}) {
            $res *= $x;
            $res += $k;
        }

        return $res;
    }
}

package FactorBasePrime {

    sub new ($class, $p, $t, $lp) {
        bless {
               p     => $p,
               soln1 => undef,
               soln2 => undef,
               t     => $t,
               lp    => $lp,
               ainv  => undef,
              }, $class;
    }
}

sub siqs_factor_base_primes ($n, $nf) {
    my @factor_base;

    foreach my $p (@small_primes) {
        my $t  = sqrtmod($n, $p) // next;
        my $lp = sprintf('%0.f', log($p) / log(2));
        push @factor_base, FactorBasePrime->new($p, $t, $lp);

        if (scalar(@factor_base) >= $nf) {
            last;
        }
    }

    return \@factor_base;
}

sub siqs_create_poly ($A, $B, $n, $factor_base, $first) {

    my $B_orig = $B;

    if (($B << 1) > $A) {
        $B = $A - $B;
    }

    # 0 < $B                   or die 'error';
    # 2 * $B <= $A             or die 'error';
    # ($B * $B - $n) % $A == 0 or die 'error';

    my $g = Polynomial->new([$A * $A, ($A * $B) << 1, $B * $B - $n], $A, $B_orig);
    my $h = Polynomial->new([$A, $B]);

    foreach my $fb (@$factor_base) {

        next if Math::GMPz::Rmpz_divisible_ui_p($A, $fb->{p});

#<<<
        $fb->{ainv}  = int(invmod($A, $fb->{p}))                         if $first;
        $fb->{soln1} = int(($fb->{ainv} * ( $fb->{t} - $B)) % $fb->{p});
        $fb->{soln2} = int(($fb->{ainv} * (-$fb->{t} - $B)) % $fb->{p});
#>>>

    }

    return ($g, $h);
}

sub siqs_find_first_poly ($n, $m, $factor_base) {
    my $p_min_i;
    my $p_max_i;

    foreach my $i (0 .. $#{$factor_base}) {
        my $fb = $factor_base->[$i];
        if (not defined($p_min_i) and $fb->{p} >= SIQS_MIN_PRIME_POLYNOMIAL) {
            $p_min_i = $i;
        }
        if (not defined($p_max_i) and $fb->{p} > SIQS_MAX_PRIME_POLYNOMIAL) {
            $p_max_i = $i - 1;
            last;
        }
    }

    # The following may happen if the factor base is small
    if (not defined($p_max_i)) {
        $p_max_i = $#{$factor_base};
    }

    if (not defined($p_min_i)) {
        $p_min_i = 5;
    }

    if ($p_max_i - $p_min_i < 20) {
        $p_min_i = vecmin($p_min_i, 5);
    }

    my $target0 = (log("$n") + log(2)) / 2 - log("$m");
    my $target1 = $target0 - log(($factor_base->[$p_min_i]{p} + $factor_base->[$p_max_i]{p}) / 2) / 2;

    # find q such that the product of factor_base[q_i] is approximately
    # sqrt(2 * n) / m; try a few different sets to find a good one
    my ($best_q, $best_a, $best_ratio);

    for (1 .. 30) {
        my $A     = $ONE;
        my $log_A = 0;

        my %Q;
        while ($log_A < $target1) {

            my $p_i = 0;
            while ($p_i == 0 or exists $Q{$p_i}) {
                $p_i = $p_min_i + urandomm($p_max_i - $p_min_i + 1);
            }

            my $fb = $factor_base->[$p_i];
            $A     *= $fb->{p};
            $log_A += log($fb->{p});
            $Q{$p_i} = $fb;
        }

        my $ratio = exp($log_A - $target0);

        # ratio too small seems to be not good
        if (   !defined($best_ratio)
            or ($ratio >= 0.9 and $ratio < $best_ratio)
            or ($best_ratio < 0.9 and $ratio > $best_ratio)) {
            $best_q     = \%Q;
            $best_a     = $A;
            $best_ratio = $ratio;
        }
    }

    my $A = $best_a;
    my $B = $ZERO;

    my @arr;

    foreach my $fb (values %$best_q) {
        my $p = $fb->{p};

        #($A % $p == 0) or die 'error';

        my $r = $A / $p;

        #$fb->{t} // die 'error';
        #gcd($r, $p) == 1 or die 'error';

        my $gamma = ($fb->{t} * int(invmod($r, $p))) % $p;

        if ($gamma > ($p >> 1)) {
            $gamma = $p - $gamma;
        }

        my $t = $r * $gamma;

        $B += $t;
        push @arr, $t;
    }

    my ($g, $h) = siqs_create_poly($A, $B, $n, $factor_base, 1);

    return ($g, $h, \@arr);
}

sub siqs_find_next_poly ($n, $factor_base, $i, $g, $arr) {

    # Compute the (i+1)-th polynomials for the Self-Initializing
    # Quadratic Sieve, given that g is the i-th polynomial.

    my $v = valuation($i, 2);
    my $z = ((($i >> ($v + 1)) & 1) == 0) ? -1 : 1;

    my $A = $g->{a};
    my $B = ($g->{b} + 2 * $z * $arr->[$v]) % $A;

    return siqs_create_poly($A, $B, $n, $factor_base, 0);
}

sub siqs_sieve ($factor_base, $m) {

    # Perform the sieving step of the SIQS. Return the sieve array.

    my @sieve_array = (0) x (2 * $m + 1);

    foreach my $fb (@$factor_base) {

        $fb->{p} > 100 or next;
        $fb->{soln1} // next;

        my $p   = $fb->{p};
        my $lp  = $fb->{lp};
        my $end = 2 * $m;

        my $i_start_1 = -int(($m + $fb->{soln1}) / $p);
        my $a_start_1 = int($fb->{soln1} + $i_start_1 * $p);

        for (my $i = $a_start_1 + $m ; $i <= $end ; $i += $p) {
            $sieve_array[$i] += $lp;
        }

        my $i_start_2 = -int(($m + $fb->{soln2}) / $p);
        my $a_start_2 = int($fb->{soln2} + $i_start_2 * $p);

        for (my $i = $a_start_2 + $m ; $i <= $end ; $i += $p) {
            $sieve_array[$i] += $lp;
        }
    }

    return \@sieve_array;
}

sub siqs_trial_divide ($n, $factor_base_info) {

    # Determine whether the given number can be fully factorized into
    # primes from the factors base. If so, return the indices of the
    # factors from the factor base. If not, return undef.

    my $factor_prod = $factor_base_info->{prod};

    state $g = Math::GMPz::Rmpz_init_nobless();
    state $t = Math::GMPz::Rmpz_init_nobless();

    Math::GMPz::Rmpz_set($t, $n);
    Math::GMPz::Rmpz_gcd($g, $t, $factor_prod);

    while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

        Math::GMPz::Rmpz_remove($t, $t, $g);

        if (Math::GMPz::Rmpz_cmp_ui($t, 1) == 0) {

            my $factor_index = $factor_base_info->{index};

            return [map { [$factor_index->{$_->[0]}, $_->[1]] } factor_exp($n)];
        }

        Math::GMPz::Rmpz_gcd($g, $t, $g);
    }

    return undef;
}

sub siqs_trial_division ($n, $sieve_array, $factor_base_info, $smooth_relations, $g, $h, $m, $req_relations) {

    # Perform the trial division step of the Self-Initializing Quadratic Sieve.

    my $limit = (log("$m") + log("$n") / 2) / log(2) - SIQS_TRIAL_DIVISION_EPS;

    foreach my $i (0 .. $#{$sieve_array}) {

        next if ((my $sa = $sieve_array->[$i]) < $limit);

        my $x  = $i - $m;
        my $gx = abs($g->eval($x));

        my $divisors_idx = siqs_trial_divide($gx, $factor_base_info) // next;

        my $u = $h->eval($x);
        my $v = $gx;

        #(($u * $u) % $n == ($v % $n)) or die 'error';

        push @$smooth_relations, [$u, $v, $divisors_idx];

        if (scalar(@$smooth_relations) >= $req_relations) {
            return 1;
        }
    }

    return 0;
}

sub siqs_build_matrix ($factor_base, $smooth_relations) {

    # Build the matrix for the linear algebra step of the Quadratic Sieve.
    my $fb = scalar(@$factor_base);
    my @matrix;

    foreach my $sr (@$smooth_relations) {
        my @row = (0) x $fb;
        foreach my $pair (@{$sr->[2]}) {
            $row[$pair->[0]] = $pair->[1] % 2;
        }
        push @matrix, \@row;
    }

    return \@matrix;
}

sub siqs_build_matrix_opt ($M) {

    # Convert the given matrix M of 0s and 1s into a list of numbers m
    # that correspond to the columns of the matrix.
    # The j-th number encodes the j-th column of matrix M in binary:
    # The i-th bit of m[i] is equal to M[i][j].

    my $m           = scalar(@{$M->[0]});
    my @cols_binary = ("") x $m;

    foreach my $mi (@$M) {
        foreach my $j (0 .. $#{$mi}) {
            $cols_binary[$j] .= $mi->[$j];
        }
    }

#<<<
    return ([map {
        Math::GMPz::Rmpz_init_set_str(scalar reverse($_), 2)
    } @cols_binary], scalar(@$M), $m);
#>>>
}

sub find_pivot_column_opt ($M, $j) {

    # For a matrix produced by siqs_build_matrix_opt, return the row of
    # the first non-zero entry in column j, or None if no such row exists.

    my $v = $M->[$j];

    if ($v == 0) {
        return undef;
    }

    return valuation($v, 2);
}

sub siqs_solve_matrix_opt ($M, $n, $m) {

    # Perform the linear algebra step of the SIQS. Perform fast
    # Gaussian elimination to determine pairs of perfect squares mod n.
    # Use the optimizations described in [1].

    # [1] Koç, Çetin K., and Sarath N. Arachchige. 'A Fast Algorithm for
    #    Gaussian Elimination over GF (2) and its Implementation on the
    #    GAPP.' Journal of Parallel and Distributed Computing 13.1
    #    (1991): 118-122.

    my @row_is_marked = (0) x $n;
    my @pivots        = (-1) x $m;

    foreach my $j (0 .. $m - 1) {

        my $i = find_pivot_column_opt($M, $j) // next;

        $pivots[$j]        = $i;
        $row_is_marked[$i] = 1;

        foreach my $k (0 .. $m - 1) {
            if ($k != $j and Math::GMPz::Rmpz_tstbit($M->[$k], $i)) {
                Math::GMPz::Rmpz_xor($M->[$k], $M->[$k], $M->[$j]);
            }
        }
    }

    my @perf_squares;
    foreach my $i (0 .. $n - 1) {
        if (not $row_is_marked[$i]) {
            my @perfect_sq_indices = ($i);
            foreach my $j (0 .. $m - 1) {
                if (Math::GMPz::Rmpz_tstbit($M->[$j], $i)) {
                    push @perfect_sq_indices, $pivots[$j];
                }
            }
            push @perf_squares, \@perfect_sq_indices;
        }
    }

    return \@perf_squares;
}

sub siqs_calc_sqrts ($n, $square_indices, $smooth_relations) {

    # Given on of the solutions returned by siqs_solve_matrix_opt and
    # the corresponding smooth relations, calculate the pair [a, b], such
    # that a^2 = b^2 (mod n).

    my $r1 = $ONE;
    my $r2 = $ONE;

    foreach my $i (@$square_indices) {
        ($r1 *= $smooth_relations->[$i][0]) %= $n;
        ($r2 *= $smooth_relations->[$i][1]);
    }

    $r2 = Math::GMPz->new(sqrtint($r2));

    return ($r1, $r2);
}

sub siqs_factor_from_square ($n, $square_indices, $smooth_relations) {

    # Given one of the solutions returned by siqs_solve_matrix_opt,
    # return the factor f determined by f = gcd(a - b, n), where
    # a, b are calculated from the solution such that a*a = b*b (mod n).
    # Return f, a factor of n (possibly a trivial one).

    my ($sqrt1, $sqrt2) = siqs_calc_sqrts($n, $square_indices, $smooth_relations);

    #(($sqrt1 * $sqrt1) % $n == ($sqrt2 * $sqrt2) % $n) or die 'error';

    return Math::GMPz->new(gcd($sqrt1 - $sqrt2, $n));
}

sub siqs_find_more_factors_gcd (@numbers) {
    my %res;

    foreach my $i (0 .. $#numbers) {
        my $n = $numbers[$i];
        $res{$n} = $n;
        foreach my $k ($i + 1 .. $#numbers) {
            my $m = $numbers[$k];

            my $fact = Math::GMPz->new(gcd($n, $m));
            if ($fact != 1 and $fact != $n and $fact != $m) {

                if (not exists($res{$fact})) {
                    say "SIQS: GCD found non-trivial factor: $fact";
                    $res{$fact} = $fact;
                }

                my $t1 = $n / $fact;
                my $t2 = $m / $fact;

                $res{$t1} = $t1;
                $res{$t2} = $t2;
            }
        }
    }

    return (values %res);
}

sub siqs_find_factors ($n, $perfect_squares, $smooth_relations) {

    # Perform the last step of the Self-Initializing Quadratic Field.
    # Given the solutions returned by siqs_solve_matrix_opt, attempt to
    # identify a number of (not necessarily prime) factors of n, and
    # return them.

    my @factors;
    my $rem = $n;

    my %non_prime_factors;
    my %prime_factors;

    foreach my $square_indices (@$perfect_squares) {
        my $fact = siqs_factor_from_square($n, $square_indices, $smooth_relations);

        if ($fact > 1 and $fact < $rem) {
            if (is_prime($fact)) {

                if (not exists $prime_factors{$fact}) {
                    say "SIQS: Prime factor found: $fact";
                    $prime_factors{$fact} = $fact;
                }

                $rem = check_factor($rem, $fact, \@factors);

                if ($rem == 1) {
                    last;
                }

                if (is_prime($rem)) {
                    push @factors, $rem;
                    $rem = 1;
                    last;
                }

                if (defined(my $root = check_perfect_power($rem))) {
                    say "SIQS: Perfect power detected with root: $root";
                    push @factors, $root;
                    $rem = 1;
                    last;
                }
            }
            else {
                if (not exists $non_prime_factors{$fact}) {
                    say "SIQS: Composite factor found: $fact";
                    $non_prime_factors{$fact} = $fact;
                }
            }
        }
    }

    if ($rem != 1 and keys(%non_prime_factors)) {
        $non_prime_factors{$rem} = $rem;

        my @primes;
        my @composites;

        foreach my $fact (siqs_find_more_factors_gcd(values %non_prime_factors)) {
            if (is_prime($fact)) {
                push @primes, $fact;
            }
            elsif ($fact > 1) {
                push @composites, $fact;
            }
        }

        foreach my $fact (@primes, @composites) {

            if ($fact != $rem and $rem % $fact == 0) {
                say "SIQS: Using non-trivial factor from GCD: $fact";
                $rem = check_factor($rem, $fact, \@factors);
            }

            if ($rem == 1 or is_prime($rem)) {
                last;
            }
        }
    }

    if ($rem != 1) {
        push @factors, $rem;
    }

    return @factors;
}

sub siqs_choose_range ($n) {

    # Choose m for sieving in [-m, m].

    $n = "$n";

    return sprintf('%.0f', exp(sqrt(log($n) * log(log($n))) / 2));
}

sub siqs_choose_nf ($n) {

    # Choose parameters nf (sieve of factor base)

    $n = "$n";

    return sprintf('%.0f', exp(sqrt(log($n) * log(log($n))))**(sqrt(2) / 4));
}

sub siqs_choose_nf2 ($n) {

    # Choose parameters nf (sieve of factor base)
    $n = "$n";

    return sprintf('%.0f', exp(sqrt(log($n) * log(log($n))) / 2));
}

sub siqs_factorize ($n, $nf) {

    # Use the Self-Initializing Quadratic Sieve algorithm to identify
    # one or more non-trivial factors of the given number n. Return the
    # factors as a list.

    my $m = siqs_choose_range($n);

    my @factors;
    my $factor_base = siqs_factor_base_primes($n, $nf);
    my $factor_prod = Math::GMPz->new(vecprod(map { $_->{p} } @$factor_base));

    my %factor_base_index;
    @factor_base_index{map { $_->{p} } @{$factor_base}} = 0 .. $#{$factor_base};

    my $factor_base_info = {
                            base  => $factor_base,
                            prod  => $factor_prod,
                            index => \%factor_base_index,
                           };

    my $smooth_relations         = [];
    my $required_relations_ratio = 1;

    my $success  = 0;
    my $prev_cnt = 0;
    my $i_poly   = 0;

    my ($g, $h, $arr);

    while (not $success) {

        say "*** Step 1/2: Finding smooth relations ***";
        say "SIQS sieving range: [-$m, $m]";

        my $required_relations = sprintf('%.0f', (scalar(@$factor_base) + 1) * $required_relations_ratio);
        say "Target: $required_relations relations.";
        my $enough_relations = 0;

        while (not $enough_relations) {
            if ($i_poly == 0) {
                ($g, $h, $arr) = siqs_find_first_poly($n, $m, $factor_base);
            }
            else {
                ($g, $h) = siqs_find_next_poly($n, $factor_base, $i_poly, $g, $arr);
            }

            if (++$i_poly >= (1 << $#{$arr})) {
                $i_poly = 0;
            }

            my $sieve_array = siqs_sieve($factor_base, $m);

            $enough_relations =
              siqs_trial_division($n, $sieve_array, $factor_base_info, $smooth_relations, $g, $h, $m, $required_relations);

            if (   scalar(@$smooth_relations) >= $required_relations
                or scalar(@$smooth_relations) > $prev_cnt) {
                printf("Progress: %d/%d relations.\r", scalar(@$smooth_relations), $required_relations);
                $prev_cnt = scalar(@$smooth_relations);
            }
        }

        say "\n\n*** Step 2/2: Linear Algebra ***";
        say "Building matrix for linear algebra step...";

        my $M = siqs_build_matrix($factor_base, $smooth_relations);
        my ($M_opt, $M_n, $M_m) = siqs_build_matrix_opt($M);

        say "Finding perfect squares using Gaussian elimination...";
        my $perfect_squares = siqs_solve_matrix_opt($M_opt, $M_n, $M_m);

        say "Finding factors from congruences of squares...\n";
        @factors = siqs_find_factors($n, $perfect_squares, $smooth_relations);

        if (scalar(@factors) > 1) {
            $success = 1;
        }
        else {
            say "Failed to find a solution. Finding more relations...";
            $required_relations_ratio += 0.05;
        }
    }

    return @factors;
}

sub check_factor ($n, $i, $factors) {

    while ($n % $i == 0) {

        $n /= $i;
        push @$factors, $i;

        if (is_prime($n)) {
            push @$factors, $n;
            return 1;
        }
    }

    return $n;
}

sub trial_division_small_primes ($n) {

    # Perform trial division on the given number n using all primes up
    # to upper_bound. Initialize the global variable small_primes with a
    # list of all primes <= upper_bound. Return (factors, rem), where
    # factors is the list of identified prime factors of n, and rem is the
    # remaining factor. If rem = 1, the function terminates early, without
    # fully initializing small_primes.

    say "[*] Trial division...";

    my $factors = [];
    my $rem     = $n;

    foreach my $p (@small_primes) {
        if (Math::GMPz::Rmpz_divisible_ui_p($rem, $p)) {
            $rem = check_factor($rem, $p, $factors);
            last if ($rem == 1);
        }
    }

    return ($factors, $rem);
}

sub fast_fibonacci_factor ($n, $upto) {

    my $g = Math::GMPz::Rmpz_init();

    foreach my $k (2 .. $upto) {

        my ($U, $V) = lucas_sequence($n, 3, 1, $k);

        foreach my $t ($U, $V, Math::Prime::Util::GMP::subint($V, 1), Math::Prime::Util::GMP::addint($V, 1)) {

            Math::GMPz::Rmpz_set_str($g, $t, 10);
            Math::GMPz::Rmpz_gcd($g, $g, $n);

            if (    Math::GMPz::Rmpz_cmp_ui($g, 1) > 0
                and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                return $g;
            }
        }
    }

    return undef;
}

sub fast_power_check ($n, $upto) {

    state $t = Math::GMPz::Rmpz_init_nobless();
    state $g = Math::GMPz::Rmpz_init_nobless();

    my $base_limit = vecmin(logint($n, 2), 150);

    foreach my $base (2 .. $base_limit) {

        Math::GMPz::Rmpz_set_ui($t, $base);

        foreach my $exp (2 .. $upto) {

            Math::GMPz::Rmpz_mul_ui($t, $t, $base);

            foreach my $k ($base <= 10 ? (1 .. ($base_limit >> 1)) : 1) {
                Math::GMPz::Rmpz_mul_ui($g, $t, $k);

                Math::GMPz::Rmpz_sub_ui($g, $g, 1);
                Math::GMPz::Rmpz_gcd($g, $g, $n);

                if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0 and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                    return Math::GMPz::Rmpz_init_set($g);
                }

                Math::GMPz::Rmpz_mul_ui($g, $t, $k);
                Math::GMPz::Rmpz_add_ui($g, $g, 1);
                Math::GMPz::Rmpz_gcd($g, $g, $n);

                if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0 and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                    return Math::GMPz::Rmpz_init_set($g);
                }
            }
        }
    }

    return undef;
}

sub cyclotomic_polynomial ($n, $x, $m) {

    $n = Math::GMPz::Rmpz_init_set_ui($n) if !ref($n);
    $x = Math::GMPz::Rmpz_init_set_ui($x) if !ref($x);

    # Generate the squarefree divisors of n, along
    # with the number of prime factors of each divisor
    my @sd;
    foreach my $pe (factor_exp($n)) {
        my ($p) = @$pe;

        $p =
          ($p < ULONG_MAX)
          ? Math::GMPz::Rmpz_init_set_ui($p)
          : Math::GMPz::Rmpz_init_set_str("$p", 10);

        push @sd, map { [$_->[0] * $p, $_->[1] + 1] } @sd;
        push @sd, [$p, 1];
    }

    push @sd, [Math::GMPz::Rmpz_init_set_ui(1), 0];

    my $prod = Math::GMPz::Rmpz_init_set_ui(1);

    foreach my $pair (@sd) {
        my ($d, $c) = @$pair;

        my $base = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_divexact($base, $n, $d);
        Math::GMPz::Rmpz_powm($base, $x, $base, $m);    # x^(n/d) mod m
        Math::GMPz::Rmpz_sub_ui($base, $base, 1);

        if ($c % 2 == 1) {
            Math::GMPz::Rmpz_invert($base, $base, $m) || do {
                my $g = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_gcd($g, $base, $m);
                return $g;
            };
        }

        Math::GMPz::Rmpz_mul($prod, $prod, $base);
        Math::GMPz::Rmpz_mod($prod, $prod, $m);
    }

    return $prod;
}

sub cyclotomic_factorization ($n) {

    my $g          = Math::GMPz::Rmpz_init();
    my $base_limit = vecmin(1 + logint($n, 2), 1000);

    for (my $base = $base_limit ; $base >= 2 ; $base -= 1) {
        my $lim = 1 + logint($n, $base);

        foreach my $k (1 .. $lim) {
            my $c = cyclotomic_polynomial($k, $base, $n);
            Math::GMPz::Rmpz_gcd($g, $n, $c);
            if (    Math::GMPz::Rmpz_cmp_ui($g, 1) > 0
                and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                return $g;
            }
        }
    }

    return undef;
}

sub fast_lucasVmod ($P, $n, $m) {    # assumes Q = 1

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $bit (ntheory::todigits($n, 2)) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
        Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

        if ($bit) {
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);
            Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $m);
            Math::GMPz::Rmpz_submul($V1, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
            Math::GMPz::Rmpz_mod($V1, $V1, $m);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
            Math::GMPz::Rmpz_submul($V2, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
            Math::GMPz::Rmpz_mod($V2, $V2, $m);
        }
    }

    Math::GMPz::Rmpz_mod($V1, $V1, $m);

    return $V1;
}

sub chebyshev_factorization ($n, $B, $A = 127) {

    # The Chebyshev factorization method, taking
    # advantage of the smoothness of p-1 or p+1.

    my $x = Math::GMPz::Rmpz_init_set_ui($A);
    my $i = Math::GMPz::Rmpz_init_set_ui(2);

    Math::GMPz::Rmpz_invert($i, $i, $n);

    my sub chebyshevTmod ($A, $x) {
        Math::GMPz::Rmpz_mul_2exp($x, $x, 1);
        Math::GMPz::Rmpz_set($x, fast_lucasVmod($x, $A, $n));
        Math::GMPz::Rmpz_mul($x, $x, $i);
        Math::GMPz::Rmpz_mod($x, $x, $n);
    }

    my $g   = Math::GMPz::Rmpz_init();
    my $lnB = log($B);

    foreach my $p (sieve_primes(2, $B)) {

        chebyshevTmod($p**int($lnB / log($p)), $x);    # T_k(x) (mod n)

        Math::GMPz::Rmpz_sub_ui($g, $x, 1);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            return undef if (Math::GMPz::Rmpz_cmp($g, $n) == 0);
            return $g;
        }
    }

    return undef;
}

sub fibonacci_factorization ($n, $bound) {

    # The Fibonacci factorization method, taking
    # advantage of the smoothness of `p - legendre(p, 5)`.

    my ($P, $Q) = (1, 0);

    for (my $k = 2 ; ; ++$k) {
        my $D = (-1)**$k * (2 * $k + 1);

        if (Math::GMPz::Rmpz_si_kronecker($D, $n) == -1) {
            $Q = (1 - $D) / 4;
            last;
        }
    }

    state %cache;
    my $g = Math::GMPz::Rmpz_init();

    for (; ;) {
        return undef if $bound <= 1;

        my $d = ($cache{$bound} //= consecutive_integer_lcm($bound));
        my ($U, $V) = map { Math::GMPz::Rmpz_init_set_str($_, 10) } lucas_sequence($n, $P, $Q, $d);

        foreach my $t ($U, $V - 2, $V, $V + 2) {

            Math::GMPz::Rmpz_gcd($g, $t, $n);

            if (    Math::GMPz::Rmpz_cmp_ui($g, 1) > 0
                and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                return $g;
            }
        }

        if ($U == 0) {
            say ":: p±1 seems to be $bound-smooth...";
            $bound >>= 1;
            next;
        }

        say "=> Lucas p±1...";
        return lucas_factorization($n, Math::GMPz::Rmpz_init_set_str($d, 10));
    }
}

sub lucas_factorization ($n, $d) {

    # The Lucas factorization method, taking
    # advantage of the smoothness of p-1 or p+1.

    my $Q;
    for (my $k = 2 ; ; ++$k) {
        my $D = (-1)**$k * (2 * $k + 1);

        if (Math::GMPz::Rmpz_si_kronecker($D, $n) == -1) {
            $Q = (1 - $D) / 4;
            last;
        }
    }

    my $s  = Math::GMPz::Rmpz_scan1($d, 0);
    my $U1 = Math::GMPz::Rmpz_init_set_ui(1);

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set_ui(1));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $bit (split(//, substr(Math::GMPz::Rmpz_get_str($d, 2), 0, -$s - 1))) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
        Math::GMPz::Rmpz_mod($Q1, $Q1, $n);

        if ($bit) {
            Math::GMPz::Rmpz_mul_si($Q2, $Q1, $Q);
            Math::GMPz::Rmpz_mul($U1, $U1, $V2);
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);

            Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $n);
            Math::GMPz::Rmpz_sub($V1, $V1, $Q1);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);

            Math::GMPz::Rmpz_mod($V1, $V1, $n);
            Math::GMPz::Rmpz_mod($U1, $U1, $n);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($U1, $U1, $V1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_sub($U1, $U1, $Q1);

            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $n);
            Math::GMPz::Rmpz_sub($V2, $V2, $Q1);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);

            Math::GMPz::Rmpz_mod($V2, $V2, $n);
            Math::GMPz::Rmpz_mod($U1, $U1, $n);
        }
    }

    Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
    Math::GMPz::Rmpz_mul_si($Q2, $Q1, $Q);
    Math::GMPz::Rmpz_mul($U1, $U1, $V1);
    Math::GMPz::Rmpz_mul($V1, $V1, $V2);
    Math::GMPz::Rmpz_sub($U1, $U1, $Q1);
    Math::GMPz::Rmpz_sub($V1, $V1, $Q1);
    Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);

    my $t = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_gcd($t, $U1, $n);

    if (    Math::GMPz::Rmpz_cmp_ui($t, 1) > 0
        and Math::GMPz::Rmpz_cmp($t, $n) < 0) {
        return $t;
    }

    Math::GMPz::Rmpz_gcd($t, $V1, $n);

    if (    Math::GMPz::Rmpz_cmp_ui($t, 1) > 0
        and Math::GMPz::Rmpz_cmp($t, $n) < 0) {
        return $t;
    }

    for (1 .. $s) {

        Math::GMPz::Rmpz_mul($U1, $U1, $V1);
        Math::GMPz::Rmpz_mod($U1, $U1, $n);
        Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $n);
        Math::GMPz::Rmpz_submul_ui($V1, $Q1, 2);
        Math::GMPz::Rmpz_powm_ui($Q1, $Q1, 2, $n);

        Math::GMPz::Rmpz_gcd($t, $U1, $n);

        if (    Math::GMPz::Rmpz_cmp_ui($t, 1) > 0
            and Math::GMPz::Rmpz_cmp($t, $n) < 0) {
            return $t;
        }

        Math::GMPz::Rmpz_gcd($t, $V1, $n);

        if (    Math::GMPz::Rmpz_cmp_ui($t, 1) > 0
            and Math::GMPz::Rmpz_cmp($t, $n) < 0) {
            return $t;
        }
    }

    return undef;
}

sub pollard_pm1_lcm_find_factor ($n, $bound) {

    # Pollard p-1 method (LCM).

    my $g = Math::GMPz::Rmpz_init();
    my $t = Math::GMPz::Rmpz_init_set_ui(random_prime(1e6));

    foreach my $p (sieve_primes(2, $bound)) {

        Math::GMPz::Rmpz_powm_ui($t, $t, $p**int(log(ULONG_MAX >> 32) / log($p)), $n);
        Math::GMPz::Rmpz_sub_ui($g, $t, 1);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            return undef if ($g == $n);
            return $g;
        }
    }

    return undef;
}

sub pollard_pm1_factorial_find_factor ($n, $bound2) {

    # Pollard p-1 method (factorial).

    my $bound1 = 1e5;

    state %cache;

    my $g = Math::GMPz::Rmpz_init();
    my $t = Math::GMPz::Rmpz_init_set_ui(random_prime(1e6));

    if (exists $cache{$n}) {
        $t      = $cache{$n}{value};
        $bound1 = $cache{$n}{bound};
    }
    else {
        foreach my $k (2 .. $bound1) {

            Math::GMPz::Rmpz_powm_ui($t, $t, $k, $n);
            Math::GMPz::Rmpz_sub_ui($g, $t, 1);
            Math::GMPz::Rmpz_gcd($g, $g, $n);

            if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
                return undef if ($g == $n);
                return $g;
            }
        }
    }

    while ($bound1 >= $bound2) {
        $bound2 *= 2;
    }

    foreach my $p (sieve_primes($bound1, $bound2)) {

        Math::GMPz::Rmpz_powm_ui($t, $t, $p, $n);
        Math::GMPz::Rmpz_sub_ui($g, $t, 1);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            return undef if ($g == $n);
            return $g;
        }
    }

    $cache{$n}{value} = $t;
    $cache{$n}{bound} = $bound2 + 1;

    return undef;
}

sub pollard_rho_find_factor ($n, $max_iter) {

    # Pollard rho method, using the polynomial:
    #   f(x) = x^2 - 1, with x_0 = 1+floor(log_2(n)).

    state %cache;

    my $u = logint($n, 2) + 1;
    my $x = Math::GMPz::Rmpz_init_set_ui($u);
    my $y = Math::GMPz::Rmpz_init_set_ui($u * $u - 1);

    if (exists $cache{$n}) {
        $x = $cache{$n}{x};
        $y = $cache{$n}{y};
    }

    my $g = Math::GMPz::Rmpz_init();

    for (1 .. $max_iter) {

        # f(x) = x^2 - 1
        Math::GMPz::Rmpz_powm_ui($x, $x, 2, $n);
        Math::GMPz::Rmpz_sub_ui($x, $x, 1);

        # f(f(x)) = (x^2 - 1)^2 - 1 = (x^2 - 2) * x^2
        Math::GMPz::Rmpz_powm_ui($g, $y, 2, $n);
        Math::GMPz::Rmpz_sub_ui($y, $g, 2);
        Math::GMPz::Rmpz_mul($y, $y, $g);

        Math::GMPz::Rmpz_sub($g, $x, $y);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) != 0) {
            return undef if ($g == $n);
            return $g;
        }
    }

    $cache{$n}{x} = $x;
    $cache{$n}{y} = $y;

    return undef;
}

sub pollard_pm1_ntheory_factor ($n, $max_iter) {
    my ($p, $q) = Math::Prime::Util::GMP::pminus1_factor($n, $max_iter);
    return $p if defined($q);
    return pollard_pm1_factorial_find_factor($n, $max_iter);
}

sub williams_pp1_ntheory_factor ($n, $max_iter) {
    my ($p, $q) = Math::Prime::Util::GMP::pplus1_factor($n, $max_iter);
    return $p if defined($q);
    return undef;
}

sub pollard_rho_ntheory_factor ($n, $max_iter) {
    my ($p, $q) =
        (rand(1) < 0.5)
      ? (Math::Prime::Util::GMP::prho_factor($n, $max_iter))
      : (Math::Prime::Util::GMP::pbrent_factor($n, $max_iter));
    return $p if defined($q);
    return pollard_rho_find_factor($n, $max_iter >> 1);
}

sub pollard_rho_sqrt_find_factor ($n, $max_iter) {

    # Pollard rho method, using the polynomial:
    #   f(x) = x^2 + c
    #
    # where
    #   c = floor(sqrt(n)) - (floor(sqrt(n))^2 - n)
    #   c = n + s - s^2, with s = floor(sqrt(n))
    #
    # and
    #   x_0 = 3^2 + c

    my $s = Math::GMPz->new(sqrtint($n));
    my $c = $n + $s - $s * $s;

    my $a0 = 3;
    my $a1 = ($a0 * $a0 + $c);
    my $a2 = ($a1 * $a1 + $c);

    my $g = Math::GMPz::Rmpz_init();

    for (1 .. $max_iter) {

        Math::GMPz::Rmpz_sub($g, $a2, $a1);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) != 0) {
            return undef if ($g == $n);
            return $g;
        }

        Math::GMPz::Rmpz_powm_ui($a1, $a1, 2, $n);
        Math::GMPz::Rmpz_add($a1, $a1, $c);

        Math::GMPz::Rmpz_powm_ui($a2, $a2, 2, $n);
        Math::GMPz::Rmpz_add($a2, $a2, $c);

        Math::GMPz::Rmpz_powm_ui($a2, $a2, 2, $n);
        Math::GMPz::Rmpz_add($a2, $a2, $c);
    }

    return undef;
}

sub pollard_rho_exp_find_factor ($n, $max_iter) {

    my $B = logint($n, 5)**2;

    if ($B > 50_000) {
        $B = 50_000;
    }

    my $e = Math::GMPz::Rmpz_init_set_str(consecutive_integer_lcm($B), 10);
    my $c = 2 * $e - 1;

    my $x = Math::GMPz::Rmpz_init_set_ui(1);
    my $y = Math::GMPz::Rmpz_init();
    my $g = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_powm($x, $x, $e, $n);
    Math::GMPz::Rmpz_add($x, $x, $c);
    Math::GMPz::Rmpz_mod($x, $x, $n);

    Math::GMPz::Rmpz_powm($y, $x, $e, $n);
    Math::GMPz::Rmpz_add($y, $y, $c);
    Math::GMPz::Rmpz_mod($y, $y, $n);

    for (1 .. $max_iter) {

        Math::GMPz::Rmpz_powm($x, $x, $e, $n);
        Math::GMPz::Rmpz_add($x, $x, $c);
        Math::GMPz::Rmpz_mod($x, $x, $n);

        Math::GMPz::Rmpz_powm($y, $y, $e, $n);
        Math::GMPz::Rmpz_add($y, $y, $c);
        Math::GMPz::Rmpz_mod($y, $y, $n);

        Math::GMPz::Rmpz_powm($y, $y, $e, $n);
        Math::GMPz::Rmpz_add($y, $y, $c);
        Math::GMPz::Rmpz_mod($y, $y, $n);

        Math::GMPz::Rmpz_sub($g, $x, $y);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            return undef if (Math::GMPz::Rmpz_cmp($g, $n) == 0);
            return $g;
        }
    }

    return undef;
}

sub phi_finder_factor ($n, $max_iter) {

    # Phi-finder algorithm for semiprimes, due to Kyle Kloster (2010)

    my $E  = $n - 2 * Math::GMPz->new(sqrtint($n)) + 1;
    my $E0 = Math::GMPz->new(powmod(2, -$E, $n));

    my $L = logint($n, 2);
    my $i = 0;

    while (Math::GMPz::Rmpz_scan1($E0, 0) < Math::GMPz::Rmpz_sizeinbase($E0, 2) - 1) {
        Math::GMPz::Rmpz_mul_2exp($E0, $E0, $L);
        Math::GMPz::Rmpz_mod($E0, $E0, $n);
        ++$i;
        return undef if ($i > $max_iter);
    }

    my $t = 0;

    foreach my $k (0 .. $L) {
        if (Math::GMPz->new(powmod(2, $k, $n)) == $E0) {
            $t = $k;
            last;
        }
    }

    my $phi = abs($i * $L - $E - $t);

    my $q = ($n - $phi + 1);
    my $p = ($q + Math::GMPz->new(sqrtint(abs($q * $q - 4 * $n)))) >> 1;

    (($n % $p) == 0) ? $p : undef;
}

sub FLT_find_factor ($n, $base = 2, $reps = 1e4) {

    # Find a prime factor of n if all the prime factors of n are close to each other.
    # Inpsired by Fermat's little theorem.

    state $z = Math::GMPz::Rmpz_init_nobless();
    state $t = Math::GMPz::Rmpz_init_nobless();

    my $g = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_set_ui($t, $base);
    Math::GMPz::Rmpz_set_ui($z, $base);

    Math::GMPz::Rmpz_powm($z, $z, $n, $n);

    # Cannot factor Fermat pseudoprimes
    if (Math::GMPz::Rmpz_cmp_ui($z, $base) == 0) {
        return undef;
    }

    my $multiplier = $base * $base;

    for (my $k = 1 ; $k <= $reps ; $k += 1) {

        Math::GMPz::Rmpz_mul_ui($t, $t, $multiplier);
        Math::GMPz::Rmpz_mod($t, $t, $n) if ($k % 10 == 0);
        Math::GMPz::Rmpz_sub($g, $z, $t);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            return undef if (Math::GMPz::Rmpz_cmp($g, $n) == 0);
            return $g;
        }
    }

    return undef;
}

{
    state $state = Math::GMPz::zgmp_randinit_mt_nobless();
    Math::GMPz::zgmp_randseed_ui($state, scalar srand());

    sub MBE_find_factor ($n, $max_k = 1000) {

        my $t = Math::GMPz::Rmpz_init();
        my $g = Math::GMPz::Rmpz_init();

        my $a = Math::GMPz::Rmpz_init();
        my $b = Math::GMPz::Rmpz_init();
        my $c = Math::GMPz::Rmpz_init();

        foreach my $k (1 .. $max_k) {

            # Deterministic version
            # Math::GMPz::Rmpz_div_ui($t, $n, $k+1);

            # Randomized version
            Math::GMPz::Rmpz_urandomm($t, $state, $n, 1);

            Math::GMPz::Rmpz_set($a, $t);
            Math::GMPz::Rmpz_set($b, $t);
            Math::GMPz::Rmpz_set_ui($c, 1);

            foreach my $i (0 .. Math::GMPz::Rmpz_sizeinbase($b, 2) - 1) {

                if (Math::GMPz::Rmpz_tstbit($b, $i)) {

                    Math::GMPz::Rmpz_powm($c, $a, $c, $n);
                    Math::GMPz::Rmpz_sub_ui($g, $c, 1);
                    Math::GMPz::Rmpz_gcd($g, $g, $n);

                    if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0 and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                        return $g;
                    }
                }

                Math::GMPz::Rmpz_powm($a, $a, $a, $n);
            }
        }

        return undef;
    }
}

sub fermat_find_factor ($n, $max_iter) {

    # Fermat's factorization method, trying to represent `n` as a difference of two squares:
    #   n = a^2 - b^2, where n = (a-b) * (a+b).

    my $p = Math::GMPz::Rmpz_init();    # p = floor(sqrt(n))
    my $q = Math::GMPz::Rmpz_init();    # q = p^2 - n

    Math::GMPz::Rmpz_sqrtrem($p, $q, $n);
    Math::GMPz::Rmpz_neg($q, $q);

    for (my $j = 1 ; $j <= $max_iter ; ++$j) {

        Math::GMPz::Rmpz_addmul_ui($q, $p, 2);

        Math::GMPz::Rmpz_add_ui($q, $q, 1);
        Math::GMPz::Rmpz_add_ui($p, $p, 1);

        if (Math::GMPz::Rmpz_perfect_square_p($q)) {
            Math::GMPz::Rmpz_sqrt($q, $q);

            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_sub($r, $p, $q);

            return $r;
        }
    }

    return undef;
}

sub holf_ntheory_find_factor ($n, $max_iter) {
    my ($p, $q) = Math::Prime::Util::GMP::holf_factor($n, $max_iter);
    return $p if defined($q);
    return undef;
}

sub holf_find_factor ($n, $max_iter) {

    # Hart’s One-Line Factoring Algorithm

    my $m = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_init();

    foreach my $i (1 .. $max_iter) {

        Math::GMPz::Rmpz_mul_ui($s, $n, 4 * $i);
        Math::GMPz::Rmpz_sqrt($s, $s);
        Math::GMPz::Rmpz_add_ui($s, $s, 1);

        Math::GMPz::Rmpz_mul($m, $s, $s);
        Math::GMPz::Rmpz_mod($m, $m, $n);

        if (Math::GMPz::Rmpz_perfect_square_p($m)) {

            Math::GMPz::Rmpz_sqrt($m, $m);
            Math::GMPz::Rmpz_sub($m, $s, $m);
            Math::GMPz::Rmpz_gcd($m, $m, $n);

            if (    Math::GMPz::Rmpz_cmp_ui($m, 1) > 0
                and Math::GMPz::Rmpz_cmp($m, $n) < 0) {
                return $m;
            }
        }
    }

    return undef;
}

sub miller_rabin_factor ($n, $tries) {

    # Miller-Rabin factorization method.
    # https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test

    my $D = $n - 1;
    my $s = Math::GMPz::Rmpz_scan1($D, 0);
    my $r = $s - 1;
    my $d = $D >> $s;

    if ($s > 20 and $tries > 10) {
        $tries = 1 + int(2 * (100 / $s));
    }

    my $x = Math::GMPz::Rmpz_init();
    my $g = Math::GMPz::Rmpz_init();

    for (1 .. $tries) {

        my $p = random_prime(1e7);
        Math::GMPz::Rmpz_powm($x, Math::GMPz::Rmpz_init_set_ui($p), $d, $n);

        foreach my $k (0 .. $r) {

            last if (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0);
            last if (Math::GMPz::Rmpz_cmp($x, $D) == 0);

            foreach my $i (1, -1) {
                Math::GMPz::Rmpz_gcd($g, $x + $i, $n);
                if (    Math::GMPz::Rmpz_cmp_ui($g, 1) > 0
                    and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                    return $g;
                }
            }

            Math::GMPz::Rmpz_powm_ui($x, $x, 2, $n);
        }
    }

    return undef;
}

sub lucas_miller_factor ($n, $j, $tries) {

    # Lucas-Miller factorization method.

    my $D = $n + $j;
    my $s = Math::GMPz::Rmpz_scan1($D, 0);
    my $r = $s;
    my $d = $D >> $s;

    $d = Math::GMPz::Rmpz_get_str($d, 10);

    if ($s > 10 and $tries > 5) {
        $tries //= 1 + int(100 / $s);
    }

    my $g = Math::GMPz::Rmpz_init();

    foreach my $i (1 .. $tries) {

        my $P = 1 + int(rand(1e6));
        my $Q = 1 + int(rand(1e6));

        $Q *= -1 if (rand(1) < 0.5);

        next if ntheory::is_square($P * $P - 4 * $Q);

        my ($U1, $V1, $Q1) =
          map { Math::GMPz::Rmpz_init_set_str($_, 10) } Math::Prime::Util::GMP::lucas_sequence($n, $P, $Q, $d);

        foreach my $k (1 .. $r) {

            foreach my $t ($U1, $V1, $P) {
                if (ref($t)) {
                    Math::GMPz::Rmpz_gcd($g, $t, $n);
                }
                else {
                    Math::GMPz::Rmpz_sub_ui($g, $V1, $t);
                    Math::GMPz::Rmpz_gcd($g, $g, $n);
                }
                if (    Math::GMPz::Rmpz_cmp_ui($g, 1) > 0
                    and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                    return $g;
                }
            }

            Math::GMPz::Rmpz_mul($U1, $U1, $V1);
            Math::GMPz::Rmpz_mod($U1, $U1, $n);
            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $n);
            Math::GMPz::Rmpz_submul_ui($V1, $Q1, 2);
            Math::GMPz::Rmpz_powm_ui($Q1, $Q1, 2, $n);
        }
    }

    return undef;
}

sub simple_cfrac_find_factor ($n, $max_iter) {

    # Simple version of the continued-fraction factorization method.
    # Efficient for numbers that have factors relatively close to sqrt(n)

    my $x = Math::GMPz::Rmpz_init();
    my $y = Math::GMPz::Rmpz_init();
    my $z = Math::GMPz::Rmpz_init_set_ui(1);

    my $t = Math::GMPz::Rmpz_init();
    my $w = Math::GMPz::Rmpz_init();
    my $r = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_sqrt($x, $n);
    Math::GMPz::Rmpz_set($y, $x);

    Math::GMPz::Rmpz_add($w, $x, $x);
    Math::GMPz::Rmpz_set($r, $w);

    my $f2 = Math::GMPz::Rmpz_init_set($x);
    my $f1 = Math::GMPz::Rmpz_init_set_ui(1);

    foreach (1 .. $max_iter) {

        # y = r*z - y
        Math::GMPz::Rmpz_mul($t, $r, $z);
        Math::GMPz::Rmpz_sub($y, $t, $y);

        # z = (n - y*y) / z
        Math::GMPz::Rmpz_mul($t, $y, $y);
        Math::GMPz::Rmpz_sub($t, $n, $t);
        Math::GMPz::Rmpz_divexact($z, $t, $z);

        # r = (x + y) / z
        Math::GMPz::Rmpz_add($t, $x, $y);
        Math::GMPz::Rmpz_div($r, $t, $z);

        # f1 = (f1 + r*f2) % n
        Math::GMPz::Rmpz_addmul($f1, $f2, $r);
        Math::GMPz::Rmpz_mod($f1, $f1, $n);

        # swap f1 with f2
        ($f1, $f2) = ($f2, $f1);

        if (Math::GMPz::Rmpz_perfect_square_p($z)) {
            my $g = Math::GMPz->new(gcd($f1 - Math::GMPz->new(sqrtint($z)), $n));

            if ($g > 1 and $g < $n) {
                return $g;
            }
        }

        last if ($z == 1);
    }

    return undef;
}

sub store_factor ($rem, $f, $factors) {

    $f || return;

    if (ref($f) ne 'Math::GMPz') {
        $f =~ /^[0-9]+\z/ or return;
        $f = Math::GMPz->new($f);
    }

    $f < $$rem or return;

    $$rem % $f == 0 or die 'error';

    if (is_prime($f)) {
        say("`-> prime factor: ", $f);
        $$rem = check_factor($$rem, $f, $factors);
    }
    else {
        say("`-> composite factor: ", $f);

        $$rem /= $f;

        # Try to find a small factor of f
        my $f_factor = find_small_factors($f, $factors);

        if ($f_factor < $f) {
            $$rem *= $f_factor;
        }
        else {

            # Use SIQS to factorize f
            find_prime_factors($f, $factors);

            foreach my $p (@$factors) {
                if ($$rem % $p == 0) {
                    $$rem = check_factor($$rem, $p, $factors);
                    last if $$rem == 1;
                }
            }
        }
    }

    return 1;
}

sub find_small_factors ($rem, $factors) {

    # Some special-purpose factorization methods to attempt to find small prime factors.
    # Collect the identified prime factors in the `$factors` array and return 1 if all
    # prime factors were found, or otherwise the remaining factor.

    my %state = (
                 cyclotomic_check     => 1,
                 fast_power_check     => 1,
                 fast_fibonacci_check => 1,
                );

    my $len = length($rem);

    my @factorization_methods = (
        sub {
            say "=> Miller-Rabin method...";
            miller_rabin_factor($rem, ($len > 1000) ? 15 : MILLER_RABIN_ITERATIONS);
        },

        sub {
            if ($len < 3000) {
                say "=> Lucas-Miller method (n+1)...";
                lucas_miller_factor($rem, +1, ($len > 1000) ? 10 : LUCAS_MILLER_ITERATIONS);
            }
        },

        sub {
            if ($len < 3000) {
                say "=> Lucas-Miller method (n-1)...";
                lucas_miller_factor($rem, -1, ($len > 1000) ? 10 : LUCAS_MILLER_ITERATIONS);
            }
        },

        sub {
            say "=> Phi finder method...";
            phi_finder_factor($rem, PHI_FINDER_ITERATIONS);
        },

        sub {
            say "=> Fermat's method...";
            fermat_find_factor($rem, FERMAT_ITERATIONS);
        },

        sub {
            say "=> HOLF method...";
            holf_find_factor($rem, HOLF_ITERATIONS);
        },

        sub {
            say "=> HOLF method (ntheory)...";
            holf_ntheory_find_factor($rem, 2 * HOLF_ITERATIONS);
        },

        sub {
            say "=> CFRAC simple...";
            simple_cfrac_find_factor($rem, CFRAC_ITERATIONS);
        },

        sub {
            say "=> Fermat's little theorem (base 2)...";
            FLT_find_factor($rem, 2, ($len > 1000) ? 1e4 : ORDER_ITERATIONS);
        },

        sub {
            my $len_2 = $len * (log(10) / log(2));
            my $iter  = ($len_2 * MBE_ITERATIONS > 1_000) ? int(1_000 / $len_2) : MBE_ITERATIONS;
            if ($iter > 0) {
                say "=> MBE method ($iter iter)...";
                MBE_find_factor($rem, $iter);
            }
        },

        sub {
            say "=> Fermat's little theorem (base 3)...";
            FLT_find_factor($rem, 3, ($len > 1000) ? 1e4 : ORDER_ITERATIONS);
        },

        sub {
            $state{fast_fibonacci_check} || return undef;
            say "=> Fast Fibonacci check...";
            my $f = fast_fibonacci_factor($rem, 5000);
            $f // do { $state{fast_fibonacci_check} = 0 };
            $f;
        },

        sub {
            $state{cyclotomic_check} || return undef;
            say "=> Fast cyclotomic check...";
            my $f = cyclotomic_factorization($rem);
            $f // do { $state{cyclotomic_check} = 0 };
            $f;
        },

        sub {
            say "=> Pollard rho (10M)...";
            pollard_rho_ntheory_factor($rem, int sqrt(1e10));
        },

        sub {
            say "=> Pollard p-1 (500K)...";
            pollard_pm1_ntheory_factor($rem, 500_000);
        },

        sub {
            say "=> Williams p±1 (500K)...";
            williams_pp1_ntheory_factor($rem, 500_000);
        },

        sub {
            if ($len < 1000) {
                say "=> Chebyshev p±1 (500K)...";
                chebyshev_factorization($rem, 500_000, int(rand(1e6)) + 2);
            }
        },

        sub {
            say "=> Williams p±1 (1M)...";
            williams_pp1_ntheory_factor($rem, 1_000_000);
        },

        sub {
            if ($len < 1000) {
                say "=> Chebyshev p±1 (1M)...";
                chebyshev_factorization($rem, 1_000_000, int(rand(1e6)) + 2);
            }
        },

        sub {
            $state{fast_power_check} || return undef;
            say "=> Fast power check...";
            my $f = fast_power_check($rem, 500);
            $f // do { $state{fast_power_check} = 0 };
            $f;
        },

        sub {
            if ($len < 500) {
                say "=> Fibonacci p±1 (500K)...";
                fibonacci_factorization($rem, 500_000);
            }
        },

        sub {
            say "=> Pollard rho (12M)...";
            pollard_rho_ntheory_factor($rem, int sqrt(1e12));
        },

        sub {
            say "=> Pollard p-1 (5M)...";
            pollard_pm1_factorial_find_factor($rem, 5_000_000);
        },

        sub {
            say "=> Williams p±1 (3M)...";
            williams_pp1_ntheory_factor($rem, 3_000_000);
        },

        sub {
            say "=> Pollard rho (13M)...";
            pollard_rho_ntheory_factor($rem, int sqrt(1e13));
        },

        sub {
            say "=> Williams p±1 (5M)...";
            williams_pp1_ntheory_factor($rem, 5_000_000);
        },

        sub {
            if ($len > 40) {
                say "=> Pollard rho (14M)...";
                pollard_rho_ntheory_factor($rem, int sqrt(1e14));
            }
        },

        sub {
            say "=> Pollard p-1 (8M)...";
            pollard_pm1_ntheory_factor($rem, 8_000_000);
        },

        sub {
            if ($len < 150) {
                say "=> Pollard rho-exp...";
                pollard_rho_exp_find_factor($rem, ($len > 50 ? 2 : 1) * 200);
            }
        },

        sub {
            if ($len > 50) {
                say "=> Pollard p-1 (10M)...";
                pollard_pm1_factorial_find_factor($rem, 10_000_000);
            }
        },

        sub {
            if ($len > 50) {
                say "=> Williams p±1 (10M)...";
                williams_pp1_ntheory_factor($rem, 10_000_000);
            }
        },

        sub {
            if ($len > 70) {
                say "=> Pollard rho (15M)...";
                pollard_rho_ntheory_factor($rem, int sqrt(1e15));
            }
        },

        sub {
            if ($len > 70) {
                say "=> Pollard p-1 (20M)...";
                pollard_pm1_factorial_find_factor($rem, 20_000_000);
            }
        },

        sub {
            if ($len > 70) {
                say "=> Williams p±1 (20M)...";
                williams_pp1_ntheory_factor($rem, 20_000_000);
            }
        },

        sub {
            if ($len > 70) {
                say "=> Pollard rho-exp...";
                pollard_rho_exp_find_factor($rem, 1000);
            }
        },

        sub {
            if ($len > 70) {
                say "=> Pollard rho (16M)...";
                pollard_rho_ntheory_factor($rem, int sqrt(1e16));
            }
        },

        sub {
            if ($len > 70) {
                say "=> Pollard p-1 (50M)...";
                pollard_pm1_factorial_find_factor($rem, 50_000_000);
            }
        },

        sub {
            if ($len > 70) {
                say "=> Pollard p+1 (50M)...";
                williams_pp1_ntheory_factor($rem, 50_000_000);
            }
        },

        sub {
            if ($len > 70) {
                say "=> Pollard rho (16M)...";
                pollard_rho_ntheory_factor($rem, int sqrt(1e16));
            }
        },
    );

  MAIN_LOOP: for (; ;) {

        if ($rem <= 1) {
            last;
        }

        if (is_prime($rem)) {
            push @$factors, $rem;
            $rem = 1;
            last;
        }

        $len = length($rem);

        if ($len >= 25 and $len <= 35) {    # factorize with SIQS directly
            return $rem;
        }

        printf("\n[*] Factoring %s (%s digits)...\n\n", ($len > MASK_LIMIT ? "C$len" : $rem), $len);

        say "=> Perfect power check...";

        if (defined(my $f = check_perfect_power($rem))) {
            my $exp = 1;

            for (my $t = $f ; $t < $rem ; ++$exp) {
                $t *= $f;
            }

            my @r = (is_prime($f) ? $f : factorize($f));
            push(@$factors, (@r) x $exp);
            return 1;
        }

        foreach my $i (0 .. $#factorization_methods) {

            my $code = $factorization_methods[$i];
            my $f    = $code->();

            if (store_factor(\$rem, $f, $factors)) {

                # Move the successful factorization method at the top
                unshift(@factorization_methods, splice(@factorization_methods, $i, 1));

                next MAIN_LOOP;
            }
        }

        last;
    }

    return $rem;
}

sub check_perfect_power ($n) {

    # Check whether n is a perfect and return its perfect root.
    # Returns undef otherwise.

    if ((my $exp = is_power($n)) > 1) {
        my $root = Math::GMPz->new(rootint($n, $exp));
        say "`-> perfect power: $root^$exp";
        return $root;
    }

    return undef;
}

sub find_prime_factors ($n, $factors) {

    # Return one or more prime factors of the given number n. Assume
    # that n is not a prime and does not have very small factors.

    my %factors;

    if (defined(my $root = check_perfect_power($n))) {
        $factors{$root} = $root;
    }
    else {
        my $digits = length($n);

        say("\n[*] Using SIQS to factorize" . " $n ($digits digits)...\n");

        my $nf = siqs_choose_nf($n);
        my @sf = siqs_factorize($n, $nf);

        @factors{@sf} = @sf;
    }

    foreach my $f (values %factors) {
        find_all_prime_factors($f, $factors);
    }
}

sub find_all_prime_factors ($n, $factors) {

    # Return all prime factors of the given number n.
    # Assume that n does not have very small factors.

    if (!ref($n)) {
        $n = Math::GMPz->new($n);
    }

    my $rem = $n;

    while ($rem > 1) {

        if (is_prime($rem)) {
            push @$factors, $rem;
            last;
        }

        my @new_factors;
        find_prime_factors($rem, \@new_factors);

        foreach my $f (@new_factors) {

            $rem != $f     or die 'error';
            $rem % $f == 0 or die 'error';
            is_prime($f)   or die 'error';

            $rem = check_factor($rem, $f, $factors);

            last if ($rem == 1);
        }
    }
}

sub special_form_factorization ($n) {

    my %seen_divisor;
    my @near_power_params;
    my @diff_powers_params;
    my @cong_powers_params;
    my @sophie_params;

    #
    ## Close to a perfect power
    #

    my $near_power = sub ($r, $e, $k) {
        my @factors;

        foreach my $d (ntheory::divisors($e)) {
            my $x = $r**$d;
            foreach my $j (1, -1) {

                my $t = $x - $k * $j;
                my $g = Math::GMPz->new(gcd($t, $n));

                if ($g > TRIAL_DIVISION_LIMIT and $g < $n and !$seen_divisor{$g}++) {
                    push @factors, $g;
                }
            }
        }

        @factors;
    };

    foreach my $j (1 .. NEAR_POWER_ITERATIONS) {
        foreach my $k (1, -1) {
            my $u = $k * $j * $j;

            if ($n + $u > 0) {
                if (my $e = is_power($n + $u)) {
                    my $r = Math::GMPz->new(rootint($n + $u, $e));
                    say "[*] Near power detected: $r^$e ", sprintf("%s %s", ($k == 1) ? ('-', $u) : ('+', -$u));
                    push @near_power_params, [$r, $e, $j];
                }
            }
        }
    }

    #
    ## Difference of powers
    #

    my $diff_powers = sub ($r1, $e1, $r2, $e2) {
        my @factors;

        my @d1 = ntheory::divisors($e1);
        my @d2 = ntheory::divisors($e2);

        foreach my $d1 (@d1) {
            my $x = $r1**$d1;
            foreach my $d2 (@d2) {
                my $y = $r2**$d2;
                foreach my $j (1, -1) {

                    my $t = $x - $j * $y;
                    my $g = Math::GMPz->new(gcd($t, $n));

                    if ($g > TRIAL_DIVISION_LIMIT and $g < $n and !$seen_divisor{$g}++) {
                        push @factors, $g;
                    }
                }
            }
        }

        @factors;
    };

    my $diff_power_check = sub ($r1, $e1) {

        my $u  = $r1**$e1;
        my $dx = abs($u - $n);

        if (Math::GMPz::Rmpz_perfect_power_p($dx)) {

            my $e2 = is_power($dx) || 1;
            my $r2 = Math::GMPz->new(rootint($dx, $e2));

            if ($u > $n) {
                say "[*] Difference of powers detected: ", sprintf("%s^%s - %s^%s", $r1, $e1, $r2, $e2);
            }
            else {
                say "[*] Sum of powers detected: ", sprintf("%s^%s + %s^%s", $r1, $e1, $r2, $e2);

                # Sophie Germain's identity:
                #   n^4 + 4^(2k+1) = n^4 + 4*(4^(2k)) = n^4 + 4*((2^k)^4)

                if ($r1 == 4 and ($e1 % 2 == 1) and $e2 == 4) {    # n = r1^(2k+1) + r2^4
                    push @sophie_params, [$r2, Math::GMPz->new(rootint($r1**($e1 - 1), 4))];
                }

                if ($r2 == 4 and ($e2 % 2 == 1) and $e1 == 4) {    # n = r2^(2k+1) + r1^4
                    push @sophie_params, [$r1, Math::GMPz->new(rootint($r2**($e2 - 1), 4))];
                }
            }

            push @diff_powers_params, [$r1, $e1, $r2, $e2];
        }
    };

    # Sum and difference of powers of the form a^k ± b^k, where a and b are small.
    foreach my $r1 (reverse 2 .. logint($n, 2)) {

        my $t = logint($n, $r1);

        $diff_power_check->(Math::GMPz->new($r1), $t);        # sum of powers
        $diff_power_check->(Math::GMPz->new($r1), $t + 1);    # difference of powers
    }

    # Sum and difference of powers of the form a^k ± b^k, where a and b are large.
    foreach my $e1 (reverse 2 .. logint($n, 2)) {

        my $t = Math::GMPz->new(rootint($n, $e1));

        $diff_power_check->($t,     $e1);                     # sum of powers
        $diff_power_check->($t + 1, $e1);                     # difference of powers
    }

    #
    ## Congruence of powers
    #

    my $cong_powers = sub ($r, $e1, $k, $e2) {

        my @factors;

        my @divs1 = ntheory::divisors($e1);
        my @divs2 = ntheory::divisors($e2);

        foreach my $d1 (@divs1) {
            my $x = $r**$d1;
            foreach my $d2 (@divs2) {
                my $y = $k**$d2;
                foreach my $j (-1, 1) {

                    my $t = $x - $j * $y;
                    my $g = Math::GMPz->new(gcd($t, $n));

                    if ($g > TRIAL_DIVISION_LIMIT and $g < $n and !$seen_divisor{$g}++) {

                        if ($r == $k) {
                            say "[*] Congruence of powers: a^$d1 == b^$d2 (mod n) -> $g";
                        }
                        else {
                            say "[*] Congruence of powers: $r^$d1 == $k^$d2 (mod n) -> $g";
                        }

                        push @factors, $g;
                    }
                }
            }
        }

        @factors;
    };

    my @congrunce_range = reverse(2 .. 64);

    my $process_congruence = sub ($root, $e) {

        for my $j (1, 0) {

            my $k = $root + $j;
            my $u = Math::GMPz::Rmpz_init();

            ref($k)
              ? Math::GMPz::Rmpz_set($u, $k)
              : Math::GMPz::Rmpz_set_ui($u, $k);

            Math::GMPz::Rmpz_powm_ui($u, $u, $e, $n);

            foreach my $z ($u, $n - $u) {
                if (Math::GMPz::Rmpz_perfect_power_p($z)) {
                    my $t = is_power($z) || 1;

                    my $r1 = rootint($z, $t);
                    my $r2 = rootint($z, $e);

                    push @cong_powers_params, [Math::GMPz->new($r1), $t, Math::GMPz->new($k), $e];
                    push @cong_powers_params, [Math::GMPz->new($r2), $e, Math::GMPz->new($k), $e];
                }
            }
        }
    };

    for my $e (@congrunce_range) {
        my $root = Math::GMPz->new(rootint($n, $e));
        $process_congruence->($root, $e);
    }

    for my $root (@congrunce_range) {
        my $e = Math::GMPz->new(logint($n, $root));
        $process_congruence->($root, $e);
    }

    # Sophie Germain's identity
    # x^4 + 4y^4 = (x^2 + 2xy + 2y^2) * (x^2 - 2xy + 2y^2)
    my $sophie = sub ($A, $B) {
        my @factors;

        foreach my $f (
#<<<
            $A*$A + (($B*$B)<<1) - (($A*$B<<1)),
            $A*$A + (($B*$B)<<1) + (($A*$B)<<1),
#>>>
          ) {
            my $g = Math::GMPz->new(gcd($f, $n));

            if ($g > TRIAL_DIVISION_LIMIT and $g < $n and !$seen_divisor{$g}++) {
                push @factors, $g;
            }
        }

        @factors;
    };

    my $sophie_check_root = sub ($r1) {
        {
            my $x  = 4 * $r1**4;
            my $dx = $n - $x;

            if (is_power($dx, 4)) {
                my $r2 = Math::GMPz->new(rootint($dx, 4));
                say "[*] Sophie Germain special form detected: $r2^4 + 4*$r1^4";
                push @sophie_params, [$r2, $r1];
            }

        }

        {
            my $y  = $r1**4;
            my $dy = $n - $y;

            if (($dy % 4 == 0) and is_power($dy >> 2, 4)) {
                my $r2 = Math::GMPz->new(rootint($dy >> 2, 4));
                say "[*] Sophie Germain special form detected: $r1^4 + 4*$r2^4";
                push @sophie_params, [$r1, $r2];
            }
        }
    };

    # Try to find n = x^4 + 4*y^4, for x or y small.
    foreach my $r1 (map { Math::GMPz->new($_) } 2 .. logint($n, 2)) {
        $sophie_check_root->($r1);
    }

    {    # Try to find n = x^4 + 4*y^4 for x and y close to floor(n/5)^(1/4).
        my $k = Math::GMPz->new(rootint($n / 5, 4));

        for my $j (0 .. 1000) {
            $sophie_check_root->($k + $j);
        }
    }

    my @divisors;

    foreach my $args (@near_power_params) {
        push @divisors, $near_power->(@$args);
    }

    foreach my $args (@diff_powers_params) {
        push @divisors, $diff_powers->(@$args);
    }

    foreach my $args (@cong_powers_params) {
        push @divisors, $cong_powers->(@$args);
    }

    foreach my $args (@sophie_params) {
        push @divisors, $sophie->(@$args);
    }

    @divisors = sort { $a <=> $b } @divisors;

    my @factors;
    foreach my $d (@divisors) {
        my $g = Math::GMPz->new(gcd($n, $d));

        if ($g > TRIAL_DIVISION_LIMIT and $g < $n) {
            while ($n % $g == 0) {
                $n /= $g;
                push @factors, $g;
            }
        }
    }

    return sort { $a <=> $b } @factors;
}

sub verify_prime_factors ($n, $factors) {

    Math::GMPz->new(vecprod(@$factors)) == $n or die 'product of factors != n';

    foreach my $p (@$factors) {
        is_prime($p) or die "not prime detected: $p";
    }

    sort { $a <=> $b } @$factors;
}

sub fast_trial_factor ($n, $L = 1e5, $R = 1e6) {

    my @factors;
    my @P = sieve_primes(2, $L);

    my $g = Math::GMPz::Rmpz_init();
    my $t = Math::GMPz::Rmpz_init();

    while (1) {

        # say "L = $L with $#P";

        Math::GMPz::Rmpz_set_str($g, vecprod(@P), 10);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        # Early stop when n seems to no longer have small factors
        if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
            last;
        }

        # Factorize n over primes in P
        foreach my $p (@P) {
            if (Math::GMPz::Rmpz_divisible_ui_p($g, $p)) {

                Math::GMPz::Rmpz_set_ui($t, $p);
                my $valuation = Math::GMPz::Rmpz_remove($n, $n, $t);
                push @factors, ($p) x $valuation;

                # Stop the loop early when no more primes divide `u` (optional)
                Math::GMPz::Rmpz_divexact_ui($g, $g, $p);
                last if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0);
            }
        }

        # Early stop when n has been fully factored
        if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0) {
            last;
        }

        # Early stop when the trial range has been exhausted
        if ($L > $R) {
            last;
        }

        @P = sieve_primes($L + 1, $L << 1);
        $L <<= 1;
    }

    return @factors;
}

sub factorize ($n) {

    # Factorize the given integer n >= 1 into its prime factors.

    my $orig = Math::GMPz::Rmpz_init_set($n);

    if ($n < 1) {
        die "Number needs to be an integer >= 1";
    }

    my $len = length($n);
    printf("\n[*] Factoring %s (%d digits)...\n", ($len > MASK_LIMIT ? "C$len" : $n), $len);

    return ()   if ($n <= 1);
    return ($n) if is_prime($n);

    if (my $e = is_power($n)) {
        my $root = Math::GMPz->new(rootint($n, $e));
        say "[*] Perfect power detected: $root^$e";
        my @factors = (is_prime($root) ? $root : factorize($root));
        return verify_prime_factors($n, [(@factors) x $e]);
    }

    my @divisors;

    push @divisors, (($n > ~0) ? special_form_factorization($n) : ());

    if (!@divisors) {
        push @divisors, fast_trial_factor($n);
    }

    if (@divisors) {

        say "[*] Divisors found so far: ", join(', ', sort { $a <=> $b } @divisors);

        my @composite;
        my @factors;

        foreach my $d (@divisors) {
            $d > 1 or next;
            if (is_prime($d)) {
                push @factors, $d;
            }
            else {
                push @composite, $d;
            }
        }

        push @factors, map { factorize($_) } reverse @composite;
        my $rem = $orig / Math::GMPz->new(vecprod(@factors));

        if ($rem > 1) {
            push @factors, factorize($rem);
        }

        return verify_prime_factors($orig, \@factors);
    }

    my ($factors, $rem) = trial_division_small_primes($n);

    if (@$factors) {
        say "[*] Prime factors found so far: ", join(', ', @$factors);
    }
    else {
        say "[*] No small factors found...";
    }

    if ($rem != 1) {

        if (LOOK_FOR_SMALL_FACTORS) {
            say "[*] Trying to find more small factors...";
            $rem = find_small_factors($rem, $factors);
        }
        else {
            say "[*] Skipping the search for more small factors...";
        }

        if ($rem > 1) {
            find_all_prime_factors($rem, $factors);
        }
    }

    return verify_prime_factors($orig, $factors);
}

if (@ARGV) {
    my $n = eval { Math::GMPz->new($ARGV[0]) };

    if ($@) {    # evaluate the expression using PARI/GP
        chomp(my $str = `echo \Q$ARGV[0]\E | gp -q -f`);
        $n = Math::GMPz->new($str);
    }

    say "\nPrime factors: ", join(', ', factorize($n));
}
else {
    die "Usage: $0 <N>\n";
}
