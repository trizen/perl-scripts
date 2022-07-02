#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 02 July 2022
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
use ntheory      qw(:all);

sub fermat_pseudoprimes ($base, $k_limit, $prime_limit, $callback) {

    my %common_divisors;

    for (my $p = 2 ; $p <= $prime_limit ; $p = next_prime($p)) {
        my $z = znorder($base, $p) // next;
        for my $k (1 .. $k_limit) {
            if (is_prime($k * $z + 1)) {
                push @{$common_divisors{$z}}, $k * $z + 1;
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

my $base        = 2;       # generate Fermat pseudoprimes to this base
my $k_limit     = 10;      # largest k multiple of the znorder(base, p)
my $prime_limit = 1000;    # sieve primes up to this limit

fermat_pseudoprimes(
    $base,                 # base
    $k_limit,              # k limit
    $prime_limit,          # prime limit
    sub ($n) {
        if (is_pseudoprime($n, $base)) {
            push @pseudoprimes, $n;
        }
    }
);

@pseudoprimes = sort { $a <=> $b } @pseudoprimes;

say join(', ', @pseudoprimes);

__END__
341, 561, 1105, 1387, 1729, 2047, 2465, 2701, 2821, 3277, 4033, 4681, 5461, 7957, 8321, 11305, 13747, 13981, 18721, 19951, 23377, 29341, 31417, 31609, 31621, 35333, 46657, 49141, 60701, 65281, 83333, 88357, 104653, 129889, 137149, 158369, 164737, 176149, 194221, 196093, 219781, 241001, 249841, 252601, 275887, 282133, 285541, 294409, 387731, 390937, 399001, 488881, 512461, 513629, 514447, 580337, 587861, 604117, 617093, 642001, 653333, 665281, 710533, 721801, 722201, 722261, 729061, 847261, 852841, 873181, 916327, 1018921, 1082401, 1092547, 1128121, 1152271, 1252697, 1293337, 1357441, 1373653, 1433407, 1493857, 1507963, 1509709, 1530787, 1537381, 1690501, 1735841, 1876393, 1987021, 2008597, 2100901, 2163001, 2181961, 2184571, 2205967, 2387797, 2510569, 2649029, 2746477, 2746589, 2944261, 2976487, 3059101, 3116107, 3539101, 3828001, 3985921, 4209661, 4335241, 4360621, 4361389, 5489641, 6027193, 6189121, 6255341, 6309901, 8231653, 8725753, 10004681, 10031653, 10033777, 10267951, 10802017, 12490201, 12599233, 12932989, 13073941, 14154337, 14676481, 17327773, 17895697, 18736381, 19384289, 20140129, 24904153, 26470501, 29111881, 31405501, 31794241, 32285041, 36307981, 46045117, 50201089, 53711113, 56052361, 61377109, 62176661, 64377991, 74945953, 79624621, 82929001, 82995421, 83083001, 84350561, 95053249, 96916279, 118901521, 171454321, 172947529, 183739141, 193638337, 217123069, 288120421, 308448649, 366652201, 427294141, 434042801, 492559141, 578595989, 710408917, 771043201, 775368901, 1223884969, 1269295201, 1299963601, 1632785701, 1732924001, 1772267281, 2344578077, 2509198669, 2598933481, 2656296091, 2882370481, 3313196881, 3423222757, 4034969401, 4421207701, 4550912389, 4563568819, 5073193501, 5278692481, 6051675913, 6825681757, 6891991489, 7112441977, 7148526337, 7885412221, 8346731851, 9030158341, 9293756581, 10277275681, 11346205609, 11411590009, 12372019801, 13468994941, 13673254951, 15999856237, 17063111801, 17714324629, 19964068741, 23707055737, 27278026129, 30923424001, 47122273801, 52396612381, 82380774001, 100264053529, 192739365541, 256946186881, 476407634761, 694902524401, 769888667161, 1493850868921, 5590443472129, 15221798510161, 21283744186021, 24567360229441, 26376200040373, 37677897416641, 51974855184001, 168915985617601, 195429852420661, 211900752829081, 474688401423121, 834577931805601
