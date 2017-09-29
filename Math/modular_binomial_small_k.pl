#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 September 2017
# Website: https://github.com/trizen

# A decently efficient algorithm for computing `binomial(n, k) mod m`, where `k` is small (<~ 10^4).

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes valuation mulmod);

sub power {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    return $s;
}

sub modular_binomial {
    my ($n, $k, $m) = @_;

    my $prod = 1;

    my %div;
    forprimes {
        $div{$_} = power($k, $_);
    } $k;

    OUTER: foreach my $t ($n - $k + 1 .. $n) {
        foreach my $d (keys %div) {

            if ($t % $d == 0) {
                my $v = valuation($t, $d);

                if ($v >= $div{$d}) {
                    $v = delete($div{$d});
                }
                else {
                    $div{$d} -= $v;
                }

                next OUTER if ($t /= $d**$v) == 1;
            }
        }

        $prod = mulmod($prod, $t, $m);
    }

    return $prod;
}

say modular_binomial(12,   5,   100000);     #=> 792
say modular_binomial(16,   4,   100000);     #=> 1820
say modular_binomial(100,  50,  139);        #=> 71
say modular_binomial(1000, 10,  1243);       #=> 848
say modular_binomial(124,  42,  1234567);    #=> 395154
say modular_binomial(1e9,  1e4, 1234567);    #=> 833120
