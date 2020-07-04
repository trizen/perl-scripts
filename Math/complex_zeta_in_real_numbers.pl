#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 August 2017
# https://github.com/trizen

# Computing the zeta function for a complex input, using only real numbers.

# Defined as:
#   zeta(a + b*i) = Sum_{n>=1} 1/n^(a + b*i)

# where we have the identity:
#   1/n^(a + b*i) = (cos(log(n) * b) - i*sin(log(n) * b)) / n**a

use 5.010;
use strict;
use warnings;

use experimental qw(signatures);

sub complex_zeta ($r = 1 / 2, $s = 14.134725142, $rep = 1e6) {

    my $real = 0;
    my $imag = 0;

    foreach my $n (1 .. $rep) {
        $real += cos(log($n) * $s) / $n**$r;
        $imag -= sin(log($n) * $s) / $n**$r;
    }

    return ($real, $imag);
}

my $r = 3;      # real part
my $s = 4;      # imaginary part

my ($real, $imag) = complex_zeta($r, $s);
say "zeta($r + $s*i) =~ complex($real, $imag)";    #=> complex(0.890554906959998, -0.0080759454242689)
