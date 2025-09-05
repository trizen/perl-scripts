#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 September 2025
# https://github.com/trizen

# Count the number of B-rough numbers <= n.

# See also:
#   https://en.wikipedia.org/wiki/Rough_number

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub my_rough_count($n, $k) {

    my @P = @{primes($k - 1)};

    return $n if (@P == 0);

    my %cache;

    sub ($n, $a) {

        my $key = "$n,$a";

        return $cache{$key}
            if exists $cache{$key};

        # Initial count: odd numbers ≤ n
        my $count = $n - ($n >> 1);

        # Inclusion-Exclusion principle
        for my $j (1 .. $a - 1) {
            last if ($P[$j] > $n);
            $count -= __SUB__->(divint($n, $P[$j]), $j);
        }

        $cache{$key} = $count;
    }->($n, scalar @P);
}

foreach my $p (@{primes(30)}) {
    say "Φ(10^n, $p) for n <= 10: [", join(', ', map { my_rough_count(powint(10, $_), $p) } 0 .. 10), "]";
}

__END__
Φ(10^n,  2) for n <= 10: [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 10000000000]
Φ(10^n,  3) for n <= 10: [1, 5, 50, 500, 5000, 50000, 500000, 5000000, 50000000, 500000000, 5000000000]
Φ(10^n,  5) for n <= 10: [1, 3, 33, 333, 3333, 33333, 333333, 3333333, 33333333, 333333333, 3333333333]
Φ(10^n,  7) for n <= 10: [1, 2, 26, 266, 2666, 26666, 266666, 2666666, 26666666, 266666666, 2666666666]
Φ(10^n, 11) for n <= 10: [1, 1, 22, 228, 2285, 22857, 228571, 2285713, 22857142, 228571428, 2285714285]
Φ(10^n, 13) for n <= 10: [1, 1, 21, 207, 2077, 20779, 207792, 2077921, 20779221, 207792207, 2077922077]
Φ(10^n, 17) for n <= 10: [1, 1, 20, 190, 1917, 19181, 191808, 1918081, 19180820, 191808190, 1918081917]
Φ(10^n, 19) for n <= 10: [1, 1, 19, 179, 1806, 18053, 180524, 1805251, 18052535, 180525355, 1805253568]
Φ(10^n, 23) for n <= 10: [1, 1, 18, 170, 1711, 17103, 171021, 1710234, 17102401, 171024023, 1710240224]
Φ(10^n, 29) for n <= 10: [1, 1, 17, 163, 1634, 16361, 163586, 1635877, 16358819, 163588196, 1635881952]
