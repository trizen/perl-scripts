#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 August 2021
# https://github.com/trizen

# Sub-linear formula for computing the count of k-powerfree numbers <= n.

# See also:
#   https://oeis.org/A013928 -- Number of (positive) squarefree numbers < n.
#   https://oeis.org/A060431 -- Number of cubefree numbers <= n.
#   https://oeis.org/A071172 -- Number of squarefree integers <= 10^n.
#   https://oeis.org/A160112 -- Number of cubefree integers not exceeding 10^n.

use 5.020;
use strict;
use warnings;

use ntheory qw(vecall factor_exp powint divint forsquarefree rootint);
use experimental qw(signatures);

sub is_powerfree ($n, $k = 2) {
    (vecall { $_->[1] < $k } factor_exp($n)) ? 1 : 0;
}

sub powerfree_count ($n, $k = 2) {
    my $count = 0;
    forsquarefree {
        $count += ((scalar(@_) & 1) ? -1 : 1) * divint($n, powint($_, $k));
    } rootint($n, $k);
    return $count;
}

foreach my $k (2 .. 10) {
    printf("Number of %2d-powerfree numbers <= 10^j: {%s}\n", $k,
           join(', ', map { powerfree_count(powint(10, $_), $k) } 0 .. 10));
}

use Test::More tests => 10;

foreach my $k (1..10) {
    my $n = 100;

    is_deeply(
        [map { powerfree_count($_, $k) } 1..$n],
        [map { scalar grep { is_powerfree($_, $k) } 1..$_ } 1..$n],
    );
}

__END__
Number of  2-powerfree numbers <= 10^j: {1, 7, 61, 608, 6083, 60794, 607926, 6079291, 60792694, 607927124, 6079270942}
Number of  3-powerfree numbers <= 10^j: {1, 9, 85, 833, 8319, 83190, 831910, 8319081, 83190727, 831907372, 8319073719}
Number of  4-powerfree numbers <= 10^j: {1, 10, 93, 925, 9240, 92395, 923939, 9239385, 92393839, 923938406, 9239384029}
Number of  5-powerfree numbers <= 10^j: {1, 10, 97, 965, 9645, 96440, 964388, 9643874, 96438737, 964387341, 9643873409}
Number of  6-powerfree numbers <= 10^j: {1, 10, 99, 984, 9831, 98297, 982954, 9829527, 98295260, 982952591, 9829525925}
Number of  7-powerfree numbers <= 10^j: {1, 10, 100, 993, 9918, 99173, 991721, 9917199, 99171986, 991719856, 9917198560}
Number of  8-powerfree numbers <= 10^j: {1, 10, 100, 997, 9960, 99595, 995940, 9959393, 99593921, 995939202, 9959392012}
Number of  9-powerfree numbers <= 10^j: {1, 10, 100, 999, 9981, 99800, 997997, 9979956, 99799564, 997995634, 9979956329}
Number of 10-powerfree numbers <= 10^j: {1, 10, 100, 1000, 9991, 99902, 999008, 9990065, 99900642, 999006414, 9990064132}
