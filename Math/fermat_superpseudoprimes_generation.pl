#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 28 January 2019
# https://github.com/trizen

# A new algorithm for generating Fermat super-pseudoprimes to any given base.

# See also:
#   https://oeis.org/A050217 -- Super-Poulet numbers: Poulet numbers whose divisors d all satisfy d|2^d-2.

# See also:
#   https://en.wikipedia.org/wiki/Fermat_pseudoprime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::AnyNum qw(prod);
use ntheory qw(:all);

sub fermat_superpseudoprimes ($base, $prime_limit, $callback) {

    my %common_divisors;

    for (my $p = 2; $p <= $prime_limit; $p = next_prime($p)) {
        my $z = znorder($base, $p) // next;
        foreach my $d (divisors($p - 1)) {
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

sub is_fermat_pseudoprime ($n, $base) {
    powmod($base, $n - 1, $n) == 1;
}

sub is_fibonacci_pseudoprime ($n) {
    (lucas_sequence($n, 1, -1, $n - kronecker($n, 5)))[0] == 0;
}

my $base = 2;
my @pseudoprimes;

fermat_superpseudoprimes(
    $base,    # base
    3_000,    # prime limit
    sub ($n) {

        is_fermat_pseudoprime($n, $base) || die "error for n=$n";

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
341, 1387, 2047, 2701, 3277, 4033, 4369, 4681, 5461, 7957, 8321, 10261, 13747, 14491, 15709, 18721, 19951, 23377, 31417, 31609, 31621, 35333, 42799, 49141, 49981, 60701, 60787, 65077, 65281, 80581, 83333, 85489, 88357, 90751, 104653, 123251, 129889, 130561, 150851, 162193, 164737, 181901, 188057, 194221, 196093, 215749, 219781, 220729, 226801, 241001, 249841, 253241, 256999, 264773, 271951, 275887, 280601, 282133, 294271, 294409, 318361, 357761, 390937, 396271, 422659, 435671, 443719, 452051, 458989, 481573, 486737, 513629, 514447, 556169, 580337, 587861, 604117, 642001, 653333, 657901, 665281, 665333, 679729, 710533, 721801, 722201, 722261, 729061, 741751, 745889, 769567, 838861, 873181, 877099, 916327, 983401, 1053761, 1082401, 1092547, 1168513, 1207361, 1252697, 1293337, 1302451, 1325843, 1357441, 1373653, 1398101, 1433407, 1493857, 1507963, 1530787, 1537381, 1549411, 1584133, 1678541, 1690501, 1735841, 1755001, 1809697, 1840357, 1969417, 1987021, 2008597, 2035153, 2134277, 2163001, 2205967, 2269093, 2284453, 2304167, 2487941, 2491637, 2617451, 2649029, 2944261, 2977217, 3059101, 3090091, 3235699, 3345773, 3363121, 3400013, 4082653, 4469471, 5351537, 5423713, 6122551, 12599233, 13421773, 15162941, 15732721, 28717483, 61377109, 66384121, 67763803, 74658629, 90341197, 96916279, 109322501, 135945853, 157010389, 163442551, 221415781, 271682651, 434042801, 457457617, 464955857, 516045197, 536870911, 604611019, 630622753, 1299963601, 1541955409, 1879623157, 3650158849, 31675383749, 193601185171, 257506553303
