#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 December 2019
# https://github.com/trizen

# Compute the n-th composite number and the number of composite numbers <= n.

# See also:
#   https://oeis.org/A002808 -- The composite numbers: numbers n of the form x*y for x > 1 and y > 1.
#   https://oeis.org/A065857 -- The (10^n)-th composite number.

use 5.020;
use warnings;
use ntheory qw(:all);
use experimental qw(signatures);

sub composite_count($n) {
    $n - prime_count($n) - 1;
}

sub nth_composite($n) {

    return undef if ($n <= 0);
    return 4     if ($n == 1);

    # Lower and upper bounds from A002808 (for n >= 4).
    my $min = int($n + $n / log($n) + $n / (log($n)**2));
    my $max = int($n + $n / log($n) + (3 * $n) / (log($n)**2));

    if ($n < 4) {
        $min = 4;
        $max = 8;
    }

    my $k = 0;

    while (1) {
        $k = ($min + $max) >> 1;

        my $cmp = ($k - prime_count($k) - 1) <=> $n;

        if ($cmp > 0) {
            $max = $k - 1;
        }
        elsif ($cmp < 0) {
            $min = $k + 1;
        }
        else {
            last;
        }
    }

    --$k if is_prime($k);

    return $k;
}

say nth_composite(1000000000);      #=> 1053422339
say composite_count(1053422339);    #=> 1000000000
