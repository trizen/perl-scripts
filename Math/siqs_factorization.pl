#!/usr/bin/perl

=begin

This script factorizes a natural number given as a command line
parameter into its prime factors. It first attempts to use trial
division to find very small factors, then uses Brent's version of the
Pollard rho algorithm [1] to find slightly larger factors. If any large
factors remain, it uses the Self-Initializing Quadratic Sieve (SIQS) [2]
to factorize those.

[1] Brent, Richard P. 'An improved Monte Carlo factorization algorithm.'
    BIT Numerical Mathematics 20.2 (1980): 176-184.

[2] Contini, Scott Patrick. 'Factoring integers with the self-
    initializing quadratic sieve.' (1997).

=cut

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

use ntheory qw(
  sqrtmod invmod is_prime factor_exp vecmin urandomm
  valuation logint is_power fromdigits is_square
  );

use Math::Prime::Util::GMP qw(vecprod sqrtint rootint gcd random_prime sieve_primes consecutive_integer_lcm lucas_sequence);

my $ZERO = Math::GMPz->new(0);
my $ONE  = Math::GMPz->new(1);

local $| = 1;

# Tuning parameters
use constant {
              MASK_LIMIT                => 200,         # show Cn if n > MASK_LIMIT, where n ~ log_10(N)
              LOOK_FOR_SMALL_FACTORS    => 1,
              FIBONACCI_BOUND           => 500_000,
              TRIAL_DIVISION_LIMIT      => 1_000_000,
              POLLARD_BRENT_ITERATIONS  => 16,
              POLLARD_RHO_ITERATIONS    => 50_000,
              FERMAT_ITERATIONS         => 500,
              NEAR_POWER_ITERATIONS     => 1_000,
              CFRAC_ITERATIONS          => 15_000,
              HOLF_ITERATIONS           => 15_000,
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
            $A *= $fb->{p};
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

        Math::GMPz::Rmpz_gcd($g, $t, $factor_prod);
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

sub siqs_build_matrix_opt($M) {

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

    return ([map { Math::GMPz->new(fromdigits(scalar reverse($_), 2)) } @cols_binary], scalar(@$M), $m);
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

sub siqs_find_more_factors_gcd(@numbers) {
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

sub siqs_choose_nf($n) {

    # Choose parameters nf (sieve of factor base)

    $n = "$n";

    return sprintf('%.0f', exp(sqrt(log($n) * log(log($n))))**(sqrt(2) / 4));
}

sub siqs_choose_nf2($n) {

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

        say "Finding factors from perfect squares...\n";
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

sub pollard_brent_f ($c, $n, $x) {

    # Return f(x) = (x^2 + c)%n. Assume c < n.

    my $x1 = ($x * $x) % $n + $c;

    if ($x1 >= $n) {
        $x1 -= $n;
    }

    # (($x1 >= 0) && ($x1 < $n)) or die 'error';

    return $x1;
}

sub pollard_brent_find_factor ($n, $max_iter) {

    # Perform Brent's variant of the Pollard rho factorization
    # algorithm to attempt to a non-trivial factor of the given number n.
    # If max_iter > 0, return undef if no factors were found within
    # max_iter iterations.

    my ($y, $c, $m) = (map { 1 + urandomm($n - 1) } 1 .. 3);
    my ($r, $q, $g) = (1, 1, 1);

    my $i = 0;
    my ($x, $ys);

    while ($g eq '1') {
        $x = $y;

        for (1 .. $r) {
            $y = pollard_brent_f($c, $n, $y);
        }

        my $k = 0;

        while ($k < $r and $g eq '1') {
            $ys = $y;

            for (1 .. vecmin($m, $r - $k)) {
                $y = pollard_brent_f($c, $n, $y);
                $q = ($q * abs($x - $y)) % $n;
            }

            $g = gcd($q, $n);
            $k += $m;
        }

        $r <<= 1;

        if (++$i >= $max_iter) {
            return undef;
        }
    }

    $g = Math::GMPz->new($g);

    if ($g == $n) {
        for (; ;) {
            $ys = pollard_brent_f($c, $n, $ys);
            $g  = gcd($x - $ys, $n);

            if ($g ne '1') {
                $g = Math::GMPz->new($g);
                return undef if ($g == $n);
                return $g;
            }
        }
    }

    return $g;
}

sub fast_fibonacci_factor ($n, $upto) {

    foreach my $k (2 .. $upto) {
        foreach my $P (3, 4) {

            my ($U, $V) = map { Math::GMPz::Rmpz_init_set_str($_, 10) } lucas_sequence($n, $P, 1, $k);

            foreach my $f (sub { gcd($U, $n) }, sub { gcd($V - 2, $n) }, sub { gcd($V, $n) }) {
                my $g = Math::GMPz->new($f->());
                return $g if ($g > 1 and $g < $n);
            }
        }
    }

    return undef;
}

sub fibonacci_factorization ($n, $upper_bound) {

    # The Fibonacci factorization method, taking
    # advantage of the smoothness of `p - legendre(p, 5)`.

    my $bound = 5 * logint($n, 2)**2;

    if ($bound > $upper_bound) {
        $bound = $upper_bound;
    }

    my ($P, $Q) = (1, 0);

    for (my $k = 2 ; ; ++$k) {
        my $D = (-1)**$k * (2 * $k + 1);

        if (Math::GMPz::Rmpz_si_kronecker($D, $n) == -1) {
            $Q = (1 - $D) / 4;
            last;
        }
    }

    for (; ;) {
        return undef if $bound <= 1;

        my $d = consecutive_integer_lcm($bound);
        my ($U, $V) = map { Math::GMPz::Rmpz_init_set_str($_, 10) } lucas_sequence($n, $P, $Q, $d);

        foreach my $f (sub { gcd($U, $n) }, sub { gcd($V - 2, $n) }, sub { gcd($V, $n) }) {
            my $g = Math::GMPz->new($f->());
            return $g if ($g > 1 and $g < $n);
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

    Math::GMPz::Rmpz_sub_ui($t, $V1, 2);
    Math::GMPz::Rmpz_gcd($t, $t, $n);

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

        Math::GMPz::Rmpz_sub_ui($t, $V1, 2);
        Math::GMPz::Rmpz_gcd($t, $t, $n);

        if (    Math::GMPz::Rmpz_cmp_ui($t, 1) > 0
            and Math::GMPz::Rmpz_cmp($t, $n) < 0) {
            return $t;
        }
    }

    return undef;
}

sub pollard_pm1_find_factor ($n, $bound) {

    my $g = Math::GMPz::Rmpz_init();
    my $t = Math::GMPz::Rmpz_init_set_ui(random_prime(1e6));

    foreach my $p (sieve_primes(2, $bound)) {

        Math::GMPz::Rmpz_powm_ui($t, $t, $p * $p * (logint($bound, $p) + 1), $n);

        Math::GMPz::Rmpz_sub_ui($g, $t, 1);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {

            if ($g == $n) {
                return undef;
            }

            return $g;
        }
    }

    return undef;
}

sub pollard_rho_find_factor ($n, $max_iter) {

    my $x = Math::GMPz->new(2);
    my $y = Math::GMPz->new(3);

    my $g = Math::GMPz::Rmpz_init();

    for (1 .. $max_iter) {

        Math::GMPz::Rmpz_mul($x, $x, $x);
        Math::GMPz::Rmpz_sub_ui($x, $x, 1);
        Math::GMPz::Rmpz_mod($x, $x, $n);

        Math::GMPz::Rmpz_mul($y, $y, $y);
        Math::GMPz::Rmpz_sub_ui($y, $y, 1);
        Math::GMPz::Rmpz_powm_ui($y, $y, 2, $n);
        Math::GMPz::Rmpz_sub_ui($y, $y, 1);

        Math::GMPz::Rmpz_sub($g, $x, $y);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) != 0) {
            return undef if ($g == $n);
            return $g;
        }
    }

    return undef;
}

sub pollard_rho_sqrt_find_factor ($n, $max_iter) {

    my $p = Math::GMPz->new(sqrtint($n));
    my $q = ($p * $p - $n);

    my $c = $q + $p;

    my $a0 = 1;
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

        Math::GMPz::Rmpz_mul($a1, $a1, $a1);
        Math::GMPz::Rmpz_add($a1, $a1, $c);
        Math::GMPz::Rmpz_mod($a1, $a1, $n);

        Math::GMPz::Rmpz_mul($a2, $a2, $a2);
        Math::GMPz::Rmpz_add($a2, $a2, $c);
        Math::GMPz::Rmpz_mod($a2, $a2, $n);

        Math::GMPz::Rmpz_mul($a2, $a2, $a2);
        Math::GMPz::Rmpz_add($a2, $a2, $c);
        Math::GMPz::Rmpz_mod($a2, $a2, $n);
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

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) != 0) {
            return undef if ($g == $n);
            return $g;
        }
    }

    return undef;
}

sub fermat_find_factor ($n, $max_iter) {

    my $p = Math::GMPz->new(sqrtint($n));
    my $q = $p * $p - $n;

    foreach my $i (1 .. $max_iter) {

        $q += 2 * $p++ + 1;

        if (is_square($q)) {
            return ($p - Math::GMPz->new(sqrtint($q)));
        }
    }

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
}

sub find_small_factors ($rem, $factors) {

    # Perform up to max_iter iterations of Brent's variant of the
    # Pollard rho factorization algorithm to attempt to find small
    # prime factors. Restart the algorithm each time a factor was found.
    # Add all identified prime factors to factors, and return 1 if all
    # prime factors were found, or otherwise the remaining factor.

    my $f;

    for (; ;) {

        if ($rem <= 1) {
            last;
        }

        if (is_prime($rem)) {
            push @$factors, $rem;
            $rem = 1;
            last;
        }

        my $len = length($rem);
        printf("\n[*] Factoring %s (%s digits)...\n\n", ($len > MASK_LIMIT ? "C$len" : $rem), $len);

        say "=> Perfect power check...";
        $f = check_perfect_power($rem);

        if (defined($f)) {
            my $exp = 1;

            for (my $t = $f ; $t < $rem ; ++$exp) {
                $t *= $f;
            }

            my @r = factorize($f);
            push(@$factors, (@r) x $exp);
            return 1;
        }

        say "=> Fermat's method...";
        $f = fermat_find_factor($rem, FERMAT_ITERATIONS);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        say "=> HOLF method...";
        $f = holf_find_factor($rem, HOLF_ITERATIONS);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        say "=> Fast Fibonacci check...";
        $f = fast_fibonacci_factor($rem, 5000);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        say "=> CFRAC simple...";
        $f = simple_cfrac_find_factor($rem, ($len > 50 ? 2 : 1) * CFRAC_ITERATIONS);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        say "=> Pollard rho-sqrt...";
        $f = pollard_rho_sqrt_find_factor($rem, ($len > 50 ? 2 : 1) * POLLARD_RHO_ITERATIONS);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        say "=> Pollard p-1 (500K)...";
        $f = pollard_pm1_find_factor($rem, 500_000);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        say "=> Fibonacci p±1...";
        $f = fibonacci_factorization($rem, FIBONACCI_BOUND);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        say "=> Pollard p-1 (2M)...";
        $f = pollard_pm1_find_factor($rem, 2_000_000);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        say "=> Pollard rho...";
        $f = pollard_rho_find_factor($rem, ($len > 50 ? 3 : 2) * POLLARD_RHO_ITERATIONS);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        say "=> Pollard rho-sqrt...";
        $f = pollard_rho_sqrt_find_factor($rem, ($len > 50 ? 6 : 3) * POLLARD_RHO_ITERATIONS);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        if ($len < 150) {

            say "=> Pollard rho-exp...";
            $f = pollard_rho_exp_find_factor($rem, ($len > 50 ? 2 : 1) * 200);

            if (defined($f) and $f < $rem) {
                store_factor(\$rem, $f, $factors);
                next;
            }
        }

        say "=> Pollard rho (Brent)...";
        $f = pollard_brent_find_factor($rem, POLLARD_BRENT_ITERATIONS);

        if (defined($f) and $f < $rem) {
            store_factor(\$rem, $f, $factors);
            next;
        }

        if ($len > 50) {

            say "=> Pollard p-1 (10M)...";
            $f = pollard_pm1_find_factor($rem, 10_000_000);

            if (defined($f) and $f < $rem) {
                store_factor(\$rem, $f, $factors);
                next;
            }
        }

        if ($len > 70) {

            say "=> Pollard p-1 (20M)...";
            $f = pollard_pm1_find_factor($rem, 20_000_000);

            if (defined($f) and $f < $rem) {
                store_factor(\$rem, $f, $factors);
                next;
            }

            say "=> Pollard rho-exp...";
            $f = pollard_rho_exp_find_factor($rem, 1000);

            if (defined($f) and $f < $rem) {
                store_factor(\$rem, $f, $factors);
                next;
            }
        }

        if ($len > 80) {

            say "=> Pollard p-1 (50M)...";
            $f = pollard_pm1_find_factor($rem, 50_000_000);

            if (defined($f) and $f < $rem) {
                store_factor(\$rem, $f, $factors);
                next;
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
        say "$n is $root^$exp";
        return $root;
    }

    return undef;
}

sub find_prime_factors ($n, $factors) {

    # Return one or more prime factors of the given number n. Assume
    # that n is not a prime and does not have very small factors, and that
    # the global small_primes has already been initialized. Do not return
    # duplicate factors.

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

    # Return all prime factors of the given number n. Assume that n
    # does not have very small factors and that the global small_primes
    # has already been initialized.

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

sub near_power_factorization ($n) {

    my $f = sub ($r, $e, $k) {
        my @factors;

        foreach my $d (ntheory::divisors($e)) {
            foreach my $j (1, -1) {

                my $t = $r**$d - $k * $j;
                my $g = Math::GMPz->new(gcd($t, $n));

                if ($g > TRIAL_DIVISION_LIMIT and $g < $n) {
                    while ($n % $g == 0) {
                        $n /= $g;
                        push @factors, $g;
                    }
                }
            }
        }

        sort { $a <=> $b } @factors;
    };

    my @f_params;
    my @g_params;

    foreach my $j (1 .. NEAR_POWER_ITERATIONS) {
        foreach my $k (1, -1) {
            my $u = $k * $j * $j;

            if ($n + $u > 0) {
                if (my $e = is_power($n + $u)) {
                    my $r = Math::GMPz->new(rootint($n + $u, $e));
                    say "[*] Near power detected: $r^$e ", sprintf("%s %s", ($k == 1) ? ('-', $u) : ('+', -$u));
                    push @f_params, [$r, $e, $j];
                }
            }
        }
    }

    my $g = sub ($r, $e, $r2, $e2) {
        my @factors;

        my @d1 = ntheory::divisors($e);
        my @d2 = ntheory::divisors($e2);

        foreach my $d (@d1) {
            foreach my $d2 (@d2) {
                foreach my $j (1, -1) {

                    my $t = $r**$d - $j * $r2**$d2;
                    my $g = Math::GMPz->new(gcd($t, $n));

                    if ($g > TRIAL_DIVISION_LIMIT and $g < $n) {
                        while ($n % $g == 0) {
                            $n /= $g;
                            push @factors, $g;
                        }
                    }
                }
            }
        }

        foreach my $d (@d1) {
            foreach my $j (1, -1) {
                if ($d * log($e) / log(10) < 1e6) {

                    my $t = Math::GMPz->new($d)**$e - $j * Math::GMPz->new($d)**$e2;
                    my $g = Math::GMPz->new(gcd($t, $n));

                    if ($g > TRIAL_DIVISION_LIMIT and $g < $n) {
                        while ($n % $g == 0) {
                            $n /= $g;
                            push @factors, $g;
                        }
                    }
                }
            }
        }

        foreach my $d2 (@d2) {
            foreach my $j (1, -1) {
                if ($d2 * log($e) / log(10) < 1e6) {

                    my $t = Math::GMPz->new($d2)**$e - $j * Math::GMPz->new($d2)**$e2;
                    my $g = Math::GMPz->new(gcd($t, $n));

                    if ($g > TRIAL_DIVISION_LIMIT and $g < $n) {
                        while ($n % $g == 0) {
                            $n /= $g;
                            push @factors, $g;
                        }
                    }
                }
            }
        }

        sort { $a <=> $b } @factors;
    };

    foreach my $r (2 .. logint($n, 2)) {

        my $l    = logint($n, $r);
        my $u    = Math::GMPz->new($r)**($l + 1);
        my $diff = $u - $n;

        if ($diff == 1 or Math::GMPz::Rmpz_perfect_power_p($diff)) {
            my $e  = ($diff == 1) ? 1 : is_power($diff);
            my $r2 = rootint($diff, $e);
            say "[*] Difference of powers detected: ", sprintf("%s^%s - %s^%s", $r, $l + 1, $r2, $e);
            push @g_params, [Math::GMPz->new($r), $l + 1, Math::GMPz->new($r2), $e];
        }
    }

    foreach my $r (2 .. logint($n, 2)) {

        my $l    = logint($n, $r);
        my $u    = Math::GMPz->new($r)**$l;
        my $diff = $n - $u;

        if ($diff == 1 or Math::GMPz::Rmpz_perfect_power_p($diff)) {
            my $e  = ($diff == 1) ? 1 : is_power($diff);
            my $r2 = rootint($diff, $e);
            say "[*] Sum of powers detected: ", sprintf("%s^%s + %s^%s", $r, $l, $r2, $e);
            push @g_params, [Math::GMPz->new($r), $l, Math::GMPz->new($r2), $e];
        }
    }

    my @factors;
    foreach my $fp (@f_params) {
        push @factors, $f->(@$fp);
    }

    foreach my $gp (@g_params) {
        push @factors, $g->(@$gp);
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

sub factorize($n) {

    # Factorize the given integer n >= 1 into its prime factors.

    if ($n < 1) {
        die "Number needs to be an integer >= 1";
    }

    my $len = length($n);
    printf("\n[*] Factoring %s (%d digits)...\n", ($len > MASK_LIMIT ? "C$len" : $n), $len);

    return ()   if ($n <= 1);
    return ($n) if is_prime($n);

    my @divisors = (($n > ~0) ? near_power_factorization($n) : ());

    if (@divisors) {

        say "[*] Divisors found so far: ", join(', ', @divisors);

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
        my $rem = $n / Math::GMPz->new(vecprod(@factors));

        if ($rem > 1) {
            push @factors, factorize($rem);
        }

        return verify_prime_factors($n, \@factors);
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

    return verify_prime_factors($n, $factors);
}

if (@ARGV) {
    my $n = Math::GMPz->new($ARGV[0]);
    say "\nPrime factors: ", join(', ', factorize($n));
}
else {
    die "Usage: $0 <N>\n";
}
