#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 October 2017
# https://github.com/trizen

# Find all the positive solutions to the quadratic congruence: x^2 = -1 (mod n), where `n` is known.

# See also:
#   https://en.wikipedia.org/wiki/Quadratic_residue

use 5.010;
use strict;
use warnings;

use Set::Product::XS qw(product);
use ntheory qw(sqrtmod factor_exp chinese mulmod);

sub solve_quadratic_congruence {
    my ($n) = @_;

    my %table;
    foreach my $f (factor_exp($n)) {
        my $pp = $f->[0]**$f->[1];
        my $r = sqrtmod($pp - 1, $pp) || return;
        push @{$table{$pp}}, [$r, $pp], [$pp - $r, $pp];
    }

    my %solutions;

    product {
        undef $solutions{chinese(@_)};
    } values %table;

    return sort { $a <=> $b } keys %solutions;
}

foreach my $n (1 .. 1e5) {
    (my @solutions = solve_quadratic_congruence($n)) || next;

    say "x^2 = -1 (mod $n); x = { ", join(', ', @solutions), ' }';

    # Verify solutions
    foreach my $solution (@solutions) {
        if (mulmod($solution, $solution, $n) != $n - 1) {
            die "error for $n: $solution\n";
        }
    }
}

__END__
x^2 = -1 (mod 99850); x = { 29543, 46343, 53507, 70307 }
x^2 = -1 (mod 99853); x = { 4298, 34107, 65746, 95555 }
x^2 = -1 (mod 99857); x = { 316, 16054, 83803, 99541 }
x^2 = -1 (mod 99865); x = { 6763, 33183, 66682, 93102 }
x^2 = -1 (mod 99874); x = { 42617, 57257 }
x^2 = -1 (mod 99877); x = { 10118, 89759 }
x^2 = -1 (mod 99881); x = { 19913, 79968 }
x^2 = -1 (mod 99901); x = { 34569, 65332 }
x^2 = -1 (mod 99905); x = { 447, 4217, 14227, 17997, 20428, 24198, 34208, 37978, 61927, 65697, 75707, 79477, 81908, 85678, 95688, 99458 }
x^2 = -1 (mod 99914); x = { 48155, 51759 }
x^2 = -1 (mod 99917); x = { 17457, 19894, 80023, 82460 }
x^2 = -1 (mod 99929); x = { 28615, 71314 }
x^2 = -1 (mod 99937); x = { 6962, 11069, 88868, 92975 }
x^2 = -1 (mod 99961); x = { 37804, 62157 }
x^2 = -1 (mod 99965); x = { 5412, 45398, 54567, 94553 }
x^2 = -1 (mod 99970); x = { 707, 19287, 26853, 46847, 53123, 73117, 80683, 99263 }
x^2 = -1 (mod 99973); x = { 14119, 25170, 74803, 85854 }
x^2 = -1 (mod 99977); x = { 16545, 36384, 63593, 83432 }
x^2 = -1 (mod 99985); x = { 2302, 37692, 62293, 97683 }
x^2 = -1 (mod 99986); x = { 11031, 88955 }
x^2 = -1 (mod 99989); x = { 23040, 76949 }
x^2 = -1 (mod 99994); x = { 18245, 48879, 51115, 81749 }
