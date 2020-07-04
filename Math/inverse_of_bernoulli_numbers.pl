#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 June 2017
# https://github.com/trizen

# Inverse of Bernoulli numbers, based on the inverse of the following asymptotic formula:
#   |Bn| ~ 2 / (2*pi)^n * n!

# Using Stirling's approximation for n!, we have:
#   |Bn| ~ 2 / (2*pi)^n * sqrt(2*pi*n) * (n/e)^n

# This gives us the following inverse formula:
#   n ~ lgrt((2*pi)^(-1/(4*pi*e)) * (|Bn| / 2)^(1/(2*pi*e))) * 2*pi*e - 1/2

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload tau e LambertW lgrt log bernreal);

use constant S => log(sqrt(tau));
use constant T => tau**(-1/2 / e / tau);

sub inv_bern_W ($n) {
    my $L = log($n / 2) - S;
    $L / LambertW($L / tau / e) - 0.5;
}

sub inv_bern_lgrt ($n) {
    lgrt(T * ($n / 2)**(1 / e / tau)) * e * tau - 0.5;
}

my $x = abs(bernreal(1000000));

say inv_bern_W($x);         #=> 1000000.07672120297238023703521860508549747587329
say inv_bern_lgrt($x);      #=> 1000000.07672120297238023703521860508549747587329
