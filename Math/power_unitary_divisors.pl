#!/usr/bin/perl

# Author: Trizen
# Date: 13 September 2023
# https://github.com/trizen

# Generate the k-th power unitary divisors of n.

# See also:
#   https://oeis.org/A056624

use 5.036;
use ntheory qw(:all);

sub power_udivisors ($n, $k = 1) {

    my @d = (1);

    foreach my $pp (factor_exp($n)) {
        my ($p, $e) = @$pp;

        if ($e % $k == 0) {
            my $u = powint($p, $e);
            push @d, map { mulint($_, $u) } @d;
        }
    }

    sort { $a <=> $b } @d;
}

say join(', ', power_udivisors(3628800, 1));    # unitary divisors
say join(', ', power_udivisors(3628800, 2));    # square unitary divisors
say join(', ', power_udivisors(3628800, 3));    # cube unitary divisors
say join(', ', power_udivisors(3628800, 4));    # 4th power unitary divisors

__END__
1, 7, 25, 81, 175, 256, 567, 1792, 2025, 6400, 14175, 20736, 44800, 145152, 518400, 3628800
1, 25, 81, 256, 2025, 6400, 20736, 518400
1
1, 81, 256, 20736
