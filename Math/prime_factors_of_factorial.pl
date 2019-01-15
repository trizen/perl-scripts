#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 July 2016
# https://github.com/trizen

# A shortcut algorithm for finding the factors of n!
# without computing the factorial in the first place.

# Example:
#    6! =  2^4  *  3^2  *  5^1

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(forprimes vecsum todigits);

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

sub factorial_prime_powers ($n) {
    my @pp;

    forprimes {
        push @pp, [$_, factorial_power($n, $_)];
    } $n;

    return @pp;
}

for my $n (2 .. 20) {
    my @pp = factorial_prime_powers($n);
    printf("%2s! = %s\n", $n, join(' * ', map { sprintf("%2d^%-2d", $_->[0], $_->[1]) } @pp));
}

__END__
 2! =  2^1
 3! =  2^1  *  3^1
 4! =  2^3  *  3^1
 5! =  2^3  *  3^1  *  5^1
 6! =  2^4  *  3^2  *  5^1
 7! =  2^4  *  3^2  *  5^1  *  7^1
 8! =  2^7  *  3^2  *  5^1  *  7^1
 9! =  2^7  *  3^4  *  5^1  *  7^1
10! =  2^8  *  3^4  *  5^2  *  7^1
11! =  2^8  *  3^4  *  5^2  *  7^1  * 11^1
12! =  2^10 *  3^5  *  5^2  *  7^1  * 11^1
13! =  2^10 *  3^5  *  5^2  *  7^1  * 11^1  * 13^1
14! =  2^11 *  3^5  *  5^2  *  7^2  * 11^1  * 13^1
15! =  2^11 *  3^6  *  5^3  *  7^2  * 11^1  * 13^1
16! =  2^15 *  3^6  *  5^3  *  7^2  * 11^1  * 13^1
17! =  2^15 *  3^6  *  5^3  *  7^2  * 11^1  * 13^1  * 17^1
18! =  2^16 *  3^8  *  5^3  *  7^2  * 11^1  * 13^1  * 17^1
19! =  2^16 *  3^8  *  5^3  *  7^2  * 11^1  * 13^1  * 17^1  * 19^1
20! =  2^18 *  3^8  *  5^4  *  7^2  * 11^1  * 13^1  * 17^1  * 19^1
