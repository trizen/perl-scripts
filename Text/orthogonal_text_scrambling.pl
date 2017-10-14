#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 July 2017
# https://github.com/trizen

# An interesting text scrambling algorithm, invented by the author in ~2008.

use 5.010;
use strict;
use warnings;

sub scramble {
    my ($str) = @_;

    my $i = length($str);
    $str =~ s/(.{$i})(.)/$2$1/sg while --$i > 0;
    return $str;
}

sub unscramble {
    my ($str) = @_;

    my $i = 0;
    my $l = length($str);
    $str =~ s/(.)(.{$i})/$2$1/sg while (++$i < $l);
    return $str;
}

my $abc = "abcdefghijklmnopqrstuvwxyz";

say scramble($abc);                #=> "fvjnabdsgrpzxqeholmictyuwk"
say unscramble(scramble($abc));    #=> "abcdefghijklmnopqrstuvwxyz"
