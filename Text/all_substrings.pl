#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 April 2015
# website: http://github.com/trizen

# Find all the possible substrings of a string. (creative solution)

use 5.012;
use strict;
use warnings;

sub all_substrings {
    my ($str, $callback) = @_;

    my @cache;
    my @chars = split(//, $str);
    while (my ($i, $c) = each @chars) {
        $cache[$_] .= $c for (0 .. $i);
        $callback->(@cache);
    }

    return;
}

all_substrings("abcdefg", sub { say for @_ });
