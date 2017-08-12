#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 August 2017
# https://github.com/trizen

# Algorithm invented by J. Stein in 1967, described in the
# book "Algorithmic Number Theory" by Eric Bach and Jeffrey Shallit.

use 5.010;
use strict;
use warnings;

use Math::GMPz;

sub binary_gcd {
    my ($u, $v) = @_;

    $u = Math::GMPz::Rmpz_init_set($u);
    $v = Math::GMPz::Rmpz_init_set($v);

    my $g = Math::GMPz::Rmpz_init_set_ui(1);

    while (Math::GMPz::Rmpz_even_p($u) and Math::GMPz::Rmpz_even_p($v)) {
        Math::GMPz::Rmpz_div_2exp($v, $v, 1);
        Math::GMPz::Rmpz_div_2exp($u, $u, 1);
        Math::GMPz::Rmpz_mul_2exp($g, $g, 1);
    }

    while (Math::GMPz::Rmpz_sgn($u)) {
        if (Math::GMPz::Rmpz_even_p($u)) {
            Math::GMPz::Rmpz_div_2exp($u, $u, 1);
        }
        elsif (Math::GMPz::Rmpz_even_p($v)) {
            Math::GMPz::Rmpz_div_2exp($v, $v, 1);
        }
        elsif (Math::GMPz::Rmpz_cmp($u, $v) >= 0) {
            Math::GMPz::Rmpz_sub($u, $u, $v);
            Math::GMPz::Rmpz_div_2exp($u, $u, 1);
        }
        else {
            Math::GMPz::Rmpz_sub($v, $v, $u);
            Math::GMPz::Rmpz_div_2exp($v, $v, 1);
        }
    }

    Math::GMPz::Rmpz_mul($g, $g, $v);
    return $g;
}

my $u = Math::GMPz->new('484118311800307409686872049018968526148964320406131317406564776592214983358038627898935326228550128722261905040875508300794183477624832000000000000000000000000');
my $v = Math::GMPz->new('93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000');

say binary_gcd($u, $v); #=> 33464469725118339932738475939854523519700805708105926500308251028510111778609255576238987149312000000000000000000000000
say binary_gcd($v, $u); #=> 33464469725118339932738475939854523519700805708105926500308251028510111778609255576238987149312000000000000000000000000
