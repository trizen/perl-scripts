#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 02 August 2020
# https://github.com/trizen

# A new factorization method for numbers that have all prime factors close to each other.

# Inpsired by Fermat's little theorem.

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::GMPz;

sub order_find_factor ($n, $max_iter = 1e5) {

    $n = Math::GMPz->new("$n");

    state $TWO = Math::GMPz::Rmpz_init_set_ui_nobless(2);

    state $z = Math::GMPz::Rmpz_init_nobless();
    state $t = Math::GMPz::Rmpz_init_nobless();

    my $g = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_powm($z, $TWO, $n, $n);

    # Cannot factor Fermat pseudoprimes
    if (Math::GMPz::Rmpz_cmp_ui($z, 2) == 0) {
        return undef;
    }

    for (my $k = 1 ; $k <= $max_iter ; $k += 2) {

        Math::GMPz::Rmpz_powm_ui($t, $TWO, $k, $n);
        Math::GMPz::Rmpz_sub($g, $z, $t);
        Math::GMPz::Rmpz_gcd($g, $g, $n);

        if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
            return undef if (Math::GMPz::Rmpz_cmp($g, $n) == 0);
            return $g;
        }
    }

    return undef;
}

say order_find_factor("1759590140239532167230871849749630652332178307219845847129");    #=> 12072684186515582507
say order_find_factor("28168370236334094367936640078057043313881469151722840306493");   #=> 30426633744568826749
