#!/usr/bin/perl

# Daniel "Trizen" Șuteu and M. F. Hasler
# Date: 20 April 2018
# Edit: 23 April 2018
# https://github.com/trizen

# Find the first index of the odd prime number in the nth-order Fibonacci sequence.

# See also:
#   https://oeis.org/A302990

use 5.020;
use strict;
use warnings;

use Math::GMPz;

my $ONE = Math::GMPz->new(1);

use ntheory qw(is_prob_prime);
use experimental qw(signatures);

sub nth_order_prime_fibonacci_index ($n = 2, $min = 0) {

    # Algorithm after M. F. Hasler from https://oeis.org/A302990
    my @a = map { $_ < $n ? ($ONE << $_) : $ONE } 1 .. ($n + 1);

    for (my $i = 2 * ($n += 1) - 2 ; ; ++$i) {

        my $t  = $i % $n;
        $a[$t] = ($a[$t-1] << 1) - $a[$t];

        if ($i >= $min and Math::GMPz::Rmpz_odd_p($a[$t])) {
            #say "Testing: $i";

            if (is_prob_prime($a[$t])) {
                #say "\nFound: $t -> $i\n";
                return $i;
            }
        }
    }
}

# a(33) = 94246
# a(36) = ?
# a(37) = 758
# a(38) = ?
# a(39) = ?

# a(36)  > 170050       (M. F. Hasler)
# a(38)  > 40092
# a(41)  > 142000       (M. F. Hasler)
# a(100) > 48076

# Example for computing the terms a(2)-a(26):
say join ", ", map{ nth_order_prime_fibonacci_index($_) } 2..26;

# Searching for a(36)
# say nth_order_prime_fibonacci_index(36, 170051);
