#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 25 June 2026
# https://github.com/trizen

# A sublinear algorithm with O(sqrt(n)) complexity for computing the partial-sums of the `usigma_j(k)` function:
#
#   Sum_{k=1..n} usigma_j(k)
#
# for any integer j >= 0.

use 5.036;
use Math::GMPz;
use Math::Prime::Util 0.74 qw(:all);

prime_set_config(bigint => 'Math::GMPz');

sub sigma_sum ($n, $m = 1) {    # using the Dirichlet hyperbola method

    my $total = 0;
    my $s     = sqrtint($n);

    for my $k (1 .. $s) {
        $total = addint($total, powersum(divint($n, $k), $m));
        $total = addint($total, mulint(powint($k, $m), divint($n, $k)));
    }

    $total = subint($total, mulint($s, powersum($s, $m)));

    return $total;
}

sub usigma_sum ($n, $j = 1) {

    my $s  = sqrtint($n);
    my $ss = sqrtint($s);

    my @M = (0);
    my @F = (0);

    for my $k (1 .. $s) {
        my $t = mulint(moebius($k), ($j == 1 ? $k : powint($k, $j)));
        push @F, $t;
        push @M, addint($M[-1], $t);
    }

    my $A = 0;
    for my $k (1 .. $ss) {
        $A = addint($A, mulint($F[$k], sigma_sum(divint($n, $k * $k), $j)));
    }

    my $B = 0;
    for my $k (1 .. $s) {
        $B = addint($B, mulint(divisor_sum($k, $j), $M[sqrtint(divint($n, $k))]));
    }

    return subint(addint($A, $B), mulint(sigma_sum($s, $j), $M[$ss]));
}

my $k = 1;
foreach my $n (1 .. 10) {    # takes ~0.6s seconds
    say "S(10^$n, $k) = ", usigma_sum(powint(10, $n), $k);
}

__END__
S(10^1, 1) = 76
S(10^2, 1) = 6889
S(10^3, 1) = 684578
S(10^4, 1) = 68425910
S(10^5, 1) = 6842185909
S(10^6, 1) = 684216736806
S(10^7, 1) = 68421643171218
S(10^8, 1) = 6842163918226589
S(10^9, 1) = 684216389063572134
S(10^10, 1) = 68421638885063570894
