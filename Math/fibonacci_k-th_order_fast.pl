#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 April 2018
# https://github.com/trizen

# Efficient algorithm for computing the k-th order Fibonacci numbers.

# See also:
#   https://oeis.org/A000045    (2-nd order: Fibonacci numbers)
#   https://oeis.org/A000073    (3-rd order: Tribonacci numbers)
#   https://oeis.org/A000078    (4-th order: Tetranacci numbers)
#   https://oeis.org/A001591    (5-th order: Pentanacci numbers)

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);

sub kth_order_fibonacci ($n, $k = 2) {

    # Algorithm due to M. F. Hasler
    # See: https://oeis.org/A302990

    if ($n < $k - 1) {
        return 0;
    }

    my @f = map {
        $_ < $k
          ? do {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_setbit($z, $_);
            $z;
          }
          : Math::GMPz::Rmpz_init_set_ui(1)
    } 1 .. ($k + 1);

    my $t = Math::GMPz::Rmpz_init();

    foreach my $i (2 * ++$k - 2 .. $n) {
        Math::GMPz::Rmpz_mul_2exp($t, $f[($i - 1) % $k], 1);
        Math::GMPz::Rmpz_sub($f[$i % $k], $t, $f[$i % $k]);
    }

    return $f[$n % $k];
}

say "Tribonacci: ", join(' ', map { kth_order_fibonacci($_, 3) } 0 .. 15);
say "Tetranacci: ", join(' ', map { kth_order_fibonacci($_, 4) } 0 .. 15);
say "Pentanacci: ", join(' ', map { kth_order_fibonacci($_, 5) } 0 .. 15);
