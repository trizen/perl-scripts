#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 06 July 2018
# https://github.com/trizen

# The following 1628-digit number: 46785696846401151 * 3^3377 requires 41763 steps to get down to 1.

# Collatz function on higher powers of 3 multiplied with n = 46785696846401151:
#      collatz(n * 3^8818) = 101856
#      collatz(n * 3^9071) = 106610
#      collatz(n * 3^9296) = 108210
#      collatz(n * 3^9586) = 110042
#      collatz(n * 3^9660) = 113569
#      collatz(n * 3^9870) = 113951

# See also:
#   https://oeis.org/A006877
#   https://oeis.org/A006577

use 5.010;
use strict;
use warnings;

use Math::GMPz;

sub collatz {
    my ($n) = @_;

    $n = Math::GMPz->new("$n");

    state $two = Math::GMPz::Rmpz_init_set_ui(2);
    my $count = Math::GMPz::Rmpz_remove($n, $n, $two);

    while (Math::GMPz::Rmpz_cmp_ui($n, 1) > 0) {

        Math::GMPz::Rmpz_mul_ui($n, $n, 3);
        Math::GMPz::Rmpz_add_ui($n, $n, 1);

        $count += 1 + Math::GMPz::Rmpz_remove($n, $n, $two);
    }

    return $count;
}

my $factor = Math::GMPz->new("46785696846401151");
my $base   = Math::GMPz->new(3);

my $max = 0;

foreach my $n (0 .. 2500) {
    my $t = collatz($factor * $base**$n);

    if ($t > $max) {
        say "collatz($factor * $base^$n) = $t";
        $max = $t;
    }
}
