#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 23 June 2016
# Website: https://github.com/trizen

# Rationalized summation of fractions, based on the identity:
#
#  a     c     ad + bc
# --- + --- = ----------
#  b     d       bd

# Combining this method with memoization, results in a practical
# generalized algorithm for summation of arbitrary fractions.

# In addition, with this method, any infinite sum can be converted into a limit.

# Example:                ∞
#            f(n)        ---  1
#  lim    ----------  =  \   ----  = e
#  n->∞      _n_         /    n!
#            | | k!      ---
#            k=0         n=0
#
# where:                     _n_
#   f(n+1) = (n+1)! * f(n) + | | k!
#                            k=0
#   f(0)   = 1
#
#====================================================
#
# Generally:
#
#   x
#  ---
#  \    a(n)       f(x)
#   -  ------  =  ------
#  /    b(n)       g(x)
#  ---
#  n=0
#
# where:
# | f(0) = a(0)
# | f(n) = b(n) * f(n-1) + a(n) * g(n-1)
#
# and:
# | g(0) = b(0)
# | g(n) = b(n) * g(n-1)

use 5.010;
use strict;
use warnings;

use Memoize qw(memoize);
use Math::AnyNum qw(:overload factorial);

memoize('b');
memoize('f');
memoize('g');

my $start = 0;     # start iteration from this value
my $iter  = 90;    # number of iterations

sub a {
    2**$_[0];
}

sub b {
    factorial($_[0]);
}

sub f {
    my ($n) = @_;
    $n <= $start
      ? a($n)
      : b($n) * f($n - 1) + a($n) * g($n - 1);
}

sub g {
    my ($n) = @_;
    $n <= $start
      ? b($n)
      : b($n) * g($n - 1);
}

my $x = f($iter) / g($iter);
say $x;
say "e^2 =~ ", $x->as_dec(64);
