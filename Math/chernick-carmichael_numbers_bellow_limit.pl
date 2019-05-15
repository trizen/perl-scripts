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
# and k, where k is the number of distinct prime factors.
sub chernick_carmichael_factors ($n, $k) {
    (6 * $n + 1, 12 * $n + 1, (map { (1 << $_) * 9 * $n + 1 } 1 .. $k - 2));
}

my @terms;
my $limit = 0 + ($ARGV[0] // 10**15);

# Generate terms with k distict prime factors
for (my $k = 3 ; ; ++$k) {

    # We can stop the search when:
    #   (6*m + 1) * (12*m + 1) * Product_{i=1..k-2} (9 * 2^i * m + 1)
    # is greater than the limit, for m=1.
    last if vecprod(chernick_carmichael_factors(1, $k)) > $limit;

    # Set the multiplier, based on the condition that `m` has to be divisible by 2^(k-4).
    my $multiplier = 1;

    if ($k > 4) {
        $multiplier = 1 << ($k - 4);
    }

    # Generate the extended Chernick numbers with k distinct prime factors,
    # that are also Carmichael numbers, bellow the limit we're looking for.
    for (my $n = 1 ; ; ++$n) {

        my @f = chernick_carmichael_factors($n * $multiplier, $k);

        # Check the condition for an extended Chernick-Carmichael number
        next if not vecall { is_prime($_) } @f;

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
