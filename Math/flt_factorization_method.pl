#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 02 August 2020
# Edit: 02 March 2026
# https://github.com/trizen

# A new factorization method for numbers that have all prime factors close to each other.

# Inpsired by Fermat's Little Theorem (FLT).

use 5.014;
use warnings;
use Math::GMPz;

use ntheory qw(:all);
use POSIX   qw(ULONG_MAX);

sub flt_factor {
    my ($n, $base, $reps) = @_;

    # base: a native integer <= sqrt(ULONG_MAX)
    # reps: how many tries before giving up

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    $base = 2   if (!defined($base) or $base < 2);
    $reps = 1e6 if (!defined($reps));

    my $z     = Math::GMPz::Rmpz_init();
    my $t     = Math::GMPz::Rmpz_init_set_ui($base);
    my $g     = Math::GMPz::Rmpz_init();
    my $accum = Math::GMPz::Rmpz_init_set_ui(1);

    Math::GMPz::Rmpz_powm($z, $t, $n, $n);

    Math::GMPz::Rmpz_sub($g, $z, $t);
    Math::GMPz::Rmpz_gcd($g, $g, $n);
    if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0 && Math::GMPz::Rmpz_cmp($g, $n) < 0) {
        my $x = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_divexact($x, $n, $g);
        return sort { Math::GMPz::Rmpz_cmp($a, $b) } ($x, $g);
    }

    # Cannot factor Fermat pseudoprimes
    if (Math::GMPz::Rmpz_cmp_ui($z, $base) == 0) {
        return ($n);
    }

    my $multiplier = $base * $base;

    if ($multiplier > ULONG_MAX) {    # base is too large
        return ($n);
    }

    for (my $j = 1 ; $j <= $reps ; $j++) {
        Math::GMPz::Rmpz_mul_ui($t, $t, $multiplier);
        Math::GMPz::Rmpz_mod($t, $t, $n);

        Math::GMPz::Rmpz_sub($g, $z, $t);

        # Multiply into accumulator instead of GCD every time
        Math::GMPz::Rmpz_mul($accum, $accum, $g);
        Math::GMPz::Rmpz_mod($accum, $accum, $n);

        # Only run the expensive GCD operation every 50 iterations
        if ($j % 50 == 0) {
            Math::GMPz::Rmpz_gcd($g, $accum, $n);

            if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
                if (Math::GMPz::Rmpz_cmp($g, $n) == 0) {
                    return $n;    # Collision, would need backtracking here
                }
                my $x = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_divexact($x, $n, $g);
                return sort { Math::GMPz::Rmpz_cmp($a, $b) } ($x, $g);
            }

            # Reset accumulator
            Math::GMPz::Rmpz_set_ui($accum, 1);
        }
    }

    return $n;
}

my $p = random_ndigit_prime(30);

say join ' * ', flt_factor("173315617708997561998574166143524347111328490824959334367069087");
say join ' * ', flt_factor("2425361208749736840354501506901183117777758034612345610725789878400467");

say join ' * ', flt_factor(vecprod($p, next_prime($p),      next_prime(next_prime($p))));
say join ' * ', flt_factor(vecprod($p, next_prime(13 * $p), next_prime(123 * $p)));
say join ' * ', flt_factor(vecprod($p, next_prime($p),      next_prime(next_prime($p)), powint(2, 128) + 1));
