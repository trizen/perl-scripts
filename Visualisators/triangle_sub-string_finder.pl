#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 07 June 2014
# Website: http://github.com/trizen

# Triangle sub-string finder (concept only)
# - search a substring using a triangle like pattern,
#   starting in the middle of the string, continuing
#   going towards the string edges after each fail-match.

use 5.014;
use strict;
use warnings;

use Term::ANSIColor qw(colored);

sub triangle_finder {
    my ($s, $c) = @_;

    my $left  = 0;
    my $right = @{$c};

    my $min = length($s);
    my $mid = int($left + $right) / 2;

    my $acc = 0;
    for (my $m1 = $mid - $acc, my $m2 = $mid + $acc ;
         $m1 > $left && $m2 < $right ;
         $acc += $min, $m1 = $mid - $acc, $m2 = $mid + $acc) {

        #
        ## some code here that will perform the search in the left
        #

        say join('', @{$c}[0 .. $m1 - 1], colored($c->[$m1], 'red'), @{$c}[$m1 + 1 .. $#{$c}]);

        #
        ## some code here that will perform the search on the right
        #

        say join('', @{$c}[0 .. $m2 - 1], colored($c->[$m2], 'red'), @{$c}[$m2 + 1 .. $#{$c}]);
    }
}

my @chars = 'a' .. 'z';
triangle_finder('i', \@chars);
