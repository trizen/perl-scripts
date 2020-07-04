#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2016
# Website: https://github.com/trizen

# A fast algorithm, based on powers of primes,
# for exactly computing very large factorials.

use 5.020;
use strict;
use warnings;

use Math::GMPz qw(:mpz);
use experimental qw(signatures);
use ntheory qw(forprimes todigits vecsum);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub factorial ($n) {

    my $t = Rmpz_init();
    my $f = Rmpz_init_set_ui(1);

    Rmpz_mul_2exp($f, $f, my $p = factorial_power($n, 2));

    forprimes {
        if ($p == 1) {
            Rmpz_mul_ui($f, $f, $_);
        }
        else {
            Rmpz_ui_pow_ui($t, $_, $p = factorial_power($n, $_));
            Rmpz_mul($f, $f, $t);
        }
    } 3, $n;

    $f;
}

say factorial($ARGV[0] // 1234);

for (0..10) {
    say factorial($_);
}
