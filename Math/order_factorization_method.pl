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

sub order_find_factor ($n, $base = 2, $reps = 1e5) {

    $n = Math::GMPz->new("$n");

    state $z = Math::GMPz::Rmpz_init_nobless();
    state $t = Math::GMPz::Rmpz_init_nobless();

    my $g = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_set_ui($t, $base);
    Math::GMPz::Rmpz_set_ui($z, $base);

    Math::GMPz::Rmpz_powm($z, $z, $n, $n);

    # Cannot factor Fermat pseudoprimes
    if (Math::GMPz::Rmpz_cmp_ui($z, $base) == 0) {
        return undef;
    }

    my $multiplier = $base * $base;

    for (my $k = 1 ; $k <= $reps ; ++$k) {

        Math::GMPz::Rmpz_mul_ui($t, $t, $multiplier);
        Math::GMPz::Rmpz_mod($t, $t, $n) if ($k % 10 == 0);
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

say order_find_factor("97967651586822913179896725042136997967830602144506842054615710025444417607092711829309187");     #=> 86762184769343281845479348731
say order_find_factor("1129151505892449502375764445221583755878554451745780900429977", 3);                              #=> 867621847693432818454793487397
