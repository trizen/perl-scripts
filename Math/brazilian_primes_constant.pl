#!/usr/bin/perl

# Compute the decimal expansion of the sum of reciprocals of Brazilian primes, also called the Brazilian primes constant.

# OEIS sequences:
#   https://oeis.org/A085104 (Brazillian primes)
#   https://oeis.org/A306759 (Decimal expansion of the sum of reciprocals of Brazilian primes)

use 5.020;
use warnings;
use experimental qw(signatures);

use ntheory qw(:all);
use Math::AnyNum;

sub brazillian_constant ($lim) {

    my $N = Math::GMPz->new("$lim");
    my $q = Math::GMPq->new(0);
    my $z = Math::GMPz->new(0);

    my $sum = Math::MPFR::Rmpfr_init2(92);
    Math::MPFR::Rmpfr_set_ui($sum, 0, 0);

    my %seen;

    # The algorithm for generating the Brazillian primes is due to M. F. Hasler.
    # See: https://oeis.org/A085104

    forprimes {
        my $K = $_;
        for my $n (2 .. rootint($N - 1, $K - 1)) {

            Math::GMPz::Rmpz_ui_pow_ui($z, $n, $K);
            Math::GMPz::Rmpz_sub_ui($z, $z, 1);
            Math::GMPz::Rmpz_divexact_ui($z, $z, $n - 1);

            my $t = Math::GMPz::Rmpz_get_ui($z);

            if (is_prob_prime($t)) {

                # Duplicate terms may happen only for t = 2^k-1, for some k
                if ((($t + 1) & $t) == 0) {
                    next if $seen{$t}++;
                }

                if ($t < $N) {
                    Math::GMPq::Rmpq_set_ui($q, 1, $t);
                    Math::MPFR::Rmpfr_add_q($sum, $sum, $q, 0);
                }
            }
        }
    } 3, logint($N + 1, 2);

    return Math::AnyNum->new($sum);
}

foreach my $n (1..14) {
    say "B(10^$n) ~ ", brazillian_constant(Math::GMPz->new(10)**$n)->round(-15);
}

__END__
B(10^1) ~ 0.142857142857143
B(10^2) ~ 0.288992728386823
B(10^3) ~ 0.322902235562691
B(10^4) ~ 0.329523680635367
B(10^5) ~ 0.331217131194618
B(10^6) ~ 0.331603869634922
B(10^7) ~ 0.331713915865475
B(10^8) ~ 0.331743419107817
B(10^9) ~ 0.331751326739499
B(10^10) ~ 0.331753565166894
B(10^11) ~ 0.331754205793184
B(10^12) ~ 0.331754390677227
B(10^13) ~ 0.331754444403319
B(10^14) ~ 0.331754460113697
B(10^15) ~ 0.331754464735449
B(10^16) ~ 0.331754466101487
B(10^17) ~ 0.331754466507345
