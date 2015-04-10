#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 April 2015
# http://github.com/trizen

# The prime41() function.
# Inspired from: https://www.youtube.com/watch?v=3K-12i0jclM

# See more about this on: http://en.wikipedia.org/wiki/Formula_for_primes

use 5.010;
use strict;
use warnings;

use ntheory qw(is_prime divisors);

#
## A general form of: n^2 - n + 41
#
sub p41 {
    my ($x, $y) = @_;

    # $x: Nth number in the sequence
    # $y: position in the sequence relative to 41

    ## Simple:
    # $x**2 - $x + 41;

    ## General:
    $x**2 + (2 * $x * $y) - $x + $y**2 - $y + 41;
}

foreach my $i (0 .. 100) {
    my $n = p41($i, 1);

    if (is_prime($n)) {
        say "$i. $n - prime";
    }
    else {
        say "$i. $n - not prime (factors: ", join(', ', grep { $_ != 1 and $_ != $n } divisors($n)), ")";
    }
}

__END__
=> Deduced from:
43^2-2 = 1847 - prime
44^2-3 = 1933 - prime
45^2-4 = 2021 - not prime (factors: 43, 47)
46^2-5 = 2111 - prime
47^2-6 = 2203 - prime
48^2-7 = 2297 - prime
49^2-8 = 2393 - prime
50^2-9 = 2491 - not prime (factors: 47, 53)
51^2-10 = 2591 - prime
52^2-11 = 2693 - prime
53^2-12 = 2797 - prime
54^2-13 = 2903 - prime
55^2-14 = 3011 - prime
56^2-15 = 3121 - prime
57^2-16 = 3233 - not prime (factors: 53, 61)
58^2-17 = 3347 - prime
59^2-18 = 3463 - prime
60^2-19 = 3581 - prime
61^2-20 = 3701 - prime
62^2-21 = 3823 - prime
63^2-22 = 3947 - prime
64^2-23 = 4073 - prime
65^2-24 = 4201 - prime
