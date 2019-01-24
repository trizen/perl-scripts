#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 December 2013
# Edit: 24 January 2019
# https://github.com/trizen

# Sorting algorithm: insertion sort + binary search = binsertion sort

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(bsearch_ge);

sub binsertion_sort {
    my (@list) = @_;

    foreach my $i (1 .. $#list) {
        if ((my $k = $list[$i]) < $list[$i - 1]) {
            splice(@list, $i, 1);
            splice(@list, bsearch_ge(0, $i - 1, sub { $list[$_] <=> $k }), 0, $k);
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
