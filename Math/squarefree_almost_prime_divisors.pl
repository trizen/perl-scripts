#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 March 2021
# https://github.com/trizen

# Generate all the squarefree k-almost prime divisors of n.

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub squarefree_almost_prime_divisors ($n, $k) {

    if ($k == 0) {
        return (1);
    }

    my @factor_exp  = factor_exp($n);
    my @factors     = map { $_->[0] } @factor_exp;
    my %valuations  = map { @$_ } @factor_exp;
    my $factors_end = $#factors;

    if ($k == 1) {
        return @factors;
    }

    my @list;

    sub ($m, $k, $i = 0) {

        if ($k == 1) {

            my $L = divint($n, $m);

            foreach my $j ($i .. $factors_end) {

                my $q = $factors[$j];
                $q > $L and last;

                push(@list, mulint($m, $q));
            }

            return;
        }

        my $L = rootint(divint($n, $m), $k);

        foreach my $j ($i .. $factors_end - 1) {

            my $q = $factors[$j];
            $q > $L and last;

            __SUB__->(mulint($m, $q), $k - 1, $j + 1);
        }
    }->(1, $k);

    sort { $a <=> $b } @list;
}

my $n = vecprod(@{primes(15)});

foreach my $k (0 .. prime_omega($n)) {
    my @divisors = squarefree_almost_prime_divisors($n, $k);
    printf("%2d-squarefree almost prime divisors of %s: [%s]\n", $k, $n, join(', ', @divisors));
}

__END__
 0-squarefree almost prime divisors of 30030: [1]
 1-squarefree almost prime divisors of 30030: [2, 3, 5, 7, 11, 13]
 2-squarefree almost prime divisors of 30030: [6, 10, 14, 15, 21, 22, 26, 33, 35, 39, 55, 65, 77, 91, 143]
 3-squarefree almost prime divisors of 30030: [30, 42, 66, 70, 78, 105, 110, 130, 154, 165, 182, 195, 231, 273, 286, 385, 429, 455, 715, 1001]
 4-squarefree almost prime divisors of 30030: [210, 330, 390, 462, 546, 770, 858, 910, 1155, 1365, 1430, 2002, 2145, 3003, 5005]
 5-squarefree almost prime divisors of 30030: [2310, 2730, 4290, 6006, 10010, 15015]
 6-squarefree almost prime divisors of 30030: [30030]
