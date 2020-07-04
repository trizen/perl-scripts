#!/usr/bin/perl

# Pollard's rho integer factorization algorithm.

# This version uses the polynomial:
#   f(x) = x^e + 2*e - 1

# where e = lcm(1..B), for a small bound B.

# See also:
#   https://en.wikipedia.org/wiki/Pollard%27s_rho_algorithm

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Math::GMPz;
use Math::Prime::Util::GMP qw(consecutive_integer_lcm logint);

sub rho_exp_factor ($n, $max_iter = 5000) {

    my $B = logint($n, 5)**2;
    my $e = Math::GMPz::Rmpz_init_set_str(consecutive_integer_lcm($B), 10);
    my $c = 2*$e - 1;

    if (length("$n") <= 12) {
        $e = Math::GMPz->new(2);
    }

    my $x = Math::GMPz::Rmpz_init_set_ui(1);
    my $y = Math::GMPz::Rmpz_init();
    my $g = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_powm($x, $x, $e, $n);
    Math::GMPz::Rmpz_add($x, $x, $c);
    Math::GMPz::Rmpz_mod($x, $x, $n);

    Math::GMPz::Rmpz_powm($y, $x, $e, $n);
    Math::GMPz::Rmpz_add($y, $y, $c);
    Math::GMPz::Rmpz_mod($y, $y, $n);

    for (1 .. $max_iter) {

        Math::GMPz::Rmpz_powm($x, $x, $e, $n);
        Math::GMPz::Rmpz_add($x, $x, $c);
        Math::GMPz::Rmpz_mod($x, $x, $n);

        Math::GMPz::Rmpz_powm($y, $y, $e, $n);
        Math::GMPz::Rmpz_add($y, $y, $c);
        Math::GMPz::Rmpz_mod($y, $y, $n);

        Math::GMPz::Rmpz_powm($y, $y, $e, $n);
        Math::GMPz::Rmpz_add($y, $y, $c);
        Math::GMPz::Rmpz_mod($y, $y, $n);

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
    314159265358979323 350011490889402191 2954624367769580651
    7167393334524676153 10033529742475370477 20135752530477192241
    21316902507352787201 2559469924891866771047 63469917720180180377579
  );

@nums = map { Math::GMPz->new($_) } @nums;

foreach my $n (@nums) {
    say "rho_exp_factor($n) = ", rho_exp_factor($n);
}

__END__
rho_exp_factor(314159265358979323) = 990371647
rho_exp_factor(350011490889402191) = 692953181
rho_exp_factor(2954624367769580651) = 490066931
rho_exp_factor(7167393334524676153) = 4721424559
rho_exp_factor(10033529742475370477) = 1412164441
rho_exp_factor(20135752530477192241) = 5907768749
rho_exp_factor(21316902507352787201) = 3055371353
rho_exp_factor(2559469924891866771047) = 266349879973
rho_exp_factor(63469917720180180377579) = 126115748167
