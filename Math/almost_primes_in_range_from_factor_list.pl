#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 17 March 2023
# https://github.com/trizen

# Generate all the possible k-almost primes in a given range [A, B], using a given list of prime factors.

use 5.020;
use ntheory      qw(:all);
use experimental qw(signatures);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub almost_primes_in_range ($A, $B, $k, $factors, $squarefree = 0) {

    $A = vecmax($A, ($squarefree ? pn_primorial($k) : powint(2, $k)));

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

        foreach my $j ($i .. ($factors_end - $squarefree)) {
            my $q = $factors->[$j];
            last if ($q > $hi);
            next if ($q < $lo);
            __SUB__->(mulint($m, $q), $k - 1, $j + $squarefree);
        }
      }
      ->(1, $k);

    sort { $a <=> $b } @list;
}

my $from    = 1;
my $upto    = 1e3;
my @factors = @{primes(11)};    # prime list

foreach my $k (0 .. scalar(@factors)) {
    my @divisors = almost_primes_in_range($from, $upto, $k, \@factors);
    printf("%2d-almost primes in range [%s, %s]: [%s]\n", $k, $from, $upto, join(', ', @divisors));
}

__END__
 0-almost primes in range [1, 1000]: [1]
 1-almost primes in range [1, 1000]: [2, 3, 5, 7, 11]
 2-almost primes in range [1, 1000]: [4, 6, 9, 10, 14, 15, 21, 22, 25, 33, 35, 49, 55, 77, 121]
 3-almost primes in range [1, 1000]: [8, 12, 18, 20, 27, 28, 30, 42, 44, 45, 50, 63, 66, 70, 75, 98, 99, 105, 110, 125, 147, 154, 165, 175, 231, 242, 245, 275, 343, 363, 385, 539, 605, 847]
 4-almost primes in range [1, 1000]: [16, 24, 36, 40, 54, 56, 60, 81, 84, 88, 90, 100, 126, 132, 135, 140, 150, 189, 196, 198, 210, 220, 225, 250, 294, 297, 308, 315, 330, 350, 375, 441, 462, 484, 490, 495, 525, 550, 625, 686, 693, 726, 735, 770, 825, 875]
 5-almost primes in range [1, 1000]: [32, 48, 72, 80, 108, 112, 120, 162, 168, 176, 180, 200, 243, 252, 264, 270, 280, 300, 378, 392, 396, 405, 420, 440, 450, 500, 567, 588, 594, 616, 630, 660, 675, 700, 750, 882, 891, 924, 945, 968, 980, 990]
