#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 15 January 2019
# https://github.com/trizen

# Efficient program for computing the sum of exponents in prime-power factorization of n!.

# See also:
#   https://oeis.org/A022559    -- Sum of exponents in prime-power factorization of n!.
#   https://oeis.org/A071811    -- Sum_{k <= 10^n} number of primes (counted with multiplicity) dividing k

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub sum_of_exponents_of_factorial ($n) {

    return 0 if ($n <= 1);

    my $s = sqrtint($n);
    my $u = divint($n, $s+1);

    my $total = 0;
    my $prev  = prime_power_count($n);

    for my $k (1 .. $s) {
        my $curr = prime_power_count(divint($n, ($k + 1)));
        $total += $k * ($prev - $curr);
        $prev = $curr;
    }

    forprimes {
        for (my $q = $_; $q <= $u; $q *= $_) {
            $total += divint($n, $q);
        }
    } $u;

    return $total;
}

sub sum_of_exponents_of_factorial_2 ($n) {

    my $s = sqrtint($n);
    my $total = 0;

    for my $k (1 .. $s) {
        $total += prime_power_count(divint($n,$k));
        $total += divint($n,$k) if is_prime_power($k);
    }

    $total -= prime_power_count($s) * $s;

    return $total;
}

foreach my $k (1 .. 11) {       # takes ~4s
    say "a(10^$k) = ", sum_of_exponents_of_factorial(powint(10,$k));
}

__END__
a(10^1)  = 15
a(10^2)  = 239
a(10^3)  = 2877
a(10^4)  = 31985
a(10^5)  = 343614
a(10^6)  = 3626619
a(10^7)  = 37861249
a(10^8)  = 392351272
a(10^9)  = 4044220058
a(10^10) = 41518796555
a(10^11) = 424904645958
a(10^12) = 4337589196099
a(10^13) = 44189168275565
