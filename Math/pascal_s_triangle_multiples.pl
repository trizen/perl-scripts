#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 November 2015
# Website: https://github.com/trizen

# Pascal's triangle with the multiples of a given integer highlighted.

use 5.010;
use strict;
use warnings;

use ntheory qw(binomial);
use Term::ANSIColor qw(colored);

my $div  = 3;     # highlight multiples of this integer
my $size = 80;    # the size of the triangle

sub pascal {
    my ($rows) = @_;

    for my $n (1 .. $rows - 1) {
        say ' ' x ($rows - $n), join "",
          map { $_ % $div == 0 ? colored('.', 'red') : '*' }
          map { binomial(2*$n, $_) } 0 .. 2*$n;
    }
}

pascal(int($size / 2));
