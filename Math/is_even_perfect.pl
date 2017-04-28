#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 September 2016
# Website: https://github.com/trizen

# A very fast function that returns true when a given number is even-perfect. False otherwise.

# See also:
#   https://en.wikipedia.org/wiki/Perfect_number

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload is_power isqrt);
use ntheory qw(is_mersenne_prime is_prime_power);

sub is_even_perfect {
    my ($n) = @_;

    $n % 2 == 0 || return 0;

    my $square = 8 * $n + 1;
    is_power($square, 2) || return 0;

    my $tp = (isqrt($square) + 1) / 2;
    my $k = is_prime_power($tp, \my $base) || return 0;

    defined($base) && ($base == 2) && is_mersenne_prime($k) ? 1 : 0;
}

say is_even_perfect(191561942608236107294793378084303638130997321548169216);                           # true
say is_even_perfect(191561942608236107294793378084303638130997321548169214);                           # false
say is_even_perfect(191561942608236107294793378084303638130997321548169218);                           # false
say is_even_perfect(14474011154664524427946373126085988481573677491474835889066354349131199152128);    # true

# A much larger perfect number
say is_even_perfect(Math::AnyNum->new('141053783706712069063207958086063189881486743514715667838838675999954867742652380114104193329037690251561950568709829327164087724366370087116731268159313652487450652439805877296207297446723295166658228846926807786652870188920867879451478364569313922060370695064736073572378695176473055266826253284886383715072974324463835300053138429460296575143368065570759537328128'));

# Search test
say "=> Perfect numbers bellow 10^4:";
for my $n (1 .. 10000) {
    is_even_perfect($n) && say $n;
}
