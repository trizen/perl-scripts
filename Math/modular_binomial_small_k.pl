#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 September 2017
# Website: https://github.com/trizen

# A decently efficient algorithm for computing `binomial(n, k) mod m`, where `k` is small (<~ 10^6).

# Implemented using the identity:
#    binomial(n, k) = Product_{r = n-k+1..n}(r) / k!

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(mulmod factor_exp vecsum todigits);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub modular_binomial ($n, $k, $m) {

    my %kp;
    my $prod = 1;

  OUTER: foreach my $r ($n - $k + 1 .. $n) {

        foreach my $pair (factor_exp($r)) {
            my ($p, $v) = @$pair;

            if ($p <= $k) {
                next if ((my $t = ($kp{$p} //= factorial_power($k, $p))) == 0);

                if ($v >= $t) {
                    $v = $t;
                    $kp{$p} = 0;
                }
                else {
                    $kp{$p} -= $v;
                }

                next OUTER if (($r /= $p**$v) == 1);
            }
            else {
                last;
            }
        }

        $prod = mulmod($prod, $r, $m);
    }

    return $prod;
}

say modular_binomial(12,   5,   100000);     #=> 792
say modular_binomial(16,   4,   100000);     #=> 1820
say modular_binomial(100,  50,  139);        #=> 71
say modular_binomial(1000, 10,  1243);       #=> 848
say modular_binomial(124,  42,  1234567);    #=> 395154
say modular_binomial(1e9,  1e4, 1234567);    #=> 833120
say modular_binomial(1e10, 1e5, 1234567);    #=> 589372
