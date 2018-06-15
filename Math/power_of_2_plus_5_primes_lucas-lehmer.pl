#!/usr/bin/perl

# Primality test for primes of the form 2^n + 5.

# First few exponents of such primes, are:
#   1, 3, 5, 11, 47, 53, 141, 143, 191, 273, 341, 16541, 34001, 34763, 42167, ...

# The primality test was derived from the Lucas-Lehmer primality test for Mersenne primes.

# See also:
#   https://oeis.org/A059242

use 5.014;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

sub is_pow2_plus5_prime($n) {

    my $M = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_setbit($M, $n);
    Math::GMPz::Rmpz_add_ui($M, $M, 5);

    if (Math::GMPz::Rmpz_divisible_ui_p($M, 3)) {
        return 0;
    }

    # Ideally, this code should be executed in parallel
    if ($n > 1e4) {

        my $res = eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            alarm 30;
            chomp(my $test = `$^X -MMath::GMPz -MMath::Prime::Util::GMP=is_prob_prime -E 'say is_prob_prime((Math::GMPz->new(1) << $n) + 5)'`);
            alarm 0;
            return $test;
        };

        return $res if defined($res);
    }

    my $S = Math::GMPz::Rmpz_init_set_ui(4);

    foreach my $i (1 .. $n) {
        Math::GMPz::Rmpz_powm_ui($S, $S, 2, $M);
        Math::GMPz::Rmpz_sub_ui($S, $S, 2);
    }

    Math::GMPz::Rmpz_cmp_ui($S, 194) == 0;
}

foreach my $n (1 .. 400) {
    say $n if is_pow2_plus5_prime($n);
}

# Find more primes of the form: 2^n + 5
# A059242(18) > 5*10^5. - Robert Price, Aug 23 2015
if (0) {
    foreach my $n (5 * 10**5 .. 1e6) {
        say "Testing: $n";
        if (is_pow2_plus5_prime($n)) {
            die "Found: $n";
        }
    }
}
