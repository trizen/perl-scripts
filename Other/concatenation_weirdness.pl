#!/usr/bin/perl

# Weird order of concatenation of variables, when the variables are mutated during concatenation.

# In older versions of Perl, the first statement correctly returns "abc".
# In newer versions of Perl, both statements return incorrect values.

use 5.010;
use strict;
use warnings;

my $x = 'a';
my $y = 'b';

say ($x . $y . ++$y);       #=> expected "abc", but got "acc"
say ($x . ++$x);            #=> expected "ab", but got "bb"
