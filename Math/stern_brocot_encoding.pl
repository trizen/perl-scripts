#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 February 2018
# https://github.com/trizen

# Encode a given fraction into an integer, using the Stern-Brocot tree.

# The decoding function decodes a given integer back into a fraction.

# See also:
#   https://en.wikipedia.org/wiki/Stern%E2%80%93Brocot_tree

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload abs);

sub stern_brocot_encode ($r) {

    my ($m, $n) = abs($r)->nude;

    my $enc = '';

    for (; ;) {
        if ((($m <=> $n) || last) < 0) {
            $enc .= '0';
            $n -= $m;
        }
        else {
            $enc .= '1';
            $m -= $n;
        }
    }

    return $enc;
}

sub stern_brocot_decode ($e) {

    my ($a, $b, $c, $d) = (1, 0, 0, 1);

    foreach my $bit (split(//, $e)) {
        if ($bit) {
            $a += $b;
            $c += $d;
        }
        else {
            $b += $a;
            $d += $c;
        }
    }

    ($c + $d) / ($a + $b);
}

say stern_brocot_encode(5 / 7);      # 0110
say stern_brocot_encode(43 / 97);    # 001110111111111
say stern_brocot_encode(97 / 43);    # 110001000000000

say '';

say stern_brocot_decode(stern_brocot_encode(5 / 7));      # 5/7
say stern_brocot_decode(stern_brocot_encode(43 / 97));    # 43/97
say stern_brocot_decode(stern_brocot_encode(97 / 43));    # 97/43

say "\n=> Tests:";

foreach my $n (1 .. 10) {

    my $f = Math::AnyNum::factorial($n);
    say "dec($n!) = ", stern_brocot_decode($f->as_bin);

    die "[0] error for dec($n!)" if (Math::AnyNum->new(stern_brocot_encode(stern_brocot_decode($f->as_bin)), 2) != $f);

    my $r1 = Math::AnyNum::fibonacci($n) / Math::AnyNum::lucas($n);
    die "[1] error for $r1" if (stern_brocot_decode(stern_brocot_encode($r1)) != $r1);

    my $r2 = Math::AnyNum::lucas($n) / $n**2;
    die "[2] error for $r2" if (stern_brocot_decode(stern_brocot_encode($r2)) != $r2);
}
