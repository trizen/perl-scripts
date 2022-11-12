#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 06 May 2022
# Edit: 12 November 2022
# https://github.com/trizen

# A new algorithm for generating Fermat pseudoprimes to multiple bases.

# See also:
#   https://oeis.org/A001567 -- Fermat pseudoprimes to base 2, also called Sarrus numbers or Poulet numbers.
#   https://oeis.org/A050217 -- Super-Poulet numbers: Poulet numbers whose divisors d all satisfy d|2^d-2.

# See also:
#   https://en.wikipedia.org/wiki/Fermat_pseudoprime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;
use experimental qw(signatures);

use ntheory qw(:all);

sub fermat_pseudoprimes ($bases, $pm1_multiple, $prime_limit, $callback) {

    my %common_divisors;
    my $bases_lcm = lcm(@$bases);

    for (my $p = 2 ; $p <= $prime_limit ; $p = next_prime($p)) {
        next if ($bases_lcm % $p == 0);
        my @orders = map { znorder($_, $p) } @$bases;
        for my $d (divisors($pm1_multiple * ($p - 1))) {
            if (vecall { $d % $_ == 0 } @orders) {
                push @{$common_divisors{$d}}, $p;
            }
        }
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

my @bases        = (2, 3);    # generate Fermat pseudoprimes to these bases
my $pm1_multiple = 2 * 3;     # multiple of p-1
my $prime_limit  = 1000;      # sieve primes up to this limit

fermat_pseudoprimes(
    \@bases,                  # base
    $pm1_multiple,            # p-1 multiple
    $prime_limit,             # prime limit
    sub ($n) {
        if (is_pseudoprime($n, @bases)) {
            push @pseudoprimes, $n;
        }
    }
);

@pseudoprimes = sort { $a <=> $b } @pseudoprimes;

say join(', ', @pseudoprimes);

__END__
1729, 2701, 18721, 31621, 49141, 63973, 83333, 90751, 104653, 126217, 226801, 282133, 294409, 4670029, 10802017, 12932989, 46045117, 56052361, 83083001, 118901521, 127479097, 172947529, 216821881
