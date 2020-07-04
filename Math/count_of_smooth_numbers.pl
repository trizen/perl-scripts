#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 May 2020
# https://github.com/trizen

# Count the number of B-smooth numbers <= n.

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub smooth_count ($n, $p) {

    if ($p == 2) {
        return 1 + logint($n, 2);
    }

    my $q = prev_prime($p);

    my $count = 0;
    foreach my $k (0 .. logint($n, $p)) {
        $count += __SUB__->(divint($n, powint($p, $k)), $q);
    }

    return $count;
}

foreach my $p (@{primes(20)}) {
    say "Ψ(10^n, $p) for n <= 10: [", join(', ', map { smooth_count(powint(10, $_), $p) } 0 .. 10), "]";
}

__END__
Ψ(10^n,  2) for n <= 10: [1, 4, 7, 10, 14, 17, 20, 24, 27, 30, 34]
Ψ(10^n,  3) for n <= 10: [1, 7, 20, 40, 67, 101, 142, 190, 244, 306, 376]
Ψ(10^n,  5) for n <= 10: [1, 9, 34, 86, 175, 313, 507, 768, 1105, 1530, 2053]
Ψ(10^n,  7) for n <= 10: [1, 10, 46, 141, 338, 694, 1273, 2155, 3427, 5194, 7575]
Ψ(10^n, 11) for n <= 10: [1, 10, 55, 192, 522, 1197, 2432, 4520, 7838, 12867, 20193]
Ψ(10^n, 13) for n <= 10: [1, 10, 62, 242, 733, 1848, 4106, 8289, 15519, 27365, 45914]
Ψ(10^n, 17) for n <= 10: [1, 10, 67, 287, 945, 2579, 6179, 13389, 26809, 50351, 89679]
Ψ(10^n, 19) for n <= 10: [1, 10, 72, 331, 1169, 3419, 8751, 20198, 42950, 85411, 160626]
