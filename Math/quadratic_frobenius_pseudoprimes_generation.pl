#!/usr/bin/perl

# Author: Trizen
# Date: 19 November 2023
# https://github.com/trizen

# A new algorithm for generating (almost) Quadratic-Frobenius pseudoprimes.

# See also:
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::AnyNum qw(prod);
use ntheory      qw(forcomb forprimes kronecker divisors);

sub quadratic_powmod ($a, $b, $w, $n, $m) {

    my ($x, $y) = (1, 0);

    do {
        ($x, $y) = (($a * $x + $b * $y * $w) % $m, ($a * $y + $b * $x) % $m) if ($n & 1);
        ($a, $b) = (($a * $a + $b * $b * $w) % $m, (2 * $a * $b) % $m);
    } while ($n >>= 1);

    ($x, $y);
}

sub quadratic_frobenius_pseudoprimes ($limit, $callback) {

    my %common_divisors;

    my $c = 5;

    forprimes {
        my $p = $_;
        foreach my $d (divisors($p - kronecker($c, $p))) {
            if ($d > 1 and (quadratic_powmod(1, 1, $c, $d, $p))[0] == 1) {
                push @{$common_divisors{$d}}, $p;
            }
        }
    } 3, $limit;

    my %seen;

    foreach my $arr (values %common_divisors) {

        my $l = $#{$arr} + 1;

        foreach my $k (2 .. $l) {
            forcomb {
                my $n = prod(@{$arr}[@_]);
                $callback->($n, @{$arr}[@_]) if !$seen{$n}++;
            } $l, $k;
        }
    }
}

my @pseudoprimes;

quadratic_frobenius_pseudoprimes(
    1e4,
    sub ($n, @f) {
        push @pseudoprimes, $n;
    }
);

@pseudoprimes = sort { $a <=> $b } @pseudoprimes;

say join(', ', @pseudoprimes);

__END__
1891, 11663, 40501, 88831, 138833, 145351, 191351, 218791, 219781, 722261, 741751, 954271, 1123937, 1521187, 1690501, 1735841, 1963501, 2253751, 2741311, 2757241, 3568661, 3768451, 3996991, 4229551, 4686391, 5143823, 5323337, 5652191, 6368689, 6755251, 6976201, 7398151, 9031651, 9080191, 9493579, 9863461, 10036223, 10386241, 10403641, 15576571, 16253551, 18888379, 20234341, 22591301, 22669501, 22994371, 30186337, 74442383, 95413823, 5073193501, 21936153271
