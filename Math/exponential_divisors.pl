#!/usr/bin/perl

# Author: Trizen
# Date: 13 September 2023
# https://github.com/trizen

# Generate the exponential divisors (or e-divisors) of n.

# See also:
#   https://oeis.org/A051377
#   https://oeis.org/A322791

use 5.036;
use ntheory qw(:all);

sub exponential_divisors ($n) {

    my @d = (1);

    foreach my $pp (factor_exp($n)) {
        my ($p, $e) = @$pp;

        my @t;
        foreach my $k (divisors($e)) {
            my $r = powint($p, $k);
            push @t, map { mulint($r, $_) } @d;
        }
        @d = @t;
    }

    return sort { $a <=> $b } @d;
}

foreach my $n (1 .. 20) {
    my @edivisors = exponential_divisors($n);
    say "e-divisors of $n: [@edivisors]";
}

__END__
e-divisors of 1: [1]
e-divisors of 2: [2]
e-divisors of 3: [3]
e-divisors of 4: [2 4]
e-divisors of 5: [5]
e-divisors of 6: [6]
e-divisors of 7: [7]
e-divisors of 8: [2 8]
e-divisors of 9: [3 9]
e-divisors of 10: [10]
e-divisors of 11: [11]
e-divisors of 12: [6 12]
e-divisors of 13: [13]
e-divisors of 14: [14]
e-divisors of 15: [15]
e-divisors of 16: [2 4 16]
e-divisors of 17: [17]
e-divisors of 18: [6 18]
e-divisors of 19: [19]
e-divisors of 20: [10 20]
