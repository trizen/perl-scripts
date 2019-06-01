#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 July 2018
# https://github.com/trizen

# Generate all the extended Chernick's Carmichael numbers bellow a certain limit.

# OEIS sequences:
#   https://oeis.org/A317126
#   https://oeis.org/A317136

# See also:
#   https://oeis.org/wiki/Carmichael_numbers
#   http://www.ams.org/journals/bull/1939-45-04/S0002-9904-1939-06953-X/home.html

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

# Generate the factors of a Chernick number, given n
# and m, where n is the number of distinct prime factors.
sub chernick_carmichael_factors ($n, $m) {
    (6*$m + 1, 12*$m + 1, (map { (1 << $_) * 9*$m + 1 } 1 .. $n-2));
}

# Check the conditions for an extended Chernick-Carmichael number
sub is_chernick_carmichael ($n, $m) {
    ($n == 2) ? (is_prime(6*$m + 1) && is_prime(12*$m + 1))
              : (is_prime((1 << ($n-2)) * 9*$m + 1) && __SUB__->($n-1, $m));
}

my @terms;
my $limit = 0 + ($ARGV[0] // 10**15);

# Generate terms with k distict prime factors
for (my $n = 3 ; ; ++$n) {

    # We can stop the search when:
    #   (6*m + 1) * (12*m + 1) * Product_{i=1..n-2} (9 * 2^i * m + 1)
    # is greater than the limit, for m=1.
    last if vecprod(chernick_carmichael_factors($n, 1)) > $limit;

    # Set the multiplier, based on the condition that `m` has to be divisible by 2^(k-4).
    my $multiplier = ($n > 4) ? 5*(1 << ($n-4)) : 1;

    # Generate the extended Chernick numbers with n distinct prime factors,
    # that are also Carmichael numbers, bellow the limit we're looking for.
    for (my $k = 1 ; ; ++$k) {

        my $m = $multiplier * $k;

        # All factors must be prime
        is_chernick_carmichael($n, $m) || next;

        # Get the prime factors
        my @f = chernick_carmichael_factors($n, $m);

        # The product of these primes, gives a Carmichael number
        my $c = vecprod(@f);
        last if $c > $limit;
        push @terms, $c;
    }
}

# Sort the terms
my @final_terms = sort { $a <=> $b } @terms;

# Display the terms
foreach my $k (0 .. $#final_terms) {
    say($k + 1, ' ', $final_terms[$k]);
}
