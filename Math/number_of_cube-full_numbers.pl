#!/usr/bin/perl

# Fast algorithm for counting the number of cube-full numbers <= n.
# A positive integer n is considered cube-full, if for every prime p that divides n, so does p^3.

# See also:
#   THE DISTRIBUTION OF CUBE-FULL NUMBERS, by P. SHIU (1990).

# OEIS:
#   https://oeis.org/A036966 -- 3-full (or cube-full, or cubefull) numbers: if a prime p divides n then so does p^3.

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub cubefull_count($n) {
    my $total = 0;

    for my $a (1 .. rootint($n, 5)) {
        for my $b (1 .. rootint(divint($n, powint($a, 5)), 4)) {
            my $t = mulint(powint($a, 5), powint($b, 4));
            if (gcd($a, $b) == 1 and is_square_free($a) and is_square_free($b)) {
                $total += rootint(divint($n, $t), 3);
            }
        }
    }

    return $total;
}

foreach my $n (1 .. 20) {
    say "C_3(10^$n) = ", cubefull_count(powint(10, $n));
}

__END__
C_3(10^1) = 2
C_3(10^2) = 7
C_3(10^3) = 20
C_3(10^4) = 51
C_3(10^5) = 129
C_3(10^6) = 307
C_3(10^7) = 713
C_3(10^8) = 1645
C_3(10^9) = 3721
C_3(10^10) = 8348
C_3(10^11) = 18589
C_3(10^12) = 41136
C_3(10^13) = 90619
C_3(10^14) = 198767
C_3(10^15) = 434572
C_3(10^16) = 947753
C_3(10^17) = 2062437
C_3(10^18) = 4480253
C_3(10^19) = 9718457
C_3(10^20) = 21055958
