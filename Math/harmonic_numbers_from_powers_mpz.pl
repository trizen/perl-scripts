#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 July 2017
# https://github.com/trizen

# Computation of the nth-harmonic number, using perfect powers.

use 5.010;
use strict;
use warnings;

use Math::GMPz;

sub harmonic_numbers_from_powers {
    my ($n) = @_;

    my @seen;

    my $num = Math::GMPz::Rmpz_init_set_ui($n <= 0 ? 0 : 1);
    my $den = Math::GMPz::Rmpz_init_set_ui(1);

    foreach my $k (2 .. $n) {
        if (not exists $seen[$k]) {

            my $p = $k;

            do {
                $seen[$p] = undef;
            } while (($p *= $k) <= $n);

            my $g = $p / $k;
            my $t = ($g - 1) / ($k - 1);

            Math::GMPz::Rmpz_mul_ui($num, $num, $g);

            $t == 1
              ? Math::GMPz::Rmpz_add($num, $num, $den)
              : Math::GMPz::Rmpz_addmul_ui($num, $den, $t);

            Math::GMPz::Rmpz_mul_ui($den, $den, $g);
        }
    }

    my $gcd = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_gcd($gcd, $num, $den);
    Math::GMPz::Rmpz_divexact($num, $num, $gcd);
    Math::GMPz::Rmpz_divexact($den, $den, $gcd);

    return ($num, $den);
}

foreach my $n (0 .. 30) {
    printf "%20s / %-20s\n", harmonic_numbers_from_powers($n);
}
