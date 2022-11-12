#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 28 January 2019
# Edit: 12 November 2022
# https://github.com/trizen

# A new algorithm for generating Fermat superpseudoprimes to multiple bases.

# See also:
#   https://oeis.org/A050217 -- Super-Poulet numbers: Poulet numbers whose divisors d all satisfy d|2^d-2.

# See also:
#   https://en.wikipedia.org/wiki/Fermat_pseudoprime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;
use experimental qw(signatures);

use ntheory qw(:all);

sub fermat_superpseudoprimes ($bases, $prime_limit, $callback) {

    my %common_divisors;
    my $bases_lcm = lcm(@$bases);

    for (my $p = 2 ; $p <= $prime_limit ; $p = next_prime($p)) {
        next if ($bases_lcm % $p == 0);
        my @orders = map { znorder($_, $p) } @$bases;
        foreach my $d (divisors($p - 1)) {
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

my @bases       = (2, 3, 5);    # superpseudoprimes to these bases
my $prime_limit = 1e4;          # prime limit

my @pseudoprimes;

fermat_superpseudoprimes(
    \@bases,                    # bases
    $prime_limit,               # prime limit
    sub ($n) {
        push @pseudoprimes, $n;
    }
);

@pseudoprimes = sort { $a <=> $b } @pseudoprimes;

say join(', ', @pseudoprimes);

__END__
721801, 873181, 9006401, 9863461, 10403641, 12322133, 18736381, 20234341, 21397381, 22369621, 25696133, 36307981, 42702661, 46094401, 47253781
