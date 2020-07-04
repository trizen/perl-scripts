#!/usr/bin/perl

# Coded by Trizen
# Date: 14 May 2015
# http://github.com/trizen

use 5.010;
use strict;
use warnings;

# Inspired from: http://www.youtube.com/watch?v=DpwUVExX27E

#
## Create and return the sequence as an array
#
sub stern_brocot {
    my ($n) = @_;

    my @fib = (1, 1);
    foreach my $i (1 .. $n) {
        push @fib, $fib[$i] + $fib[$i - 1], $fib[$i];
    }
    return @fib;
}

say join(" ", stern_brocot(15));

#
## Print the sequence as it is generated
#
sub stern_brocot_realtime(&$) {
    my ($callback, $n) = @_;

    my @fib = (1, 1);
    foreach my $i (1 .. $n) {
        push @fib, $fib[0] + $fib[1], $fib[1];
        $callback->($fib[0]);
        shift @fib;
    }
    $callback->($_) for @fib;
}

{
    local $| = 1;
    my $i = 0;
    stern_brocot_realtime {
        my ($n) = @_;
        print "$n ";
    } 15;
}
print "\n";
