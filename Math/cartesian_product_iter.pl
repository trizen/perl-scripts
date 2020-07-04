#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 23 April 2017
# https://github.com/trizen

# Iterative algorithm for computing the Cartesian product.

# Algorithm from:
#   http://stackoverflow.com/a/10947389

use 5.016;
use warnings;

sub cartesian(&@) {
    my ($callback, @arrs) = @_;

    my ($more, @lengths);

    foreach my $arr (@arrs) {
        my $end = $#{$arr};

        if ($end >= 0) {
            $more ||= 1;
        }
        else {
            $more = 0;
            last;
        }

        push @lengths, $end;
    }

    my @temp;
    my @indices = (0) x @arrs;

    while ($more) {
        @temp = @indices;

        for (my $i = $#indices ; $i >= 0 ; --$i) {
            if ($indices[$i] == $lengths[$i]) {
                $indices[$i] = 0;
                $more = 0 if $i == 0;
            }
            else {
                ++$indices[$i];
                last;
            }
        }

        $callback->(map { $_->[CORE::shift(@temp)] } @arrs);
    }
}

cartesian {
    say "@_";
} (['a', 'b'], ['c', 'd', 'e'], ['f', 'g']);
