#!/usr/bin/perl

# Perl bug when using recursion in a `my sub {}` with a parent function.

use 5.014;
use strict;
use warnings;

# Discovered by catb0t:
#   https://github.com/catb0t/multifactor/commit/d2a8ad217704182f3b71557aa81a1a62f0ea2414

sub factorial {
    my ($n) = @_;

    my sub my_func {
        my ($n) = @_;
        $n <= 1 ? 1 : $n * factorial($n - 1);
    }

    my_func($n);
}

say factorial(5);

__END__
Can't undef active subroutine at bug.pl line 17.
