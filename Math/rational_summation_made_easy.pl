#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 23 June 2016
# Website: https://github.com/trizen

# Rationalized summation of fractions, based on the principle:
#
#  a     c     ad + bc
# --- + --- = ----------
#  b     d       bd

# Combining this method with memoization, results a practical
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

use 5.014;
use strict;
use warnings;

use Memoize qw(memoize);
use Math::BigNum qw(:constant);

memoize('f');
memoize('b');
memoize('p');

my $init  = 1;     # initial value (e.g.: f(start))
my $start = 0;     # first value of n
my $iter  = 90;    # number of iterations

sub a { 1 }             # numerator
sub b { $_[0]->fac }    # denominator

sub f {
    my ($n) = @_;
    $n <= $start
      ? $init
      : b($n) * f($n - 1) + a($n) * p($n - 1);
}

sub p {
    my ($n) = @_;
    $n <= $start
      ? b($n)
      : b($n) * p($n - 1);
}

say f($iter) / p($iter);
