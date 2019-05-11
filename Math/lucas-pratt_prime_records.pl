#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 May 2019
# https://github.com/trizen

# Count the number of nodes in the Lucas-Pratt primality tree, rooted at a given prime.

# See also:
#   https://oeis.org/A037231 -- Primes which set a new record for length of Pratt certificate.
#   https://oeis.org/A130790 -- Number of nodes in the Lucas-Pratt primality tree rooted at prime(n).

use 5.020;
use warnings;

use ntheory qw(:all);
use Memoize qw(memoize);
use experimental qw(signatures);

memoize('lucas_pratt_primality_tree_count');

sub lucas_pratt_primality_tree_count ($p, $r = -1) {

    return 0 if ($p <= 1);
    return 1 if ($p == 2);

    vecsum(map { __SUB__->($_->[0], $r) } factor_exp($p + $r));
}

sub lucas_pratt_prime_records ($r = -1, $upto = 1e6) {

    my $max = 0;
    my @primes;

    forprimes {
        my $t = lucas_pratt_primality_tree_count($_, $r);
        if ($t > $max) {
            $max = $t;
            push @primes, $_;
        }
    } $upto;

    return @primes;
}

say "p-1: ", join(', ', lucas_pratt_prime_records(-1, 1e6));     # A037231
say "p+1: ", join(', ', lucas_pratt_prime_records(+1, 1e6));

__END__
p-1: 2, 7, 23, 43, 139, 283, 659, 1319, 5179, 9227, 23159, 55399, 148439, 366683, 793439, 1953839, 4875119, 9750239
p+1: 2, 5, 19, 29, 73, 173, 569, 1109, 2917, 5189, 10729, 21169, 42337, 84673, 254021, 508037, 1287457, 3787969, 7575937
