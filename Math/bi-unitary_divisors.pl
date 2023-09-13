#!/usr/bin/perl

# Author: Trizen
# Date: 13 September 2023
# https://github.com/trizen

# Generate the bi-unitary divisors of n.

# See also:
#   https://oeis.org/A188999
#   https://oeis.org/A222266

use 5.036;
use ntheory qw(:all);

sub gcud (@list) {  # greatest common unitary divisor

    my $g = gcd(@list);

    foreach my $n (@list) {
        next if ($n == 0);
        while (1) {
            my $t = gcd($g, divint($n, $g));
            last if ($t == 1);
            $g = divint($g, $t);
        }
        last if ($g == 1);
    }

    return $g;
}

sub bi_unitary_divisors ($n) {

    my @d = (1);

    foreach my $pp (factor_exp($n)) {
        my ($p, $e) = @$pp;

        my @t;
        my $r = 1;
        foreach my $j (1 .. $e) {
            $r = mulint($r, $p);
            if (gcud($r, divint($n, $r)) == 1) {
                push @t, map { mulint($r, $_) } @d;
            }
        }
        push @d, @t;
    }

    return sort { $a <=> $b } @d;
}

foreach my $n (1 .. 20) {
    my @biudivisors = bi_unitary_divisors($n);
    say "bi-udivisors of $n: [@biudivisors]";
}

__END__
bi-udivisors of 1: [1]
bi-udivisors of 2: [1 2]
bi-udivisors of 3: [1 3]
bi-udivisors of 4: [1 4]
bi-udivisors of 5: [1 5]
bi-udivisors of 6: [1 2 3 6]
bi-udivisors of 7: [1 7]
bi-udivisors of 8: [1 2 4 8]
bi-udivisors of 9: [1 9]
bi-udivisors of 10: [1 2 5 10]
bi-udivisors of 11: [1 11]
bi-udivisors of 12: [1 3 4 12]
bi-udivisors of 13: [1 13]
bi-udivisors of 14: [1 2 7 14]
bi-udivisors of 15: [1 3 5 15]
bi-udivisors of 16: [1 2 8 16]
bi-udivisors of 17: [1 17]
bi-udivisors of 18: [1 2 9 18]
bi-udivisors of 19: [1 19]
bi-udivisors of 20: [1 4 5 20]
