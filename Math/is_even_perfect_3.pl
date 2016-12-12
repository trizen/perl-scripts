#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 12 December 2016
# https://github.com/trizen

# An efficient verification for an even perfect number.

use 5.010;
use strict;
use warnings;

use Math::BigNum qw(:constant);
use ntheory qw(is_mersenne_prime valuation);

sub is_even_perfect {
    my ($n) = @_;
    my $v1 = valuation($n, 2) || return 0;
    my $m = 1 + ($n >> $v1);
    my $v2 = valuation($m, 2);
    $v2 == $v1 + 1            || return 0;
    ($m >> $v2) == 1          || return 0;
    is_mersenne_prime($v2);
}

say is_even_perfect(191561942608236107294793378084303638130997321548169216);                           # true
say is_even_perfect(191561942608236107294793378084303638130997321548169214);                           # false
say is_even_perfect(191561942608236107294793378084303638130997321548169218);                           # false
say is_even_perfect(14474011154664524427946373126085988481573677491474835889066354349131199152128);    # true

# A much larger perfect number
say is_even_perfect(Math::BigNum->new('141053783706712069063207958086063189881486743514715667838838675999954867742652380114104193329037690251561950568709829327164087724366370087116731268159313652487450652439805877296207297446723295166658228846926807786652870188920867879451478364569313922060370695064736073572378695176473055266826253284886383715072974324463835300053138429460296575143368065570759537328128'));

# Search test
say "=> Perfect numbers bellow 10^4:";
for my $n (1 .. 10000) {
    is_even_perfect($n) && say $n;
}
