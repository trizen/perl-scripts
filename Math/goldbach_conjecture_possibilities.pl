#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 July 2015
# Website: https://github.com/trizen

# Calculate the number of combinations for the Goldbach conjecture
# for all the numbers ranging between the two exponents of e.

# As it seems, the number of combinations increases,
# with each power and it seems to go towards infinity.

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes is_prime);

my ($n, $log, %table);
foreach my $i (1 .. exp(10) / 2) {
    $n   = 2 * $i;
    $log = int(log($n));
    forprimes {
        is_prime($n - $_)
          && ++$table{$log};
    }
    ($n - 2);
}

use Data::Dump qw(pp);
pp \%table;

__END__

{
  1  => 2,
  2  => 22,
  3  => 109,
  4  => 558,
  5  => 2883,
  6  => 15523,
  7  => 85590,
  8  => 484304,
  9  => 2819301,
  10 => 16797271,
  11 => 101959227,
}
