#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 December 2017
# https://github.com/trizen

# A new algorithm for computing number of connected permutations of [1..n].

# See also:
#   http://oeis.org/A003319

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload factorial binomial);

sub number_of_connected_permutations {
    my ($n) = @_;

    my @P = (1);

    foreach my $i (1 .. $n) {
        foreach my $k (0 .. $i - 1) {
            $P[$i] += $P[$k] / binomial($i, $k+1);
        }
    }

    map { $P[$_] * factorial($_) } 0 .. $#P;
}

my @P = number_of_connected_permutations(20);

foreach my $i (0 .. $#P) {
    say "P($i) = $P[$i]";
}

__END__
P(0) = 1
P(1) = 1
P(2) = 3
P(3) = 13
P(4) = 71
P(5) = 461
P(6) = 3447
P(7) = 29093
P(8) = 273343
P(9) = 2829325
P(10) = 31998903
P(11) = 392743957
P(12) = 5201061455
P(13) = 73943424413
P(14) = 1123596277863
P(15) = 18176728317413
P(16) = 311951144828863
P(17) = 5661698774848621
P(18) = 108355864447215063
P(19) = 2181096921557783605
P(20) = 46066653228356851631
