#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 23 April 2017
# https://github.com/trizen

# Recursive algorithm for computing the Cartesian product.

# Algorithm from Math::Cartesian::Product
#   https://metacpan.org/pod/Math::Cartesian::Product

use 5.016;
use warnings;

sub cartesian(&@) {
    my ($callback, @C) = @_;
    my (@c, @r);

    sub {
        if (@c < @C) {
            for my $item (@{$C[@c]}) {
                CORE::push(@c, $item);
                __SUB__->();
                CORE::pop(@c);
            }
        }
        else {
            $callback->(@c);
        }
      }
      ->();
}

cartesian {
    say "@_";
} (['a', 'b'], ['c', 'd', 'e'], ['f', 'g']);
