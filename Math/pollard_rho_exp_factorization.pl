#!/usr/bin/perl

# Pollard's rho integer factorization algorithm.

# This version uses the polynomial:
#   f(x) = x^(n^2 - 1) + 1

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

sub rho_exp_factor ($n, $max_iter = 20000) {

    my $c = 1;
    my $t = $n * $n - 1;

    my $x = Math::GMPz::Rmpz_init_set_ui($c);
    my $y = Math::GMPz::Rmpz_init();
    my $g = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_powm($y, $x, $t, $n);
    Math::GMPz::Rmpz_add_ui($y, $y, $c);

    for (1 .. $max_iter) {

        Math::GMPz::Rmpz_powm($x, $x, $t, $n);
        Math::GMPz::Rmpz_add_ui($x, $x, $c);

        Math::GMPz::Rmpz_powm($y, $y, $t, $n);
        Math::GMPz::Rmpz_add_ui($y, $y, $c);

        Math::GMPz::Rmpz_powm($y, $y, $t, $n);
        Math::GMPz::Rmpz_add_ui($y, $y, $c);

        Math::GMPz::Rmpz_sub($g, $x, $y);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) != 0) {
            return undef if ($g == $n);
            return $g;
        }
    }

    return $n;
}

my @nums = qw(
  33670570905491953
  314159265358979323
  7167393334524676153
  2559469924891866771047
  63469917720180180377579
  );

@nums = map { Math::GMPz->new($_) } @nums;

foreach my $n (@nums) {
    say "rho_exp_factor($n) = ", rho_exp_factor($n);
}

__END__
rho_exp_factor(33670570905491953) = 36169843
rho_exp_factor(314159265358979323) = 317213509
rho_exp_factor(7167393334524676153) = 1518057367
rho_exp_factor(2559469924891866771047) = 266349879973
rho_exp_factor(63469917720180180377579) = 503267186237
