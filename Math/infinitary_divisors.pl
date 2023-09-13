#!/usr/bin/perl

# Author: Trizen
# Date: 13 September 2023
# https://github.com/trizen

# Generate the infinitary divisors (or i-divisors) of n.

# See also:
#   https://oeis.org/A049417
#   https://oeis.org/A077609

use 5.036;
use ntheory qw(:all);

sub infinitary_divisors ($n) {

    my @d = (1);

    foreach my $pp (factor_exp($n)) {
        my ($p, $e) = @$pp;

        my @t;
        my $r = 1;
        foreach my $j (1 .. $e) {
            $r = mulint($r, $p);
            if (($e & $j) == $j) {
                push @t, map { mulint($r, $_) } @d;
            }
        }
        push @d, @t;
    }

    return sort { $a <=> $b } @d;
}

foreach my $n (1 .. 20) {
    my @idivisors = infinitary_divisors($n);
    say "i-divisors of $n: [@idivisors]";
}

__END__
i-divisors of 1: [1]
i-divisors of 2: [1 2]
i-divisors of 3: [1 3]
i-divisors of 4: [1 4]
i-divisors of 5: [1 5]
i-divisors of 6: [1 2 3 6]
i-divisors of 7: [1 7]
i-divisors of 8: [1 2 4 8]
i-divisors of 9: [1 9]
i-divisors of 10: [1 2 5 10]
i-divisors of 11: [1 11]
i-divisors of 12: [1 3 4 12]
i-divisors of 13: [1 13]
i-divisors of 14: [1 2 7 14]
i-divisors of 15: [1 3 5 15]
i-divisors of 16: [1 16]
i-divisors of 17: [1 17]
i-divisors of 18: [1 2 9 18]
i-divisors of 19: [1 19]
i-divisors of 20: [1 4 5 20]
