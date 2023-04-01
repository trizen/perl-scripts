#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 August 2021
# https://github.com/trizen

# Sub-linear formula for computing the sum of the k-powerfree numbers <= n.

# See also:
#   https://oeis.org/A066779

use 5.036;
use ntheory qw(addint mulint divint powint rootint
               vecprod vecsum forsquarefree vecall factor_exp);

sub T ($n) {    # n-th triangular number
    divint(mulint($n, addint($n, 1)), 2);
}

sub is_powerfree ($n, $k = 2) {
    (vecall { $_->[1] < $k } factor_exp($n)) ? 1 : 0;
}

sub powerfree_sum ($n, $k = 2) {
    my $sum = 0;
    forsquarefree {
        $sum = addint($sum, vecprod(((scalar(@_) & 1) ? -1 : 1), powint($_, $k), T(divint($n, powint($_, $k)))));
    } rootint($n, $k);
    return $sum;
}

foreach my $k (2 .. 10) {
    printf("Sum of %2d-powerfree numbers <= 10^j: {%s}\n", $k,
           join(', ', map { powerfree_sum(powint(10, $_), $k) } 0 .. 10));
}

use Test::More tests => 10;

foreach my $k (1..10) {
    my $n = 100;

    is_deeply(
        [map { powerfree_sum($_, $k) } 1..$n],
        [map { vecsum(grep { is_powerfree($_, $k) } 1..$_) } 1..$n],
    );
}

__END__
Sum of  2-powerfree numbers <= 10^j: {1, 34, 2967, 303076, 30420034, 3039711199, 303961062910, 30396557311887, 3039633904822886, 303963567619632057, 30396354343039613622}
Sum of  3-powerfree numbers <= 10^j: {1, 47, 4264, 416150, 41586160, 4159363010, 415954865054, 41595434367696, 4159535757149773, 415953684178098104, 41595368549000401165}
Sum of  4-powerfree numbers <= 10^j: {1, 55, 4633, 462309, 46194572, 4619706557, 461968894786, 46196921076177, 4619691742903970, 461969203230753906, 46196920137396170242}
Sum of  5-powerfree numbers <= 10^j: {1, 55, 4858, 482198, 48222307, 4821980585, 482193364705, 48219363893896, 4821936891554962, 482193669861570387, 48219367054214757071}
Sum of  6-powerfree numbers <= 10^j: {1, 55, 4986, 492091, 49154917, 4914845614, 491476913298, 49147631895757, 4914762949966044, 491476293899695450, 49147629625656526116}
Sum of  7-powerfree numbers <= 10^j: {1, 55, 5050, 496916, 49588762, 4958620842, 495860136228, 49585989492140, 4958599241977593, 495859927007565418, 49585992797893696932}
Sum of  8-powerfree numbers <= 10^j: {1, 55, 5050, 498964, 49798759, 4979743960, 497969661841, 49796960766296, 4979696019857946, 497969600482512058, 49796960053175724454}
Sum of  9-powerfree numbers <= 10^j: {1, 55, 5050, 499988, 49907720, 4989970435, 498998466703, 49899772216835, 4989978143911393, 498997816910227655, 49899781642188970208}
Sum of 10-powerfree numbers <= 10^j: {1, 55, 5050, 500500, 49958920, 4995123879, 499504250712, 49950320120610, 4995032061303318, 499503206523627025, 49950320659515298125}
