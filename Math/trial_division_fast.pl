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

    my @factors;
    my $remainder = 1;

    my @P = sieve_primes(2, $L);

    my $range_trial_factor = sub ($n) {
        my @arr;
        my $prod = Math::GMPz::Rmpz_init_set_ui(1);
        foreach my $p (@P) {
            if (Math::GMPz::Rmpz_divisible_ui_p($n, $p)) {
                push @arr, $p;
                Math::GMPz::Rmpz_mul_ui($prod, $prod, $p);
                last if (Math::GMPz::Rmpz_cmp($prod, $n) == 0);
            }
        }
        return @arr;
    };

    my $g = Math::GMPz::Rmpz_init();

    my $valuation = sub ($n, $p) {
        Math::GMPz::Rmpz_set_ui($g, $p);
        Math::GMPz::Rmpz_remove($g, $n, $g);
    };

    while (1) {

        # say "L = $L with $#P";

        Math::GMPz::Rmpz_set_str($g, vecprod(@P), 10);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        # Early stop when n seems to no longer have small factors
        if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
            $remainder = $n;
            last;
        }

        my @f = map { ($_) x $valuation->($n, $_) } $range_trial_factor->($g);
        my $r = $n / Math::GMPz->new(vecprod(@f));

        push @factors, @f;

        # Early stop when n has been fully factored
        if ($r == 1) {
            last;
        }

        # Early stop when the trial range has been exhausted
        if ($L > $R) {
            $remainder = $r;
            last;
        }

        $n = $r;
        @P = sieve_primes($L + 1, $L << 1);
        $L <<= 1;
    }

    return (\@factors, $remainder);
}

my $n = consecutive_integer_lcm(38861);
## my $n = vecprod(consecutive_integer_lcm(38861), Math::GMPz->new(2)**128 + 1);

say "Length of n = ", length($n);

my $t0 = [gettimeofday];
my ($f, $r) = fast_trial_factor($n);
my $elapsed = tv_interval($t0, [gettimeofday]);

say "remainder = $r";
say "bigomega(n) = ", scalar(@$f);
say "Factorization took $elapsed seconds.";

__END__
Length of n = 16875
remainder = 1
bigomega(n) = 4175
Factorization took 0.062432 seconds.
