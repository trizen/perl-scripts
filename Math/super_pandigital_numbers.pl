#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 August 2017
# https://github.com/trizen

# Generate the smallest super-pandigital numbers that are simultaneously pandigital in all bases from 2 to n inclusively.

# Brute-force solution.

# See also:
#   # https://projecteuler.net/problem=571

use 5.010;
use strict;
use warnings;

use List::Util qw(uniq all min);
use ntheory qw(todigits fromdigits);
use Algorithm::Combinatorics qw(variations);

my $base = shift(@ARGV) // 10;    # pandigital in all bases 2..$base
my $first = 10;                   # generate first n numbers

my @digits = (
               1, 0,
               (2 .. min($base - 1, 9)),
               ($base > 10
                 ? ('a' .. chr(ord('a') + $base - 10 - 1))
                 : ()
               )
             );

my @bases = reverse(2 .. $base - 1);

my $sum = 0;
my $iter = variations(\@digits, $base);

while (defined(my $t = $iter->next)) {

    if ($t->[0] ne '0') {
        my $n = join('', @$t);
        my $d = fromdigits($n, $base);

        if (all { uniq(todigits($d, $_)) == $_ } @bases) {
            say "Found: $n -> $d";
            $sum += $d;
            last if --$first == 0;
        }
    }
}

say "Sum: $sum";

__END__

First 10 super-pandigital numbers in bases 2 up to 10:

1093265784
1367508924
1432598706
1624573890
1802964753
2381059764
2409758631
2578693140
2814609357
2814759360
