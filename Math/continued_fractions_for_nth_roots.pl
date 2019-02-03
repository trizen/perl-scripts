#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 February 2019
# https://github.com/trizen

# Approximate n-th roots, using continued fractions.

# See also:
#   https://en.wikipedia.org/wiki/Generalized_continued_fraction#Roots_of_positive_numbers

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload irootrem);

sub cfrac_nth_root ($z, $m, $n, $y, $r, $k = 1) {

    return 0 if ($r <= 0);

    ($k**2 * $n**2 - $m**2) * $y**2 / (
        (2 * $k + 1) * $n * (2 * $z - $y) - __SUB__->($z, $m, $n, $y, $r - 1, $k + 1)
    );
}

sub nth_root ($z, $n, $r = 98) {
    my ($x, $y) = irootrem($z, $n);         # express z as x^n + y

    my $m = 1;
    my $t = cfrac_nth_root($z, $m, $n, $y, $r);

    $x**$m + ((2 * $x * $m * $y) / ($n * (2 * $z - $y) - $m * $y - $t));
}

say nth_root(1234,   2)->as_dec;    #=> 35.1283361405005916058703116253563067645404854788
say nth_root(12345,  3)->as_dec;    #=> 23.1116187498072686808719733295882901745171370026
say nth_root(123456, 5)->as_dec;    #=> 10.4304354640976648337531700856866384705501389373

say "\n=> Convergents for 2^(1/3):";

foreach my $k (1 .. 10) {
    say "   2^(1/3) =~ ", nth_root(2, 3, $k);
}

__END__
=> Convergents for 2^(1/3):
   2^(1/3) =~ 131/104
   2^(1/3) =~ 286/227
   2^(1/3) =~ 17494/13885
   2^(1/3) =~ 49147/39008
   2^(1/3) =~ 4725601/3750712
   2^(1/3) =~ 12205019/9687130
   2^(1/3) =~ 320084311/254051086
   2^(1/3) =~ 1829589323/1452146008
   2^(1/3) =~ 60779482705/48240707392
   2^(1/3) =~ 410233899668/325602861943
