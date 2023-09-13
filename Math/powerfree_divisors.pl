#!/usr/bin/perl

# Author: Trizen
# Date: 13 September 2023
# https://github.com/trizen

# Generate the k-powerfree divisors of a given number.

# See also:
#   https://oeis.org/A048250

use 5.036;
use ntheory qw(:all);

sub powerfree_divisors ($n, $k = 2) {

    my @d = (1);

    foreach my $pp (factor_exp($n)) {
        my ($p, $e) = @$pp;

        $e = vecmin($e, $k - 1);

        my @t;
        my $r = 1;
        for (1 .. $e) {
            $r = mulint($r, $p);
            push @t, map { mulint($r, $_) } @d;
        }
        push @d, @t;
    }

    return sort { $a <=> $b } @d;
}

say join(' ', powerfree_divisors(5040, 2));
say join(' ', powerfree_divisors(5040, 3));

__END__
1 2 3 5 6 7 10 14 15 21 30 35 42 70 105 210
1 2 3 4 5 6 7 9 10 12 14 15 18 20 21 28 30 35 36 42 45 60 63 70 84 90 105 126 140 180 210 252 315 420 630 1260
