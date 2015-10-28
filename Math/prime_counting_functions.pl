#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 19 September 2015
# Website: https://github.com/trizen

#
## Compare some prime counting functions.
#

# Li(n) = https://en.wikipedia.org/wiki/Logarithmic_integral_function
# R(n) = https://en.wikipedia.org/wiki/Prime-counting_function#Formulas_for_prime-counting_functions
# F(n) = n^2 / ln(n!)

use 5.010;
use utf8;
use strict;
use warnings;

use bigint (try => 'GMP');
use ntheory qw(prime_count LogarithmicIntegral RiemannR);

binmode(STDOUT, ':utf8');

foreach my $n (1 .. 15) {
    my $x = 10**$n;

    my $p  = prime_count($x);
    my $r  = int(RiemannR($x));
    my $li = int(LogarithmicIntegral($x));
    my $f  = $x->copy->bpow(2)->bdiv($x->bfac->blog);

    printf "%2d. π=%-10s R=%-10s Li=%-10s F=%-10s R-π=%-10s Li-π=%-10s F-π=%s\n", $n, $p, $r, $li, $f, $r - $p, $li - $p,
      $f - $p;
}

__END__
 1. π=4          R=4          Li=6          F=6          R-π=0          Li-π=2          F-π=2
 2. π=25         R=25         Li=30         F=27         R-π=0          Li-π=5          F-π=2
 3. π=168        R=168        Li=177        F=169        R-π=0          Li-π=9          F-π=1
 4. π=1229       R=1226       Li=1246       F=1217       R-π=-3         Li-π=17         F-π=-12
 5. π=9592       R=9587       Li=9629       F=9512       R-π=-5         Li-π=37         F-π=-80
 6. π=78498      R=78527      Li=78627      F=78030      R-π=29         Li-π=129        F-π=-468
 7. π=664579     R=664667     Li=664918     F=661458     R-π=88         Li-π=339        F-π=-3121
