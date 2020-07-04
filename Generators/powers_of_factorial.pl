#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2016
# Website: https://github.com/trizen

# A shortcut algorithm for finding the prime powers of n!
# without computing the n-factorial in the first place.

# Example:
#  6! is equal with: 2^4 * 3^2 * 5

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(forprimes vecsum todigits);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub factorial_powers ($n) {

    my $p = 0;
    my @powers;

    forprimes {
        if ($p == 1) {
            push @powers, $_;
        }
        else {
            push @powers, ($p = factorial_power($n, $_)) == 1 ? $_ : "$_^$p";
        }
    } $n;

    @powers ? join(' * ', @powers) : '1';
}

for (0 .. 25) {
    say "$_! = ", factorial_powers($_);
}

__END__
0! = 1
1! = 1
2! = 2
3! = 2 * 3
4! = 2^3 * 3
5! = 2^3 * 3 * 5
6! = 2^4 * 3^2 * 5
7! = 2^4 * 3^2 * 5 * 7
8! = 2^7 * 3^2 * 5 * 7
9! = 2^7 * 3^4 * 5 * 7
10! = 2^8 * 3^4 * 5^2 * 7
11! = 2^8 * 3^4 * 5^2 * 7 * 11
12! = 2^10 * 3^5 * 5^2 * 7 * 11
13! = 2^10 * 3^5 * 5^2 * 7 * 11 * 13
14! = 2^11 * 3^5 * 5^2 * 7^2 * 11 * 13
15! = 2^11 * 3^6 * 5^3 * 7^2 * 11 * 13
16! = 2^15 * 3^6 * 5^3 * 7^2 * 11 * 13
17! = 2^15 * 3^6 * 5^3 * 7^2 * 11 * 13 * 17
18! = 2^16 * 3^8 * 5^3 * 7^2 * 11 * 13 * 17
19! = 2^16 * 3^8 * 5^3 * 7^2 * 11 * 13 * 17 * 19
20! = 2^18 * 3^8 * 5^4 * 7^2 * 11 * 13 * 17 * 19
21! = 2^18 * 3^9 * 5^4 * 7^3 * 11 * 13 * 17 * 19
22! = 2^19 * 3^9 * 5^4 * 7^3 * 11^2 * 13 * 17 * 19
23! = 2^19 * 3^9 * 5^4 * 7^3 * 11^2 * 13 * 17 * 19 * 23
24! = 2^22 * 3^10 * 5^4 * 7^3 * 11^2 * 13 * 17 * 19 * 23
25! = 2^22 * 3^10 * 5^6 * 7^3 * 11^2 * 13 * 17 * 19 * 23
