#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 January 2016
# Website: https://github.com/trizen

# A basic approximation for the number of primes less than or equal with `n`
# based on the zeta function. More precisely, on the value of ζ(2).

# The formula is:
#
#   pi(2) = 1
#   pi(n) = pi(n-1) + log(ζ(2)) / (log10(^n) + log(1 / (1 - n^(-2))))
#
# where log10(^n) is the common logarithm of the initial "n".

# It's based on the fact that:
#             ∞
# log(ζ(s)) = Σ (π(n) - π(n-1)) * log(1 / (1 - n^(-s)))
#            n=2

use 5.010;
use strict;
use warnings;

no warnings 'recursion';
use ntheory qw(prime_count);

my $lz = log(1.64493406684822643647241516664602518922);    # log(ζ(2))

sub pi {
    my ($n, $lb) = @_;

    return 0 if $n <= 1;
    return 1 if $n == 2;

    pi($n - 1, $lb) + ($lz / ($lb + log(1 / (1 - $n**(-2)))));
}

for (my $i = 10 ; $i <= 3000 ; $i += 100) {
    printf("pi(%4d) =~ %4s   (actual: %4s)\n", $i, int(pi($i, log($i) / log(10))), prime_count($i));
}

__END__
pi(  10) =~    4   (actual:    4)
pi( 110) =~   27   (actual:   29)
pi( 210) =~   45   (actual:   46)
pi( 310) =~   62   (actual:   63)
pi( 410) =~   78   (actual:   80)
pi( 510) =~   94   (actual:   97)
pi( 610) =~  109   (actual:  111)
pi( 710) =~  124   (actual:  127)
pi( 810) =~  139   (actual:  140)
pi( 910) =~  153   (actual:  155)
pi(1010) =~  167   (actual:  169)
pi(1110) =~  182   (actual:  186)
pi(1210) =~  196   (actual:  197)
pi(1310) =~  209   (actual:  214)
pi(1410) =~  223   (actual:  223)
pi(1510) =~  237   (actual:  239)
pi(1610) =~  250   (actual:  254)
pi(1710) =~  263   (actual:  267)
pi(1810) =~  277   (actual:  279)
pi(1910) =~  290   (actual:  292)
pi(2010) =~  303   (actual:  304)
pi(2110) =~  316   (actual:  317)
pi(2210) =~  329   (actual:  329)
pi(2310) =~  342   (actual:  343)
pi(2410) =~  355   (actual:  357)
pi(2510) =~  368   (actual:  368)
pi(2610) =~  380   (actual:  379)
pi(2710) =~  393   (actual:  394)
pi(2810) =~  406   (actual:  409)
pi(2910) =~  418   (actual:  421)
