#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 06 May 2022
# https://github.com/trizen

# A new algorithm for generating Fermat pseudoprimes to any given base.

# See also:
#   https://oeis.org/A001567 -- Fermat pseudoprimes to base 2, also called Sarrus numbers or Poulet numbers.
#   https://oeis.org/A050217 -- Super-Poulet numbers: Poulet numbers whose divisors d all satisfy d|2^d-2.

# See also:
#   https://en.wikipedia.org/wiki/Fermat_pseudoprime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::AnyNum qw(prod);
use ntheory qw(:all);

sub fermat_pseudoprimes ($base, $pm1_multiple, $prime_limit, $callback) {

    my %common_divisors;

    for (my $p = 2; $p <= $prime_limit; $p = next_prime($p)) {
        my $z = znorder($base, $p) // next;
        for my $d (divisors($pm1_multiple * ($p - 1))) {
            if ($d % $z == 0) {
                push @{$common_divisors{$d}}, $p;
            }
        }
    }

    my %seen;

    foreach my $arr (values %common_divisors) {

        my $l = scalar(@$arr);

        foreach my $k (2 .. $l) {
            forcomb {
                my $n = prod(@{$arr}[@_]);
                $callback->($n) if !$seen{$n}++;
            } $l, $k;
        }
    }
}

my @pseudoprimes;

my $base         = 2;        # generate Fermat pseudoprimes to this base
my $pm1_multiple = 2 * 3;    # multiple of p-1
my $prime_limit  = 1000;     # sieve primes up to this limit

fermat_pseudoprimes(
    $base,                   # base
    $pm1_multiple,           # p-1 multiple
    $prime_limit,            # prime limit
    sub ($n) {
        if (is_pseudoprime($n, $base)) {
            push @pseudoprimes, $n;
        }
    }
);

@pseudoprimes = sort { $a <=> $b } @pseudoprimes;

say join(', ', @pseudoprimes);

__END__
341, 1105, 1387, 1729, 2047, 2701, 3277, 4033, 4369, 4681, 5461, 7957, 8321, 10261, 13747, 13981, 14491, 15709, 18721, 19951, 23377, 31417, 31609, 31621, 35333, 42799, 49141, 49981, 60701, 60787, 63973, 65281, 68101, 83333, 88357, 90751, 104653, 115921, 126217, 129889, 130561, 137149, 149281, 150851, 158369, 162193, 164737, 188461, 219781, 226801, 241001, 249841, 266305, 282133, 285541, 294409, 341497, 423793, 617093, 625921, 847261, 852841, 1052503, 1052929, 1104349, 1193221, 1398101, 1549411, 1746289, 1840357, 1857241, 2940337, 2953711, 3048841, 3828001, 4072729, 4154161, 4209661, 4670029, 6236473, 6474691, 6973057, 8462233, 9106141, 10802017, 12599233, 12932989, 13757653, 15732721, 17098369, 17895697, 20140129, 24929281, 30951181, 31794241, 46045117, 50193793, 53399449, 54448153, 56052361, 74945953, 82995421, 83083001, 92625121, 102134113, 118901521, 126682753, 127479097, 147868201, 172947529, 203215297, 215973001, 216821881, 285212689, 509033161, 551840221, 555046097, 698784361, 708621217, 1616873413, 1772267281, 2300628601, 3664146889, 4128469381, 6030849889, 6812268193, 9077780017, 10754196097, 10794378673, 11507202337, 11620854433, 16744588921, 19711883809, 42625846021, 50110190461, 68736258049, 136763894881, 1688543976829, 2075559846721, 3930678747361, 13266097803457
