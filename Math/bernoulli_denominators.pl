#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 May 2017
# https://github.com/trizen

# Fast computation of the denominator of the nth-Bernoulli number.

# See also:
#   https://oeis.org/A139822
#   https://en.wikipedia.org/wiki/Von_Staudt%E2%80%93Clausen_theorem

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use POSIX qw(ULONG_MAX);
use ntheory qw(fordivisors is_prob_prime);

sub bernoulli_denominator {
    my ($n) = @_;

    return 1 if ($n == 0);
    return 2 if ($n == 1);
    return 1 if ($n % 2 == 1);

    my $p = Math::GMPz::Rmpz_init();
    my $d = Math::GMPz::Rmpz_init_set_ui(1);

    fordivisors {
        if ($_ >= ULONG_MAX) {
            Math::GMPz::Rmpz_set_str($p, "$_", 10);
            Math::GMPz::Rmpz_add_ui($p, $p, 1);

            if (is_prob_prime($p)) {
                Math::GMPz::Rmpz_mul($d, $d, $p);
            }
        }
        else {
            if (is_prob_prime($_ + 1)) {
                Math::GMPz::Rmpz_mul_ui($d, $d, $_ + 1);    # d = d * p, where (p-1)|n
            }
        }
    } $n;

    return $d;
}

foreach my $n (0 .. 20) {
    say "denom(B(10^$n)) = ", bernoulli_denominator(Math::GMPz->new('1' . ('0' x $n)));
}

__END__
denom(B(10^0)) = 2
denom(B(10^1)) = 66
denom(B(10^2)) = 33330
denom(B(10^3)) = 342999030
denom(B(10^4)) = 2338224387510
denom(B(10^5)) = 9355235774427510
denom(B(10^6)) = 936123257411127577818510
denom(B(10^7)) = 9601480183016524970884020224910
denom(B(10^8)) = 394815332706046542049668428841497001870
denom(B(10^9)) = 24675958688943241584150818852261991458372001870
