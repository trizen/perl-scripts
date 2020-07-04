#!/usr/bin/perl

# A fast algorithm for computing the n-th Bell number modulo a native integer.

# See also:
#   https://oeis.org/A325630 -- Numbers k such that Bell(k) == 0 (mod k).
#   https://en.wikipedia.org/wiki/Bell_number

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

sub bell_number ($n, $m) {

    my @acc;

    my $t    = Math::GMPz::Rmpz_init();
    my $bell = Math::GMPz::Rmpz_init_set_ui(1);

    foreach my $k (1 .. $n) {

        Math::GMPz::Rmpz_set($t, $bell);

        foreach my $item (@acc) {
            Math::GMPz::Rmpz_add($t, $t, $item);
            Math::GMPz::Rmpz_mod_ui($t, $t, $m);
            Math::GMPz::Rmpz_set($item, $t);
        }

        unshift @acc, Math::GMPz::Rmpz_init_set($bell);
        $bell = Math::GMPz::Rmpz_init_set($acc[-1]);
    }

    $bell;
}

say bell_number(35,  35);      #=> 0
say bell_number(35,  1234);    #=> 852
say bell_number(123, 4171);    #=> 3567
