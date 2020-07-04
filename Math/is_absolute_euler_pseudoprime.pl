#!/usr/bin/perl

# Check if a given number is an absolute Euler pseudoprime.

# These are composite n such that abs(a^((n-1)/2) mod n) = 1 for all a with gcd(a,n) = 1.

# See also:
#   https://oeis.org/A033181 -- Absolute Euler pseudoprimes
#   https://en.wikipedia.org/wiki/Euler_pseudoprime

use 5.014;
use ntheory qw(:all);
use experimental qw(signatures);

sub is_absolute_euler_pseudoprime ($n) {
    is_carmichael($n)
        and vecall { (($n-1)>>1) % ($_-1) == 0 } factor($n);
}

foroddcomposites {
    say $_ if is_absolute_euler_pseudoprime($_);
} 1e6;
