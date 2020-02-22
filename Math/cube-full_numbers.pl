#!/usr/bin/perl

# Fast algorithm for generating all the cube-full numbers <= n.
# A positive integer n is considered cube-full, if for every prime p that divides n, so does p^3.

# See also:
#   THE DISTRIBUTION OF CUBE-FULL NUMBERS, by P. SHIU (1990).

# OEIS:
#   https://oeis.org/A036966 -- 3-full (or cube-full, or cubefull) numbers: if a prime p divides n then so does p^3.

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub cubefull_numbers ($n) {    # cubefull numbers <= n

    my @cubeful;

    for my $a (1 .. rootint($n, 5)) {
        is_square_free($a) || next;
        for my $b (1 .. rootint(divint($n, powint($a, 5)), 4)) {
            gcd($a, $b) == 1 or next;
            is_square_free($b) || next;
            my $v = mulint(powint($a, 5), powint($b, 4));
            foreach my $c (1 .. rootint(divint($n, $v), 3)) {
                my $z = vecprod($v, $c, $c, $c);
                push @cubeful, $z;
            }
        }
    }

    sort { $a <=> $b } @cubeful;
}

say join(', ', cubefull_numbers(1e4));

__END__
1, 8, 16, 27, 32, 64, 81, 125, 128, 216, 243, 256, 343, 432, 512, 625, 648, 729, 864, 1000, 1024, 1296, 1331, 1728, 1944, 2000, 2048, 2187, 2197, 2401, 2592, 2744, 3125, 3375, 3456, 3888, 4000, 4096, 4913, 5000, 5184, 5488, 5832, 6561, 6859, 6912, 7776, 8000, 8192, 9261, 10000
