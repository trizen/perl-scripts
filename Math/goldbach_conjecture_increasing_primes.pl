#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 September 2016
# Website: https://github.com/trizen

# The smallest prime p such that (2n - p) is also a prime number,
# and the prime p is the largest prime seen so far.

# Analyzing this sequence, may give us an insight into the Golbach's conjecture.

use strict;
use warnings;

use ntheory qw(primes is_prime);

my $limit  = 1000000;
my @primes = @{primes($limit)};

my $max = 0;

OUTER: for (my $i = 4 ; $i <= $limit ; $i += 2) {
    foreach my $p (@primes) {
        if (is_prime($i - $p)) {

            if ($p > $max) {
                $max = $p;
                printf("%7s %7s\n", $i, $p);
            }

            next OUTER;
        }
    }
}

__END__

Output for 2n <= 10^7:

     n       p
   -----   -----
      4       2
      6       3
     12       5
     30       7
     98      19
    220      23
    308      31
    556      47
    992      73
   2642     103
   5372     139
   7426     173
  43532     211
  54244     233
  63274     293
 113672     313
 128168     331
 194428     359
 194470     383
 413572     389
 503222     523
1077422     601
3526958     727
3807404     751
