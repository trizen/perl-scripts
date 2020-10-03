#!/usr/bin/perl

# A nice algorithm, due to David A. Corneth (Jun 06 2014), for interating over palindromic numbers in base 10.

# See also:
#   https://oeis.org/A002113
#   https://en.wikipedia.org/wiki/Palindromic_number

# This program illustrates how to compute terms of:
#   https://oeis.org/A076886

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

my $n = 1;
my @d = split(//, $n);

my %table;

while (1) {

    my $r = prime_bigomega($n);

    if (not exists $table{$r}) {
        say "a($r) = $n";
        $table{$r} = 1;
    }

    my $l = $#d;
    my $i = ((scalar(@d) + 1) >> 1) - 1;

    while ($i >= 0 and $d[$i] == 9) {
        $d[$i] = 0;
        $d[$l - $i] = 0;
        $i--;
    }

    if ($i >= 0) {
        $d[$i]++;
        $d[$l - $i] = $d[$i];
    }
    else {
        @d = (0) x (scalar(@d) + 1);
        $d[0]  = 1;
        $d[-1] = 1;
    }

    $n = join('', @d);
}
