#!/usr/bin/perl

# Author: Trizen
# Date: 16 December 2013
# Edit: 06 December 2023
# https://github.com/trizen

# Sorting algorithm: insertion sort + binary search = binsertion sort

use 5.036;
use strict;
use warnings;

sub bsearch_ge ($left, $right, $callback) {

    my ($mid, $cmp);

    for (; ;) {

        $mid = ($left + $right) >> 1;
        $cmp = $callback->($mid) || return $mid;

        if ($cmp < 0) {
            $left = $mid + 1;

            if ($left > $right) {
                $mid += 1;
                last;
            }
        }
        else {
            $right = $mid - 1;
            $left > $right and last;
        }
    }

    return $mid;
}

sub binsertion_sort {
    my (@list) = @_;

    foreach my $i (1 .. $#list) {
        if ((my $k = $list[$i]) < $list[$i - 1]) {
            splice(@list, $i, 1);
            splice(@list, bsearch_ge(0, $i - 1, sub ($j) { $list[$j] <=> $k }), 0, $k);
        }
    }

    return @list;
}

#
## MAIN
#

use List::Util qw(shuffle);

my @list = (shuffle((1 .. 100) x 2))[0 .. 50];

say "Before: ", join(' ', @list);
say "After:  ", join(' ', binsertion_sort(@list));

my @sorted = sort { $a <=> $b } @list;

join(' ', binsertion_sort(@list)) eq join(' ', @sorted)           or die "error";
join(' ', binsertion_sort(@sorted)) eq join(' ', @sorted)         or die "error";
join(' ', binsertion_sort(reverse @sorted)) eq join(' ', @sorted) or die "error";
