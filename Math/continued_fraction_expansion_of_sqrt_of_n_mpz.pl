#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 April 2019
# https://github.com/trizen

# Compute the simple continued fraction expansion for the square root of a given number.

# Algorithm from:
#   https://web.math.princeton.edu/mathlab/jr02fall/Periodicity/mariusjp.pdf

# See also:
#   https://en.wikipedia.org/wiki/Continued_fraction
#   https://mathworld.wolfram.com/PeriodicContinuedFraction.html

use 5.010;
use strict;
use warnings;

use Math::GMPz;

sub cfrac_sqrt {
    my ($n) = @_;

    $n = Math::GMPz->new("$n");

    my $x = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sqrt($x, $n);

    return ($x) if Math::GMPz::Rmpz_perfect_square_p($n);

    my $y = Math::GMPz::Rmpz_init_set($x);
    my $z = Math::GMPz::Rmpz_init_set_ui(1);
    my $r = Math::GMPz::Rmpz_init();

    my @cfrac = ($x);

    Math::GMPz::Rmpz_add($r, $x, $x);    # r = x+x

    do {
        my $t = Math::GMPz::Rmpz_init();

        # y = (r*z - y)
        Math::GMPz::Rmpz_submul($y, $r, $z);    # y = y - t*z
        Math::GMPz::Rmpz_neg($y, $y);           # y = -y

        # z = floor((n - y*y) / z)
        Math::GMPz::Rmpz_mul($t, $y, $y);       # t = y*y
        Math::GMPz::Rmpz_sub($t, $n, $t);       # t = n-t
        Math::GMPz::Rmpz_divexact($z, $t, $z);  # z = t/z

        # t = floor((x + y) / z)
        Math::GMPz::Rmpz_add($t, $x, $y);       # t = x+y
        Math::GMPz::Rmpz_tdiv_q($t, $t, $z);    # t = floor(t/z)

        $r = $t;
        push @cfrac, $t;

    } until (Math::GMPz::Rmpz_cmp_ui($z, 1) == 0);

    return @cfrac;
}

foreach my $n (1 .. 20) {
    say "sqrt($n) = [", join(', ', cfrac_sqrt($n)), "]";
}

__END__
sqrt(1) = [1]
sqrt(2) = [1, 2]
sqrt(3) = [1, 1, 2]
sqrt(4) = [2]
sqrt(5) = [2, 4]
sqrt(6) = [2, 2, 4]
sqrt(7) = [2, 1, 1, 1, 4]
sqrt(8) = [2, 1, 4]
sqrt(9) = [3]
sqrt(10) = [3, 6]
sqrt(11) = [3, 3, 6]
sqrt(12) = [3, 2, 6]
sqrt(13) = [3, 1, 1, 1, 1, 6]
sqrt(14) = [3, 1, 2, 1, 6]
sqrt(15) = [3, 1, 6]
sqrt(16) = [4]
sqrt(17) = [4, 8]
sqrt(18) = [4, 4, 8]
sqrt(19) = [4, 2, 1, 3, 1, 2, 8]
sqrt(20) = [4, 2, 8]
