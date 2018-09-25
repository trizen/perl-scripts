#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 22 September 2018
# https://github.com/trizen

# A new algorithm for generating Fibonacci pseudoprimes.

# See also:
#   https://oeis.org/A081264 -- Odd Fibonacci pseudoprimes.
#   https://oeis.org/A212424 -- Frobenius pseudoprimes with respect to Fibonacci polynomial x^2 - x - 1.

# For more info, see:
#   https://trizenx.blogspot.com/2018/08/investigating-fibonacci-numbers-modulo-m.html

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::AnyNum qw(fibmod prod powmod);
use ntheory qw(forcomb forprimes kronecker divisors);

sub fibonacci_pseudoprimes ($limit, $callback) {

    my %common_divisors;

    forprimes {
        my $p = $_;
        foreach my $d (divisors($p - kronecker($p, 5))) {
            if (fibmod($d, $p) == 0) {
                push @{$common_divisors{$d}}, $p;
            }
        }
    } $limit;

    my %seen;

    foreach my $arr (values %common_divisors) {

        my $l = $#{$arr} + 1;

        foreach my $k (2 .. $l) {
            forcomb {
                my $n = prod(@{$arr}[@_]);
                $callback->($n, @{$arr}[@_]) if !$seen{$n}++;
            } $l, $k;
        }
    }
}

sub is_fibonacci_pseudoprime($n) {
    fibmod($n - kronecker($n, 5), $n) == 0;
}

my @pseudoprimes;

fibonacci_pseudoprimes(
    10_000,
    sub ($n, @f) {

        is_fibonacci_pseudoprime($n)
            or die "Not a Fibonacci pseudoprime: $n";

        #say join(' * ', @f), " = $n";
        push @pseudoprimes, $n;

        if (kronecker($n, 5) == -1) {
            if (powmod(2, $n - 1, $n) == 1) {
                die "Found a special pseudoprime: $n";
            }
        }
    }
);

@pseudoprimes = sort {$a <=> $b} @pseudoprimes;

say join(', ', @pseudoprimes);
