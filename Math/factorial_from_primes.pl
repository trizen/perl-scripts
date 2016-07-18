#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2016
# Website: https://github.com/trizen

# A fast algorithm, based on powers of primes,
# for exactly computing very large factorials.

use 5.010;
use strict;
use warnings;

use Math::GMPz qw(:mpz);
use ntheory qw(forprimes);

sub power {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    $s;
}

sub factorial {
    my ($n) = @_;

    my $t = Rmpz_init();
    my $f = Rmpz_init_set_ui(1);

    Rmpz_mul_2exp($f, $f, my $p = power($n, 2));

    forprimes {
        if ($p == 1) {
            Rmpz_mul_ui($f, $f, $_);
        }
        else {
            Rmpz_ui_pow_ui($t, $_, $p = power($n, $_));
            Rmpz_mul($f, $f, $t);
        }
    } 3, $n;

    $f;
}

say factorial($ARGV[0] // 1234);

for (0..10) {
    say factorial($_);
}
