#!/usr/bin/perl

# Author: Trizen
# Date: 27 April 2022
# https://github.com/trizen

# A decently efficient algorithm for computing `binomial(n, k) mod m`, where `k` is small (<~ 10^6).

# Implemented using the identity:
#    binomial(n, k) = Product_{r = n-k+1..n}(r) / k!

# See also:
#   https://en.wikipedia.org/wiki/Lucas%27s_theorem

use 5.020;
use strict;
use warnings;

use List::Util qw(uniq);
use experimental qw(signatures);

use ntheory qw(
    mulmod factor_exp vecsum todigits powint
    chinese divint forfactored modint valuation
    is_square_free
);

sub factorial_power ($n, $p) {
    divint($n - vecsum(todigits($n, $p)), $p - 1);
}

sub modular_binomial_small_k ($n, $k, $m) {

    my %kp;
    my $prod = 1;

    forfactored {

        my $r       = $_;
        my @factors = uniq(@_);

        foreach my $p (@factors) {

            if ($p <= $k) {
                next if ((my $t = ($kp{$p} //= factorial_power($k, $p))) == 0);

                my $v = valuation($r, $p);

                if ($v >= $t) {
                    $v = $t;
                    $kp{$p} = 0;
                }
                else {
                    $kp{$p} -= $v;
                }

                $r = divint($r, powint($p, $v));
                last if ($r == 1);
            }
            else {
                last;
            }
        }

        $prod = mulmod($prod, $r, $m);
    } $n - $k + 1, $n;

    return $prod;
}

sub lucas_theorem ($n, $k, $p) {

    if ($n < $k) {
        return 0;
    }

    my $res = 1;

    while ($k > 0) {
        my ($Nr, $Kr) = (modint($n, $p), modint($k, $p));

        if ($Nr < $Kr) {
            return 0;
        }

        ($n, $k) = (divint($n, $p), divint($k, $p));
        $res = mulmod($res, modular_binomial_small_k($Nr, $Kr, $p), $p);
    }

    return $res;
}

sub modular_binomial ($n, $k, $m) {

    is_square_free($m)
        || return modular_binomial_small_k($n, $k, $m);

    my @congruences;

    foreach my $pp (factor_exp($m)) {
        my ($p, $e) = @$pp;

        my $pk = powint($p, $e);

        if ($e == 1) {
            push @congruences, [lucas_theorem($n, $k, $p), $p];
        }
        else {
            push @congruences, [modular_binomial_small_k($n, $k, $pk), $pk];
        }
    }

    chinese(@congruences);
}

say modular_binomial(12,   5,   100000);     #=> 792
say modular_binomial(16,   4,   100000);     #=> 1820
say modular_binomial(100,  50,  139);        #=> 71
say modular_binomial(1000, 10,  1243);       #=> 848
say modular_binomial(124,  42,  1234567);    #=> 395154
say modular_binomial(1e9,  1e4, 1234567);    #=> 833120
say modular_binomial(1e10, 1e5, 1234567);    #=> 589372
say modular_binomial(1e10, 1e6, 1234567);    #=> 456887
