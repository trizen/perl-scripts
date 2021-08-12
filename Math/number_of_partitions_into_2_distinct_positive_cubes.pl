#!/usr/bin/perl

# Count the number of partitions of n into 2 distinct positive cubes.

# See also:
#   https://oeis.org/A025468
#   https://cs.uwaterloo.ca/journals/JIS/VOL6/Broughan/broughan25.pdf

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

# Number of solutions to `n = a^3 + b^3, with 0 < a < b.
sub r2_cubes_positive_distinct ($n) {

    my $count = 0;

    foreach my $d (divisors($n)) {

        my $l = $d*$d - $n/$d;
        ($l % 3 == 0) || next;
        my $t = $d*$d - 4*($l/3);

        if ($d*$d*$d >= $n and $d*$d*$d <= 4 * $n and $l >= 3 and $t > 0 and is_square($t)) {
            ++$count;
        }
    }

    return $count;
}

foreach my $n (1 .. 100) {
    print(r2_cubes_positive_distinct($n), ", ");
}

__END__
0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
