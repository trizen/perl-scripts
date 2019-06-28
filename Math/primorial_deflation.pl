#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 April 2019
# https://github.com/trizen

# Represent a given number as a product of primorials (if possible).

# The sequence of numbers that can be represented as a product of primorials, is given by:
#   https://oeis.org/A025487

# Among other terms, the sequence includes the factorials and the highly composite numbers.

# See also:
#   https://oeis.org/A181815 -- "primorial deflation" of A025487(n)
#   https://oeis.org/A108951 -- "primorial inflation" of n

use 5.020;
use strict;
use warnings;

use experimental qw(signatures declared_refs);

use ntheory qw(factor factor_exp prev_prime);
use Math::AnyNum qw(factorial primorial prod ipow);

sub primorial_deflation ($n) {

    my @terms;

    while ($n > 1) {

        my $g = (factor($n))[-1];
        my $p = primorial($g);

        $n /= $p;
        $n->is_int || return undef;

        push @terms, $g;
    }

    return prod(@terms);
}

sub primorial_deflation_fast ($n) {

    my @p;

    foreach my \@pp (factor_exp($n)) {
        my ($p, $e) = @pp;
        push @p, ($p == 2) ? 1 : ipow(prev_prime($p), $e);
    }

    $n / prod(@p);
}

my @arr = map { primorial_deflation(factorial($_)) } 0 .. 15;    # https://oeis.org/A307035

say join ', ', @arr;                                                   #=> 1, 1, 2, 3, 12, 20, 60, 84, 672, 1512, 5040, 7920, 47520, 56160, 157248
say join ', ', map { prod(map { primorial($_) } factor($_)) } @arr;    #=> 1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880, 3628800, 39916800, 479001600, 6227020800, 87178291200

my @test = map { primorial_deflation_fast(factorial($_)) } 0 .. 15;

if ("@arr" ne "@test") {
    die "error: (@arr) != (@test)";
}

say join ', ', map { primorial_deflation_fast($_) } 1..20;      # A319626 / A319627

my $n = Math::AnyNum->new("14742217487368791965347653720647452690286549052234444179664342042930370966727413549068727214664401976854238590421417268673037399536054005777393104248210539172848500736334237168727231561710827753972114334247396552090671649834020135652920430241738510495400044737265204738821393451152066370913670083496651044937158497896720493198891148968218874744806522767468280764179516341996273430700779982929787918221844760577694188288275419541410142336911631623319041967633591283303769044016192030492715535641753600000");

say primorial_deflation($n);        #=> 52900585920
say primorial_deflation_fast($n);   #=> 52900585920
