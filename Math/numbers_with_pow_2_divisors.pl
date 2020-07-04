#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 21 September 2016
# Website: https://github.com/trizen

# First smallest numbers with 2^n divisors.

# See also:
#    http://oeis.org/A037992
#    https://projecteuler.net/problem=500

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes primes logint);

sub first_n {
    my ($num) = @_;

    my $limit = logint($num, 2) * $num;    # overshoots a little bit
    my @factors = @{primes($limit)};

    forprimes {
        my $t = $_;
        while (($t**= 2) <= $limit) {
            push @factors, $t;
        }
    } $num;

    @factors = sort { $a <=> $b } @factors;
    $#factors = $num - 2;

    my @nums = 1;
    my $prod = 1;

    foreach my $f (@factors) {
        $prod *= $f;
        push @nums, $prod;
    }

    @nums;
}

say for first_n(10)

__END__
1
2
6
24
120
840
7560
83160
1081080
17297280
