#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 February 2019
# https://github.com/trizen

# A simple integer factorization method, using square root convergents.

# See also:
#   https://en.wikipedia.org/wiki/Pell%27s_equation

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub pell_factorization ($n) {

    my $x = sqrtint($n);
    my $y = $x;
    my $z = 1;
    my $r = 2 * $x;
    my $w = $r;

    return $n if is_prime($n);
    return $x if is_square($n);

    my ($f1, $f2) = (1, $x);

    for (; ;) {

        $y = $r*$z - $y;
        $z = divint($n - $y*$y, $z);
        $r = divint($x + $y, $z);

        ($f1, $f2) = ($f2, addmod(mulmod($r, $f2, $n), $f1, $n));

        if (is_square($z)) {
            my $g = gcd($f1 - sqrtint($z), $n);
            if ($g > 1 and $g < $n) {
                return $g;
            }
        }

        return $n if ($z == 1);
    }
}

for (1 .. 10) {
    my $n = random_nbit_prime(31) * random_nbit_prime(31);
    say "PellFactor($n) = ", pell_factorization($n);
}

__END__
PellFactor(2101772756469048319) = 1228264087
PellFactor(2334333625703344609) = 1709282917
PellFactor(2358058220132276317) = 1210584887
PellFactor(1482285997261862561) = 1197377617
PellFactor(2759217719449375403) = 1559110667
PellFactor(2828146117168463857) = 1493774729
PellFactor(1732707024229573211) = 1165003451
PellFactor(2510049724431882299) = 1820676019
PellFactor(1585505630716792319) = 1311005599
PellFactor(1612976091192715981) = 1453708381
