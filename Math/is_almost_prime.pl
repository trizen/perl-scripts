#!/usr/bin/perl

# Author: Trizen
# Date: 17 February 2023
# https://github.com/trizen

# A simple and fast method for checking if a given integer n has exactly k prime factors (i.e.: bigomega(n) = k).

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);

use Math::GMPz;
use Math::Prime::Util::GMP;

use constant {
              TRIAL_LIMIT        => 1e3,
              HAS_NEW_PRIME_UTIL => defined(&Math::Prime::Util::is_almost_prime),
             };

my @SMALL_PRIMES = @{primes(TRIAL_LIMIT)};

sub mpz_is_almost_prime ($n, $k) {

    state $z = Math::GMPz::Rmpz_init();
    state $t = Math::GMPz::Rmpz_init();

    if ($n == 0) {
        return 0;
    }

    Math::GMPz::Rmpz_set_str($z, "$n", 10);
    Math::GMPz::Rmpz_root($t, $z, $k);

    my $trial_limit = Math::GMPz::Rmpz_get_ui($t);

    if ($trial_limit > TRIAL_LIMIT or !Math::GMPz::Rmpz_fits_ulong_p($t)) {
        $trial_limit = TRIAL_LIMIT;
    }

    foreach my $p (@SMALL_PRIMES) {

        last if ($p > $trial_limit);

        if (Math::GMPz::Rmpz_divisible_ui_p($z, $p)) {
            Math::GMPz::Rmpz_set_ui($t, $p);
            $k -= Math::GMPz::Rmpz_remove($z, $z, $t);
        }

        ($k > 0) or last;

        if (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($z)) {
            return Math::Prime::Util::is_almost_prime($k, Math::GMPz::Rmpz_get_ui($z));
        }
    }

    if ($k < 0) {
        return 0;
    }

    if (Math::GMPz::Rmpz_cmp_ui($z, 1) == 0) {
        return ($k == 0);
    }

    if ($k == 0) {
        return (Math::GMPz::Rmpz_cmp_ui($z, 1) == 0);
    }

    if ($k == 1) {

        if (Math::GMPz::Rmpz_fits_ulong_p($z)) {
            return is_prime(Math::GMPz::Rmpz_get_ui($z));
        }

        return Math::Prime::Util::GMP::is_prime(Math::GMPz::Rmpz_get_str($z, 10));
    }

    Math::GMPz::Rmpz_ui_pow_ui($t, next_prime($trial_limit), $k);

    if (Math::GMPz::Rmpz_cmp($z, $t) < 0) {
        return 0;
    }

    (HAS_NEW_PRIME_UTIL and Math::GMPz::Rmpz_fits_ulong_p($z))
      ? Math::Prime::Util::is_almost_prime($k, Math::GMPz::Rmpz_get_ui($z))
      : (factor(Math::GMPz::Rmpz_get_str($z, 10)) == $k);
}

foreach my $n (1 .. 100) {
    my $t = urandomb($n) + 1;

    say "Testing: $t";

    foreach my $k (1 .. 20) {
        if (HAS_NEW_PRIME_UTIL ? Math::Prime::Util::is_almost_prime($k, $t) : (factor($t) == $k)) {
            mpz_is_almost_prime($t, $k) || die "error for: ($t, $k)";
        }
        elsif (mpz_is_almost_prime($t, $k)) {
            die "counter-example: ($t, $k)";
        }
    }
}
