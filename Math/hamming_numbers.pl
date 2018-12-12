#!/usr/bin/perl

# Generate the generalized Hamming numbers bellow a certain limit, given a set of primes.

use 5.020;
use warnings;
use experimental qw(signatures);

sub hamming_numbers ($limit, $primes) {

    my @h = (1);
    foreach my $p (@$primes) {
        foreach my $n (@h) {
            if ($n * $p <= $limit) {
                push @h, $n * $p;
            }
        }
    }

    return \@h;
}

# Example: 5-smooth numbers bellow 100
my $h = hamming_numbers(100, [2, 3, 5]);
say join(', ', sort { $a <=> $b } @$h);
