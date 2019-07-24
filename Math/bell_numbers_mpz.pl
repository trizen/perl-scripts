#!/usr/bin/perl

# Fast algorithm for computing the first `n` Bell numbers, using Aitken's array (optimized for space).

# See also:
#   https://en.wikipedia.org/wiki/Bell_number

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

sub bell_numbers($n) {

    my @acc;

    my $t    = Math::GMPz::Rmpz_init();
    my @bell = (Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $k (1 .. $n) {

        Math::GMPz::Rmpz_set($t, $bell[-1]);

        foreach my $item (@acc) {
            Math::GMPz::Rmpz_add($t, $t, $item);
            Math::GMPz::Rmpz_set($item, $t);
        }

        unshift @acc, Math::GMPz::Rmpz_init_set($bell[-1]);
        push @bell, Math::GMPz::Rmpz_init_set($acc[-1]);
    }

    @bell;
}

say join ', ', bell_numbers(15);

__END__
1, 1, 2, 5, 15, 52, 203, 877, 4140, 21147, 115975, 678570, 4213597, 27644437, 190899322, 1382958545
