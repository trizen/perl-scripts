#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 17 May 2020
# https://github.com/trizen

# Algorithm for finding the length of the recurring cycle of 1/n in base b.

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub reciprocal_cycle_length ($n, $base = 10) {

    for (my $g = gcd($n, $base) ; $g > 1 ; $g = gcd($n, $base)) {
        $n /= $g;
    }

    ($n == 1) ? 0 : znorder($base, $n);
}

foreach my $n (1 .. 20) {
    my $r = reciprocal_cycle_length($n);
    say "1/$n has cycle length of $r";
}

__END__
1/1 has cycle length of 0
1/2 has cycle length of 0
1/3 has cycle length of 1
1/4 has cycle length of 0
1/5 has cycle length of 0
1/6 has cycle length of 1
1/7 has cycle length of 6
1/8 has cycle length of 0
1/9 has cycle length of 1
1/10 has cycle length of 0
1/11 has cycle length of 2
1/12 has cycle length of 1
1/13 has cycle length of 6
1/14 has cycle length of 6
1/15 has cycle length of 1
1/16 has cycle length of 0
1/17 has cycle length of 16
1/18 has cycle length of 1
1/19 has cycle length of 18
1/20 has cycle length of 0
