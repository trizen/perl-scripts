#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 June 2017
# Edit: 28 August 2023
# https://github.com/trizen

# Inverse of Bernoulli numbers, based on the inverse of the following asymptotic formula:
#   |Bn| ~ 2 / (2*pi)^n * n!

# Using Stirling's approximation for n!, we have:
#   |Bn| ~ 2 / (2*pi)^n * sqrt(2*pi*n) * (n/e)^n

# This gives us the following inverse formula:
#   n ~ lgrt((|Bn| / (4*pi))^(1/(2*pi*e))) * 2*pi*e - 1/2

# Where `lgrt(n)` is defined as:
#   lgrt(x^x) = x

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload tau e LambertW lgrt log bernreal);

sub inv_bern_W ($n) {
    my $L = log($n / 2) - log(tau);
    $L / LambertW($L / (tau * e)) - 1 / 2;
}

sub inv_bern_lgrt ($n) {
    lgrt(($n / (2 * tau))**(1 / (e * tau))) * e * tau - 1 / 2;
}

my $x = abs(bernreal(1000000));

say inv_bern_W($x);       #=> 999999.999999996521295786570230337488233833193417
say inv_bern_lgrt($x);    #=> 999999.999999996521295786570230337488233833193417
