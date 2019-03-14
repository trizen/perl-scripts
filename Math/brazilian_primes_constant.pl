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

    my $sum = Math::MPFR::Rmpfr_init2(192);
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

            if (is_prob_prime(Math::GMPz::Rmpz_get_str($z, 10))) {

                # Conjecture: duplicate terms may happen only for t = 2^k-1, for some k
                if ((($z + 1) & $z) == 0) {
                    next if $seen{$z}++;
                }

                if ($z < $N) {
                    Math::GMPq::Rmpq_set_ui($q, 1, 1);
                    Math::GMPq::Rmpq_set_den($q, $z);
                    Math::MPFR::Rmpfr_add_q($sum, $sum, $q, 0);
                }
            }
        }
    } 3, logint($N + 1, 2);

    return Math::AnyNum->new($sum);
}

foreach my $n (1..14) {
    say "B(10^$n) ~ ", brazillian_constant(Math::GMPz->new(10)**$n)->round(-32);
}

__END__
B(10^1) ~ 0.14285714285714285714285714285714
B(10^2) ~ 0.28899272838682348594073100542184
B(10^3) ~ 0.32290223556269144810843769843366
B(10^4) ~ 0.32952368063536693571523726793301
B(10^5) ~ 0.33121713119461798438057432911381
B(10^6) ~ 0.33160386963492172892306297309503
B(10^7) ~ 0.33171391586547473334091623260371
B(10^8) ~ 0.33174341910781704122196304798802
B(10^9) ~ 0.33175132673949885380067237840723
B(10^10) ~ 0.33175356516689372562521462231951
B(10^11) ~ 0.33175420579318423292974799113059
B(10^12) ~ 0.33175439067722742680152185017303
B(10^13) ~ 0.33175444440331880514669754839817
B(10^14) ~ 0.33175446011369675270545267094599
B(10^15) ~ 0.33175446473544852087966767749508
B(10^16) ~ 0.33175446610148680800864203095541
B(10^17) ~ 0.33175446650734519516960638465379
B(10^18) ~ 0.33175446662828756863723305575693
B(10^19) ~ 0.33175446666446018177571079766533
