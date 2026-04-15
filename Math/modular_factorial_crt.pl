#!/usr/bin/perl

# A simple O(n) algorithm for computing n! mod m, by factoring m and combining with CRT.

use 5.036;
use ntheory 0.74 qw(
    factor_exp chinese vecsum todigits
    powint divint mulmod forprimes powmod vecprod
);

# Legendre's Formula: Computes the exponent of highest power of p dividing n!
# Runs in O(log_p(n)) time.
sub _legendre_valuation ($n, $p) {
    divint($n - vecsum(todigits($n, $p)), $p - 1);
}

sub _facmod ($n, $mod) {

    my $p = 0;
    my $f = 1;

    forprimes {
        if ($p == 1) {
            $f = mulmod($f, $_, $mod);
        }
        else {
            $p = _legendre_valuation($n, $_);
            $f = mulmod($f, powmod($_, $p, $mod), $mod);
        }
    } $n;

    return $f;
}

sub factorialmod_crt ($n, $m) {

    # Trivial base cases
    if ($n >= $m or $m == 1) {
        return 0;
    }
    if ($n <= 1) {
        return 1;
    }

    # Factor m into prime powers [ [p1, e1], [p2, e2], ... ]
    my @factors = factor_exp($m);

    my @residues;
    for my $factor_ref (@factors) {
        my ($p, $e) = @$factor_ref;

        # Calculate p^e
        my $pe = powint($p, $e);

        # Get the power of p dividing n!
        my $valuation = _legendre_valuation($n, $p);

        # If the power of p in n! is >= e, then n! is divisible by p^e.
        # This is where we save O(n) computations!
        if ($valuation >= $e) {
            push @residues, [0, $pe];
            next;
        }

        # If we reach here, n! is NOT perfectly divisible by p^e.
        # This means n is quite small relative to p^e. We compute it directly.
        my $res = _facmod($n, $pe);

        push @residues, [$res, $pe];
    }

    # Recombine using Chinese Remainder Theorem
    chinese(@residues);
}

# --- Example Usage ---

my $n = 1000000;
my $m = vecprod(503, 503, 863, 1000000007);
say factorialmod_crt($n, $m);           #=> 51017729998226472
