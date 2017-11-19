#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 November 2017
# https://github.com/trizen

# Floor and ceil functions, implemented using closed-form Fourier series.

# See also:
#   https://en.wikipedia.org/wiki/Floor_and_ceiling_functions#Continuity_and_series_expansions

use 5.020;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload tau pi e log2 ilog2);

sub floor ($x) {
    $x + (i * (log(1 - exp(tau * i * $x)) - log(exp(-tau * i * $x) * (-1 + exp(tau * i * $x))))) / tau - 1/2;
}

sub ceil ($x) {
    $x + (i * (log(1 - exp(tau * i * $x)) - log(exp(-tau * i * $x) * (-1 + exp(tau * i * $x))))) / tau + 1/2;
}

say floor(8.95);    #=> 8
say ceil(8.95);     #=> 9

say floor(18.3);    #=> 18
say ceil(18.3);     #=> 19

#
## Test with Vacca's formula for Euler-Mascheroni constant
#

# See also:
#   https://en.wikipedia.org/wiki/Euler%E2%80%93Mascheroni_constant#Series_expansions

my $sum0 = 0.0;
my $sum1 = 0.0;
my $sum2 = 0.0;
my $sum3 = 0.0;

foreach my $n (2 .. 10000) {
    $sum0 += (-1)**$n * ilog2($n) / $n;
    $sum1 += (-1)**$n * floor(log2($n + 1/2)) / $n;
    $sum2 += (-1)**$n * (tau * log($n + 1/2) - log(2) * (i*log(1 - (2*$n+1)**(-(tau*i) / (log(2)))) - i*log(1 - (2*$n+1)**((tau*i) / (log(2)))) + pi)) / (pi * log(4) * $n);
    $sum3 += (-1)**$n * (tau * log($n) - log(2) * (i*log(1 - $n**(-(tau*i) / (log(2)))) - i*log(1 - $n**((tau*i) / (log(2)))) + pi)) / (pi * log(4) * $n);
}

say $sum0;    #=> 0.577804596003519592136242513827950669265457764297
say $sum1;    #=> 0.577804596003519592136242513827950669265457764297-2.10816560532506695800025812910971220454909391515e-60i
say $sum2;    #=> 0.577804596003519592136242513827950669265457764297
say $sum3;    #=> 0.577804596003520848567920428074451834158559906352
