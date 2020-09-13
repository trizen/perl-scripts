#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 October 2017
# https://github.com/trizen

# Find (almost) all the positive solutions to the quadratic congruence: x^2 = a (mod n), where `n` and `a` are known.

# For finding all the solutions for the special case `a = 1`, see:
#   https://github.com/trizen/perl-scripts/blob/master/Math/solutions_to_x%5E2%20=%201%20(mod%20n).pl

# For finding all the solutions to `x^2 = a (mod n)`, see:
#   https://github.com/trizen/sidef-scripts/blob/master/Math/square_root_modulo_n.sf
#   https://github.com/trizen/sidef-scripts/blob/master/Math/square_root_modulo_n_tonelli-shanks.sf

# See also:
#   https://en.wikipedia.org/wiki/Quadratic_residue

use 5.010;
use strict;
use warnings;

use Set::Product::XS qw(product);
use ntheory qw(sqrtmod factor_exp chinese mulmod);

sub modular_square_root {
    my ($k, $n) = @_;

    my %table;
    foreach my $f (factor_exp($n)) {
        my $pp = $f->[0]**$f->[1];
        my $r = sqrtmod($k, $pp) || return;
        push @{$table{$pp}}, [$r, $pp], [$pp - $r, $pp];
    }

    my %solutions;

    product {
        undef $solutions{chinese(@_)};
    } values %table;

    return sort { $a <=> $b } keys %solutions;
}

foreach my $n (2 .. 1000) {

    my $k = 1+int(rand($n));
    (my @solutions = modular_square_root($k, $n)) || next;

    say "x^2 = $k (mod $n); x = { ", join(', ', @solutions), ' }';

    # Verify solutions
    foreach my $solution (@solutions) {
        if (mulmod($solution, $solution, $n) != $k) {
            die "error for $n: $solution\n";
        }
    }
}

__END__
x^2 =  81 (mod 863); x = { 9, 854 }
x^2 = 459 (mod 865); x = { 247, 272, 593, 618 }
x^2 = 535 (mod 873); x = { 70, 124, 749, 803 }
x^2 = 685 (mod 877); x = { 135, 742 }
x^2 = 388 (mod 879); x = { 55, 238, 641, 824 }
x^2 = 441 (mod 883); x = { 21, 862 }
x^2 = 813 (mod 886); x = { 195, 691 }
x^2 =  83 (mod 887); x = { 227, 660 }
x^2 = 757 (mod 898); x = { 245, 653 }
x^2 = 848 (mod 907); x = { 162, 745 }
x^2 = 259 (mod 919); x = { 190, 729 }
x^2 = 121 (mod 929); x = { 11, 918 }
x^2 = 737 (mod 934); x = { 175, 759 }
x^2 = 509 (mod 935); x = { 38, 72, 302, 412, 523, 633, 863, 897 }
x^2 = 831 (mod 937); x = { 101, 836 }
x^2 = 511 (mod 939); x = { 220, 406, 533, 719 }
x^2 = 841 (mod 940); x = { 29, 159, 311, 441, 499, 629, 781, 911 }
x^2 = 427 (mod 941); x = { 380, 561 }
x^2 = 606 (mod 943); x = { 355, 424, 519, 588 }
x^2 = 865 (mod 954); x = { 127, 233, 721, 827 }
x^2 = 886 (mod 963); x = { 43, 385, 578, 920 }
x^2 = 142 (mod 967); x = { 143, 824 }
x^2 = 547 (mod 982); x = { 283, 699 }
x^2 = 563 (mod 983); x = { 386, 597 }
x^2 = 565 (mod 991); x = { 245, 746 }
x^2 = 866 (mod 997); x = { 350, 647 }
