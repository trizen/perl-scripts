#!/usr/bin/perl

# A simple O(n) algorithm for computing n! mod m, by factoring m and combining with CRT.

use 5.036;
use Math::GMPz;
use ntheory qw(
    factor_exp chinese forprimes
    divint vecsum todigits vecprod
);

# Legendre's Formula: Computes the exponent of highest power of p dividing n!
# Runs in O(log_p(n)) time.
sub _legendre_valuation ($n, $p) {
    divint($n - vecsum(todigits($n, $p)), $p - 1);
}

sub _facmod ($n, $mod) {

    my $p = 0;
    my $f = Math::GMPz::Rmpz_init_set_ui(1);

    state $t = Math::GMPz::Rmpz_init_nobless();

    forprimes {
        if ($p == 1) {
            Math::GMPz::Rmpz_mul_ui($f, $f, $_);
            Math::GMPz::Rmpz_mod($f, $f, $mod);
        }
        else {
            $p = _legendre_valuation($n, $_);
            Math::GMPz::Rmpz_set_ui($t, $_);
            Math::GMPz::Rmpz_powm_ui($t, $t, $p, $mod);
            Math::GMPz::Rmpz_mul($f, $f, $t);
            Math::GMPz::Rmpz_mod($f, $f, $mod);
        }
    } $n;

    return $f;
}

sub factorialmod_crt ($n_scalar, $m_scalar) {

    my $n = Math::GMPz->new($n_scalar);
    my $m = Math::GMPz->new($m_scalar);

    # Trivial base cases
    if (Math::GMPz::Rmpz_cmp($n, $m) >= 0 or Math::GMPz::Rmpz_cmp_ui($m, 1) == 0) {
        return Math::GMPz->new(0);
    }
    if (Math::GMPz::Rmpz_cmp_ui($n, 1) <= 0) {
        return Math::GMPz->new(1);
    }

    # Factor m into prime powers [ [p1, e1], [p2, e2], ... ]
    my @factors = factor_exp($m_scalar);

    my $p_z  = Math::GMPz::Rmpz_init();
    my $pe_z = Math::GMPz::Rmpz_init();

    my @residues;
    for my $factor_ref (@factors) {
        my ($p, $e) = @$factor_ref;

        # Calculate p^e
        Math::GMPz::Rmpz_set_str($p_z, $p, 10);
        Math::GMPz::Rmpz_pow_ui($pe_z, $p_z, $e);

        # Get the power of p dividing n!
        my $valuation = _legendre_valuation($n_scalar, $p);

        # If the power of p in n! is >= e, then n! is divisible by p^e.
        # This is where we save O(n) computations!
        if ($valuation >= $e) {
            push @residues, [0, Math::GMPz::Rmpz_get_str($pe_z, 10)];
            next;
        }

        # If we reach here, n! is NOT perfectly divisible by p^e.
        # This means n is quite small relative to p^e. We compute it directly.
        my $res = _facmod(Math::GMPz::Rmpz_get_ui($n), $pe_z);

        push @residues, [
            Math::GMPz::Rmpz_get_str($res, 10),
            Math::GMPz::Rmpz_get_str($pe_z, 10)
        ];
    }

    # Recombine using Chinese Remainder Theorem
    Math::GMPz->new(chinese(@residues));
}

# --- Example Usage ---

my $n = 1000000;
my $m = vecprod(503, 503, 863, 1000000007);
say factorialmod_crt($n, $m);           #=> 51017729998226472
