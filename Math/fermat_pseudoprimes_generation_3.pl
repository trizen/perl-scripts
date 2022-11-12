#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 02 July 2022
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

sub fermat_pseudoprimes ($bases, $k_limit, $prime_limit, $callback) {

    my %common_divisors;
    my $bases_lcm = lcm(@$bases);

    for (my $p = 2 ; $p <= $prime_limit ; $p = next_prime($p)) {
        next if ($bases_lcm % $p == 0);
        my @orders     = map { znorder($_, $p) } @$bases;
        my $lcm_orders = lcm(@orders);
        for my $k (1 .. $k_limit) {
            if (is_prime($k * $lcm_orders + 1)) {
                push @{$common_divisors{$lcm_orders}}, $k * $lcm_orders + 1;
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

my @bases       = (2, 3);    # generate Fermat pseudoprimes to these bases
my $k_limit     = 10;        # largest k multiple of the znorder(base, p)
my $prime_limit = 500;       # sieve primes up to this limit

fermat_pseudoprimes(
    \@bases,                 # bases
    $k_limit,                # k limit
    $prime_limit,            # prime limit
    sub ($n) {
        if (is_pseudoprime($n, @bases)) {
            push @pseudoprimes, $n;
        }
    }
);

@pseudoprimes = sort { $a <=> $b } @pseudoprimes;

say join(', ', @pseudoprimes);

__END__
1105, 1729, 2465, 2701, 2821, 18721, 29341, 31621, 46657, 49141, 63973, 83333, 90751, 104653, 172081, 176149, 226801, 252601, 282133, 294409, 399001, 488881, 512461, 653333, 721801, 852841, 873181, 1152271, 1373653, 1537381, 1690501, 2100901, 2944261, 3057601, 4335241, 6189121, 6309901, 10267951, 10802017, 12490201, 12932989, 17098369, 19384289, 32285041, 46045117, 50201089, 53711113, 56052361, 64377991, 68154001, 79624621, 83083001, 84350561, 118901521, 171454321, 172947529, 214852609, 216821881, 228842209, 308448649, 492559141, 650028061, 739444021, 771043201, 775368901, 947950501, 1213619761, 1269295201, 1348964401, 2140082101, 2598933481, 3787491457, 3955764121, 34453315009, 36764611129, 192739365541, 476407634761, 525473097661, 769888667161, 2570872764241, 8060437695529, 211900752829081, 2975137644706921
