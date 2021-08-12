#!/usr/bin/perl

# Count the number partitions of n into 2 nonnegative cubes.

# See also:
#   https://oeis.org/A025446
#   https://cs.uwaterloo.ca/journals/JIS/VOL6/Broughan/broughan25.pdf

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub r2_cubes_partitions($n) {

    my $L = rootint($n-1, 3) + 1;
    my $U = rootint(4*$n, 3);

    my $count = 0;

    foreach my $m (divisors($n)) {
        if ($L <= $m and $m <= $U) {
            my $l = $m*$m - $n/$m;
            $l % 3 == 0 or next;
            $l /= 3;
            is_square($m*$m - 4*$l) && ++$count;
        }
    }

    return $count;
}

foreach my $n (1 .. 100) {
    print(r2_cubes_partitions($n), ", ");
}

__END__
1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
