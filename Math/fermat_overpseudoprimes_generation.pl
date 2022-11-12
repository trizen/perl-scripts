#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 28 January 2019
# Edit: 12 November 2022
# https://github.com/trizen

# A new algorithm for generating Fermat overpseudoprimes to multiple bases.

# See also:
#   https://oeis.org/A141232 -- Overpseudoprimes to base 2: composite k such that k = A137576((k-1)/2).
#   https://oeis.org/A140658 -- Overpseudoprimes to bases 2 and 3.

# See also:
#   https://en.wikipedia.org/wiki/Fermat_pseudoprime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;
use experimental qw(signatures);

use ntheory qw(:all);

sub fermat_overpseudoprimes ($bases, $prime_limit, $callback) {

    my %common_divisors;
    my $bases_lcm = lcm(@$bases);

    for (my $p = 2 ; $p <= $prime_limit ; $p = next_prime($p)) {
        next if ($bases_lcm % $p == 0);
        my @orders = map { znorder($_, $p) } @$bases;
        my $sig    = join(' ', @orders);
        push @{$common_divisors{$sig}}, $p;
    }

    my %seen;

    foreach my $arr (values %common_divisors) {

        my $l = scalar(@$arr);

        foreach my $k (2 .. $l) {
            forcomb {
                my $n = vecprod(@{$arr}[@_]);
                $callback->($n) if !$seen{$n}++;
            } $l, $k;
        }
    }
}

my @pseudoprimes;

my @bases       = (2, 3);    # generate overpseudoprime to these bases
my $prime_limit = 1e5;       # sieve primes up to this limit

fermat_overpseudoprimes(
    \@bases,                 # bases
    $prime_limit,            # prime limit
    sub ($n) {
        push @pseudoprimes, $n;
    }
);

@pseudoprimes = sort { $a <=> $b } @pseudoprimes;

say join(', ', @pseudoprimes);

__END__
5173601, 13694761, 16070429, 27509653, 54029741, 66096253, 102690677, 117987841, 193949641, 206304961, 314184487, 390612221, 393611653, 717653129, 960946321, 1157839381, 1236313501, 1921309633, 2217879901, 2412172153, 2626783921, 4710862501
