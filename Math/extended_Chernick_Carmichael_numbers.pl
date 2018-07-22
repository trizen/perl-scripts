#!/usr/bin/perl

# Daniel Șuteu, 22 July 2018
# Generate all the extended Chernick Carmichael numbers bellow a certain limit.

use 5.014;
use warnings;

use List::Util qw(all);
use ntheory qw(is_prime is_carmichael);
use Math::AnyNum qw(:overload is_div prod);

# Generate the factors of a Chernick number, given n
# and k, where k is the number of distinct prime factors.
sub chernick_carmichael_factors {
    my ($n, $k) = @_;
    (6 * $n + 1, 12 * $n + 1, (map { 2**$_ * 9 * $n + 1 } 1 .. $k - 2));
}

my @terms;
my $limit = 0 + ($ARGV[0] // 10**15);

# Generate terms with k distict prime factors
for (my $k = 3 ; ; ++$k) {

    # We can stop the search when:
    #   (6*m + 1) * (12*m + 1) * Product_{i=1..k-2} (9 * 2^i * m + 1)
    # is greater than the limit, for m=1.
    last if prod(chernick_carmichael_factors(1, $k)) > $limit;

    # Generate the extended Chernick numbers with k distinct prime factors,
    # that are also Carmichael numbers, bellow the limit we're looking for.
    for (my $n = 1 ; ; ++$n) {

        my @f = chernick_carmichael_factors($n, $k);
        my $c = prod(@f);

        last if $c > $limit;
        next if not is_carmichael($c);

        # Check the conditions for an extended Chernick Carmichael number
        next if not all { is_prime($_) } @f;
        next if not is_div(($f[0] - 1) / 6, 2**($k - 4));

        push @terms, $c;
    }
}

# Sort the terms
my @final_terms = sort { $a <=> $b } @terms;

# Display the terms
foreach my $k (0 .. $#final_terms) {
    say ($k + 1, ' ', $final_terms[$k]);
}
