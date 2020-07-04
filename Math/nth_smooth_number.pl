#!/usr/bin/perl

# Generate the n-th smooth number that is the product of a given subset of primes.

# See also:
#   https://en.wikipedia.org/wiki/Smooth_number

use 5.020;
use warnings;

use ntheory qw(vecmin);
use experimental qw(signatures);

sub smooth_generator ($primes) {

    my @s = map { [1] } @$primes;

    sub {
        my $n = vecmin(map { $_->[0] } @s);

        for my $i (0..$#$primes) {
            shift(@{$s[$i]}) if ($s[$i][0] == $n);
            push(@{$s[$i]}, $n*$primes->[$i]);
        }
        return $n;
    };
}

sub nth_smooth_number($n, $primes) {
    my $g = smooth_generator($primes);
    $g->() for (1..$n-1);
    $g->();
}

say nth_smooth_number( 12, [2,7,13,19]);
say nth_smooth_number( 25, [2,5,7,11,13,23,29,31,53,67,71,73,79,89,97,107,113,127,131,137]);
say nth_smooth_number(500, [7,19,29,37,41,47,53,59,61,79,83,89,101,103,109,127,131,137,139,157,167,179,181,199,211,229,233,239,241,251]);
