#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 June 2019
# https://github.com/trizen

# Find the greatest divisor (mod m) of `n` that does not exceed the square root of `n`.

# See also:
#   https://projecteuler.net/problem=266

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub pseudo_square_root_mod ($n, $mod) {

    my $lim     = sqrtint($n);
    my @factors = map { [$_, log($_)] } grep { $_ <= $lim } factor($n);

    my @d        = ([1, 0]);
    my $sqrt_log = log("$n") / 2;

    my %seen;
    while (my $p = shift(@factors)) {
        my @t;
        foreach my $d (@d) {
            if ($p->[1] + $d->[1] <= $sqrt_log) {
                push @t, [mulmod($p->[0], $d->[0], $mod), $p->[1] + $d->[1]];
            }
        }
        push @d, @t;
    }

    my $max_log = 0;
    my $max_div = 0;

    foreach my $d (@d) {
        if ($d->[1] > $max_log) {
            $max_div = $d->[0];
            $max_log = $d->[1];
        }
    }

    return $max_div;
}

say pseudo_square_root_mod(479001600,   10**16);    #=> 21600
say pseudo_square_root_mod(6469693230,  10**16);    #=> 79534
say pseudo_square_root_mod(12398712476, 10**16);    #=> 68

say pseudo_square_root_mod('614889782588491410',              10**8);     #=> 83152070
say pseudo_square_root_mod('3217644767340672907899084554130', 10**16);    #=> 1793779293633437
