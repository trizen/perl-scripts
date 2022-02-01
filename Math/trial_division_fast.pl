#!/usr/bin/perl

# Author: Trizen
# Date: 31 January 2022
# https://github.com/trizen

# Fast adaptive trial-division algorithm.

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use Time::HiRes qw(gettimeofday tv_interval);
use Math::Prime::Util::GMP qw(:all);

use experimental qw(signatures);

sub fast_trial_factor ($n, $L = 1e4, $R = 1e6) {

    $n = Math::GMPz->new("$n");

    my @P = sieve_primes(2, $L);

    my $g = Math::GMPz::Rmpz_init();
    my $t = Math::GMPz::Rmpz_init();

    my @factors;

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

                # Stop the loop early when no more primes divide `g` (optional)
                Math::GMPz::Rmpz_divexact_ui($g, $g, $p);
                last if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0);
            }
        }

        # Early stop when n has been fully factored or the trial range has been exhausted
        if ($L >= $R or Math::GMPz::Rmpz_cmp_ui($n, 1) == 0) {
            last;
        }

        @P = sieve_primes($L + 1, $L << 1);
        $L <<= 1;
    }

    return (\@factors, $n);
}

my $n = consecutive_integer_lcm(138861);

# $n = vecprod($n, Math::GMPz->new(2)**128 + 1);

say "Length of n = ", length($n);

my $t0 = [gettimeofday];
my ($f, $r) = fast_trial_factor($n);
my $elapsed = tv_interval($t0, [gettimeofday]);

say "remainder = $r";
say "bigomega(n) = ", scalar(@$f);
say "Factorization took $elapsed seconds.";

__END__
Length of n = 60336
remainder = 1
bigomega(n) = 13034
Factorization took 0.490573 seconds.
