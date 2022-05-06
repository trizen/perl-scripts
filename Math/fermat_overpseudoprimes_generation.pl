#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 28 January 2019
# https://github.com/trizen

# A new algorithm for generating Fermat overpseudoprimes to any given base.

# See also:
#   https://oeis.org/A141232 -- Overpseudoprimes to base 2: composite k such that k = A137576((k-1)/2).

# See also:
#   https://en.wikipedia.org/wiki/Fermat_pseudoprime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::AnyNum qw(prod);
use ntheory qw(:all);

sub fermat_overpseudoprimes ($base, $prime_limit, $callback) {

    my %common_divisors;

    for (my $p = 2; $p <= $prime_limit; $p = next_prime($p)) {
        my $z = znorder($base, $p) // next;
        push @{$common_divisors{$z}}, $p;
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

sub is_fibonacci_pseudoprime ($n) {
    (lucas_sequence($n, 1, -1, $n - kronecker($n, 5)))[0] == 0;
}

my @pseudoprimes;

my $base        = 2;            # generate overpseudoprime to this base
my $prime_limit = 10_000;       # sieve primes up to this limit

fermat_overpseudoprimes(
    $base,           # base
    $prime_limit,    # prime limit
    sub ($n) {

        is_pseudoprime($n, 2) || die "error for n=$n";

        if (kronecker($n, 5) == -1) {
            if (is_fibonacci_pseudoprime($n)) {
                die "Found a special pseudoprime: $n";
            }
        }

        push @pseudoprimes, $n;
    }
);

@pseudoprimes = sort { $a <=> $b } @pseudoprimes;

say join(', ', @pseudoprimes);

__END__
2047, 3277, 4033, 8321, 65281, 80581, 85489, 88357, 104653, 130561, 220729, 253241, 256999, 280601, 390937, 458989, 486737, 514447, 580337, 818201, 838861, 877099, 916327, 976873, 1016801, 1082401, 1207361, 1251949, 1252697, 1325843, 1441091, 1507963, 1509709, 1530787, 1678541, 1811573, 2004403, 2181961, 2205967, 2264369, 2304167, 2387797, 2746477, 2748023, 2757241, 2811271, 2909197, 2976487, 3090091, 3116107, 3375041, 3400013, 3898129, 4181921, 4188889, 4469471, 4513841, 5016191, 5044033, 5173169, 5173601, 5672041, 6140161, 6226193, 6368689, 6386993, 6952037, 7306561, 7759937, 7820201, 8036033, 9006401, 9056501, 9371251, 9863461, 10425511, 10610063, 10974881, 11585293, 13338371, 13421773, 13694761, 13747361, 14179537, 14324473, 14794081, 15139199, 15188557, 15976747, 16070429, 16324001, 16853077, 17116837, 17327773, 17375249, 18073817, 18443701, 18535177, 18653353, 19404139, 21306157, 22591301, 22669501, 23464033, 23963869, 27108397, 27509653, 27664033, 27798461, 27808463, 28325881, 29581501, 30881551, 35851037, 36307981, 43363601, 46325029, 46517857, 47918581, 48191653, 48448661, 55318957, 63001801, 64605041, 464955857, 536870911, 1220114377, 1541955409, 5256967999, 5726579371, 7030714813, 8788016089, 10545166433, 18723407341, 19089110641, 37408911097, 43215089153, 59850086533, 65700513721, 78889735961, 99737787437, 105207688757, 125402926477, 149583518641, 168003672409, 40925790926473, 322053315634073
