#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 17 March 2023
# https://github.com/trizen

# Generate all the squarefree k-almost primes in a given range [A, B], using a given list of prime factors.

use 5.020;
use ntheory      qw(:all);
use experimental qw(signatures);

sub divceil ($x, $y) {    # ceil(x/y)
    my $q = divint($x, $y);
    (mulint($q, $y) == $x) ? $q : ($q + 1);
}

sub squarefree_almost_primes_in_range ($A, $B, $k, $factors) {

    $A = vecmax($A, pn_primorial($k));

    my $factors_end = $#{$factors};

    if ($k == 0) {
        return (($A > 1) ? () : 1);
    }

    my @list;

    sub ($m, $k, $i = 0) {

        my $lo = $factors->[$i];
        my $hi = rootint(divint($B, $m), $k);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            $lo = vecmax($lo, divceil($A, $m));

            if ($lo > $hi) {
                return;
            }

            foreach my $j ($i .. $factors_end) {
                my $q = $factors->[$j];
                last if ($q > $hi);
                next if ($q < $lo);
                push(@list, mulint($m, $q));
            }

            return;
        }

        foreach my $j ($i .. $factors_end - 1) {
            my $q = $factors->[$j];
            last if ($q > $hi);
            next if ($q < $lo);
            __SUB__->(mulint($m, $q), $k - 1, $j + 1);
        }
      }
      ->(1, $k);

    sort { $a <=> $b } @list;
}

my $from    = 1;
my $upto    = 1e6;
my @factors = @{primes(17)};    # prime list

foreach my $k (0 .. scalar(@factors)) {
    my @divisors = squarefree_almost_primes_in_range($from, $upto, $k, \@factors);
    printf("%2d-squarefree almost primes in range [%s, %s]: [%s]\n", $k, $from, $upto, join(', ', @divisors));
}

__END__
 0-squarefree almost primes in range [1, 1000000]: [1]
 1-squarefree almost primes in range [1, 1000000]: [2, 3, 5, 7, 11, 13, 17]
 2-squarefree almost primes in range [1, 1000000]: [6, 10, 14, 15, 21, 22, 26, 33, 34, 35, 39, 51, 55, 65, 77, 85, 91, 119, 143, 187, 221]
 3-squarefree almost primes in range [1, 1000000]: [30, 42, 66, 70, 78, 102, 105, 110, 130, 154, 165, 170, 182, 195, 231, 238, 255, 273, 286, 357, 374, 385, 429, 442, 455, 561, 595, 663, 715, 935, 1001, 1105, 1309, 1547, 2431]
 4-squarefree almost primes in range [1, 1000000]: [210, 330, 390, 462, 510, 546, 714, 770, 858, 910, 1122, 1155, 1190, 1326, 1365, 1430, 1785, 1870, 2002, 2145, 2210, 2618, 2805, 3003, 3094, 3315, 3927, 4641, 4862, 5005, 6545, 7293, 7735, 12155, 17017]
 5-squarefree almost primes in range [1, 1000000]: [2310, 2730, 3570, 4290, 5610, 6006, 6630, 7854, 9282, 10010, 13090, 14586, 15015, 15470, 19635, 23205, 24310, 34034, 36465, 51051, 85085]
 6-squarefree almost primes in range [1, 1000000]: [30030, 39270, 46410, 72930, 102102, 170170, 255255]
 7-squarefree almost primes in range [1, 1000000]: [510510]
