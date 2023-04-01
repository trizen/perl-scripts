#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 August 2021
# https://github.com/trizen

# Sub-linear formula for computing the partial sum of the k-powerfree part of numbers <= n.

# See also:
#   https://oeis.org/A007913 -- Squarefree part of n: a(n) is the smallest positive number m such that n/m is a square.
#   https://oeis.org/A050985 -- Cubefree part of n.
#   https://oeis.org/A069891 -- a(n) = Sum_{k=1..n} A007913(k), the squarefree part of k.

use 5.036;
use ntheory qw(divint addint mulint powint rootint factor_exp vecprod vecsum);

sub T ($n) {    # n-th triangular number
    divint(mulint($n, addint($n, 1)), 2);
}

sub powerfree_part ($n, $k = 2) {
    return 0 if ($n == 0);
    vecprod(map { powint($_->[0], $_->[1] % $k) } factor_exp($n));
}

sub f ($n, $r) {
    vecprod(map { 1 - powint($_->[0], $r) } factor_exp($n));
}

sub powerfree_part_sum ($n, $k = 2) {
    my $sum = 0;
    for (1 .. rootint($n, $k)) {
        $sum = addint($sum, mulint(f($_, $k), T(divint($n, powint($_, $k)))));
    }
    return $sum;
}

foreach my $k (2 .. 10) {
    printf("Sum of %2d-powerfree part of numbers <= 10^j: {%s}\n", $k,
           join(', ', map { powerfree_part_sum(powint(10, $_), $k) } 0 .. 7));
}

use Test::More tests => 10;

foreach my $k (1..10) {
    my $n = 100;

    is_deeply(
        [map { powerfree_part_sum($_, $k) } 1..$n],
        [map { vecsum(map { powerfree_part($_, $k) } 1..$_) } 1..$n],
    );
}

__END__
Sum of  2-powerfree part of numbers <= 10^j: {1, 38, 3233, 328322, 32926441, 3289873890, 328984021545, 32898872196712}
Sum of  3-powerfree part of numbers <= 10^j: {1, 48, 4341, 423422, 42307792, 4231510721, 423168867323, 42316819978538}
Sum of  4-powerfree part of numbers <= 10^j: {1, 55, 4655, 464251, 46382816, 4638539465, 463852501943, 46385283123175}
Sum of  5-powerfree part of numbers <= 10^j: {1, 55, 4864, 482704, 48270333, 4826777870, 482672975112, 48267321925901}
Sum of  6-powerfree part of numbers <= 10^j: {1, 55, 4987, 492212, 49167065, 4916054515, 491597851229, 49159726433201}
Sum of  7-powerfree part of numbers <= 10^j: {1, 55, 5050, 496944, 49591853, 4958924582, 495890504497, 49589026540242}
Sum of  8-powerfree part of numbers <= 10^j: {1, 55, 5050, 498970, 49799540, 4979820070, 497977273243, 49797721800745}
Sum of  9-powerfree part of numbers <= 10^j: {1, 55, 5050, 499989, 49907910, 4989989560, 499000372993, 49899962707231}
Sum of 10-powerfree part of numbers <= 10^j: {1, 55, 5050, 500500, 49958965, 4995128633, 499504727624, 49950367771436}
