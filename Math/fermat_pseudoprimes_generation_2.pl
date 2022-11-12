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

sub fermat_pseudoprimes ($bases, $k_limit, $prime_limit, $callback) {

    my %common_divisors;
    my $bases_lcm = lcm(@$bases);

    for (my $p = 2 ; $p <= $prime_limit ; $p = next_prime($p)) {
        next if ($bases_lcm % $p == 0);
        my @orders = map { znorder($_, $p) } @$bases;
        for my $k (1 .. $k_limit) {
            foreach my $o (@orders) {
                push @{$common_divisors{$k * $o}}, $p;
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
341, 1105, 1387, 2047, 2701, 3277, 4033, 4369, 4681, 5461, 7957, 8321, 10261, 13747, 13981, 14491, 15709, 18721, 19951, 23377, 31417, 31609, 31621, 35333, 42799, 49141, 49981, 60701, 60787, 65281, 68101, 83333, 88357, 90751, 104653, 113201, 115921, 129889, 130561, 137149, 149281, 150851, 158369, 162193, 164737, 219781, 241001, 249841, 266305, 282133, 294409, 341497, 387731, 423793, 617093, 1052503, 1052929, 1104349, 1306801, 1398101, 1534541, 1549411, 1746289, 1840357, 2327041, 2899801, 2940337, 2953711, 3048841, 4072729, 4154161, 4209661, 4335241, 6236473, 8462233, 9106141, 10004681, 10802017, 11433301, 12599233, 12932989, 13216141, 15732721, 17895697, 24929281, 46045117, 50193793, 50201089, 53399449, 68033801, 74945953, 75501793, 83083001, 102134113, 108952411, 118901521, 127479097, 147868201, 172947529, 236530981, 285212689, 523842337, 555046097, 708621217, 734770681, 1007608753, 1231726981, 2201474969, 2811315361, 3664146889, 4128469381, 6812268193, 6871413901, 9077780017, 10794378673, 32733862237, 43564534561, 63450063793, 68736258049, 195931272241, 302257028449, 1688543976829, 3930678747361, 15065746744717, 27473877622369, 36610686808561, 9235302754511521, 15852427388106913
