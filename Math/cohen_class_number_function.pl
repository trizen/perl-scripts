#!/usr/bin/perl

# Cohen's class number function H(r, N).

use 5.036;

use Math::GMPz;
use Math::GMPq;
use Math::Prime::Util qw(
  bernfrac
  binomial
  divisor_sum
  factor_exp
  kronecker
  sqrtint
);

# Build a Math::GMPz from a native integer, string or big integer object.
sub Z ($n) {
    Math::GMPz->new("$n");
}

# Build a canonical Math::GMPq num/den.
sub Q ($num, $den = 1) {
    my $q = Math::GMPq->new("$num/$den");
    Math::GMPq::Rmpq_canonicalize($q);
    return $q;
}

# Bernoulli number B_n as an exact rational, using the convention B_1 = -1/2
# (Math::Prime::Util returns B_1 = +1/2, so it is corrected here).
sub bernoulli ($n) {
    return Q(-1, 2) if ($n == 1);
    my ($num, $den) = bernfrac($n);
    return Q($num, $den);
}

# General exact algorithm: O(|D| / 2) loop using the Bernoulli expansion.
sub L_neg_general ($r, $D) {

    $D = Z($D);

    my $absD = abs($D);
    my $M    = Math::GMPz::Rmpz_get_ui($absD >> 1);

    # The loop below is O(|D|), so D must fit in a native integer anyway.
    Math::GMPz::Rmpz_fits_slong_p($D) or die "|D| is too large for the general algorithm\n";
    my $Dn = Math::GMPz::Rmpz_get_si($D);

    # Accumulate power-character sums S_m = sum_{a=1}^{M} kronecker(D, a) * a^m
    my @S = map { Math::GMPz->new(0) } 0 .. $r;

    foreach my $k (1 .. $M) {

        my $c = kronecker($Dn, $k);
        next if ($c == 0);

        my $term = Math::GMPz->new($c);

        foreach my $m (0 .. $r) {
            $S[$m] += $term;
            $term  *= $k;
        }
    }

    my $total_q = Math::GMPq->new(0);
    my $D_pow   = Q(1, $absD);

    foreach my $j (0 .. $r) {

        my $Bj = bernoulli($j);

        if ($Bj != 0) {
            my $coeff = Math::GMPq->new(binomial($r, $j)) * $Bj * $D_pow;
            $total_q += $coeff * $S[$r - $j];
        }

        $D_pow *= $absD;
    }

    # Multiplied by 2 due to the Bernoulli polynomial symmetry:
    # chi_D(|D|-a) B_r(1 - a/|D|) = chi_D(a) B_r(a/|D|)
    return (-2 * $total_q / $r);
}

# Computes L(1-r, chi_D) for a fundamental discriminant D with (-1)^r * D > 0
sub L_neg ($r, $D) {

    $D = Z($D);

    # Base case D = 1: L(1-r, chi_1) = zeta(1-r)
    if ($D == 1) {
        if ($r == 1) {
            return Q(-1, 2);
        }
        return (-bernoulli($r) / $r);
    }

    # Optimization: O(sqrt(D)) Siegel formula for r = 2 (r5 context)
    if ($r == 2 and $D > 1) {

        my $x     = (($D % 2 == 0) ? 0 : 1);
        my $limit = sqrtint($D - 1);
        my $total = Math::GMPz->new(0);
        my $t     = Math::GMPz->new(0);

        if ($x == 0) {
            $total += Z(divisor_sum($D >> 2, 1));
            $x     += 2;
        }

        while ($x <= $limit) {
            Math::GMPz::Rmpz_set_ui($t, $x);
            Math::GMPz::Rmpz_mul($t, $t, $t);
            Math::GMPz::Rmpz_sub($t, $D, $t);
            Math::GMPz::Rmpz_div_2exp($t, $t, 2);
            Math::GMPz::Rmpz_set_str($t, divisor_sum($t, 1), 10);
            Math::GMPz::Rmpz_addmul_ui($total, $t, 2);
            $x += 2;
        }

        return (-Math::GMPq->new($total) / 5);
    }

    return L_neg_general($r, $D);
}

# Multiplicative evaluation of conductor divisor sum S_f(r, D)
sub conductor_sum ($r, $D, $f) {

    return Math::GMPz->new(1) if ($f == 1);

    my $res = Math::GMPz->new(1);
    my $k   = 2 * $r - 1;
    my $r1  = $r - 1;

    foreach my $pe (factor_exp($f)) {

        my ($p, $e) = @$pe;

        my $chi_p = kronecker($D, $p);
        my $pz    = Z($p);

        # Calculate bases once to avoid redundant exponentiations
        my $pk   = $pz**$k;
        my $pk_e = $pk**$e;

        my $sig_curr = ($pk_e * $pk - 1) / ($pk - 1);
        my $sig_prev = ($pk_e - 1) / ($pk - 1);

        my $term = $sig_curr - $chi_p * ($pz**$r1) * $sig_prev;

        $res *= $term;
    }

    return $res;
}

# Main Cohen's Class Number Function H(r, N)
sub CohenH ($r, $N) {

    $N = Z($N);

    # N = 0 case: H(r, 0) = zeta(1 - 2r) = -B_{2r} / (2r)
    if ($N == 0) {
        return (-bernoulli(2 * $r) / (2 * $r));
    }

    # Parity check: (-1)^r * N mod 4
    my $rem = (($r % 2 == 1) ? (-$N % 4) : ($N % 4));
    $rem = ($rem + 4) % 4;

    if ($rem == 2 or $rem == 3) {
        return Math::GMPz->new(0);
    }

    # Factor N = |D_0| * f_0^2
    my $D0 = Math::GMPz->new(1);
    my $f0 = Math::GMPz->new(1);

    foreach my $pe (factor_exp($N)) {
        my ($p, $e) = @$pe;
        my $pz = Z($p);
        $D0 *= $pz**($e % 2);
        $f0 *= $pz**($e >> 1);
    }

    my $sgn = (($r % 2 == 1) ? -1 : 1);
    my $D   = $D0 * $sgn;
    my $f   = $f0;

    my $D_mod4 = ($D % 4 + 4) % 4;

    if ($D_mod4 != 1) {
        $D = $D0 * 4 * $sgn;
        $f = $f0 >> 1;
    }

    my $L_val = L_neg($r, $D);
    my $S_val = conductor_sum($r, $D, $f);

    return ($L_val * $S_val);
}

# Application: Number of representations of n as a sum of 5 squares
sub r5 ($n) {
    return Math::GMPz->new(1) if ($n == 0);
    return (-40 * CohenH(2, 4 * Z($n)) + 160 * CohenH(2, $n));
}

# Application: Number of representations of n as a sum of 7 squares
sub r7 ($n) {
    return Math::GMPz->new(1) if ($n == 0);
    return (-28 * CohenH(3, 4 * Z($n)) - 224 * CohenH(3, $n));
}

# ==================== VERIFICATION & TEST SUITE ====================
# (only runs when the file is executed directly, not when it is require'd)

unless (caller) {

    use Test::More tests => 10;

    is(join('', r5(4294967297)),  "1976958991065600");
    is(join('', r5(87178291200)), "249909903070464000");
    is(join('', r7(87178291200)), "42042033202847447350924289856");

    say "\n--- Testing CohenH(r, N) Values ---";
    is(join('', CohenH(1, 0)), "-1/12");
    is(join('', CohenH(2, 0)), "1/120");
    is(join('', CohenH(3, 0)), "-1/252");
    is(join('', CohenH(2, 4)), "-7/12");
    is(join('', CohenH(3, 8)), "-3");

    say "\n--- Testing r5(n) (OEIS A000132) ---";
    foreach my $n (0 .. 5) {
        printf("r5(%d) = %s\n", $n, r5($n));
    }

    say "\n--- Testing r7(n) (OEIS A008451) ---";
    foreach my $n (0 .. 5) {
        printf("r7(%d) = %s\n", $n, r7($n));
    }

    is_deeply(
              [map { r5($_) } 0 .. 46],
              [1,    10,   40,   80,   90,   112,  240,  320,  200,  250,  560,  560,  400,  560,  800,  960,  730,  480,  1240, 1520, 752,  1120, 1840, 1600,
               1200, 1210, 2000, 2240, 1600, 1680, 2720, 3200, 1480, 1440, 3680, 3040, 2250, 2800, 3280, 4160, 2800, 1920, 4320, 5040, 2800, 3472, 5920
              ]
             );
    is_deeply(
              [map { r7($_) } 0 .. 36],
              [1,     14,    84,    280,   574,    840,   1288,  2368,   3444,  3542,  4424,  7560,  9240,  8456,
               11088, 16576, 18494, 17808, 19740,  27720, 34440, 29456,  31304, 49728, 52808, 43414, 52248, 68320,
               74048, 68376, 71120, 99456, 110964, 89936, 94864, 136080, 145222
              ]
             );
}

1;
