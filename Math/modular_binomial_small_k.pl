#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 September 2017
# Website: https://github.com/trizen

# A decently efficient algorithm for computing `binomial(n, k) mod m`, where `k` is small (<~ 10^6).

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes mulmod factor_exp);

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

  OUTER: foreach my $r ($n - $k + 1 .. $n) {

        foreach my $pair (factor_exp($r)) {
            if (exists($div{$pair->[0]})) {
                my ($p, $v) = @$pair;

                if ($v >= $div{$p}) {
                    $v = delete($div{$p});
                }
                else {
                    $div{$p} -= $v;
                }

                next OUTER if (($r /= $p**$v) == 1);
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
