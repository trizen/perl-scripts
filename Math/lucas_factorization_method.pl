#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 13 October 2018
# https://github.com/trizen

# A new integer factorization method, using the Lucas U and V sequences.

# Inspired by the BPSW primality test.

# See also:
#   https://en.wikipedia.org/wiki/Lucas_sequence
#   https://en.wikipedia.org/wiki/Lucas_pseudoprime
#   https://en.wikipedia.org/wiki/Baillie%E2%80%93PSW_primality_test

use 5.020;
use warnings;

use experimental qw(signatures);

use Math::AnyNum qw(:overload bit_scan1 is_power kronecker gcd prod);
use Math::Prime::Util::GMP qw(lucas_sequence consecutive_integer_lcm random_nbit_prime);

sub lucas_factorization ($n, $B) {

    return 1 if $n <= 2;
    return 1 if is_power($n);

    my ($P, $Q) = (1, 0);

    for (my $k = 2 ; ; ++$k) {
        my $D = (-1)**$k * (2 * $k + 1);

        if (kronecker($D, $n) == -1) {
            $Q = (1 - $D) / 4;
            last;
        }
    }

    my $d = Math::AnyNum->new(consecutive_integer_lcm($B));
    my $s = bit_scan1($d);

    my ($U, $V) = lucas_sequence($n, $P, $Q, $d);

    foreach my $f (sub { gcd($U, $n) }, sub { gcd($V - 2, $n) }) {
        my $g = $f->();
        return $g if ($g > 1 and $g < $n);
    }

    return 1;
}

say lucas_factorization(257221 * 470783,               700);     #=> 470783           (p+1 is  700-smooth)
say lucas_factorization(333732865481 * 1632480277613,  3000);    #=> 333732865481     (p-1 is 3000-smooth)
say lucas_factorization(1124075136413 * 3556516507813, 4000);    #=> 1124075136413    (p+1 is 4000-smooth)
say lucas_factorization(6555457852399 * 7864885571993, 700);     #=> 6555457852399    (p-1 is  700-smooth)
say lucas_factorization(7553377229 * 588103349,        800);     #=> 7553377229       (p+1 is  800-smooth)

say "\n=> More tests:";

foreach my $k (10 .. 50) {

    my $n = prod(map { random_nbit_prime($k) } 1 .. 2);
    my $p = lucas_factorization($n, 2 * $n->ilog2**2);

    if ($p > 1 and $p < $n) {
        say "$n = $p * ", $n / $p;
    }
}

__END__
36815861 = 6199 * 5939
748527379 = 31151 * 24029
2205610861 = 46279 * 47659
6464972083 = 72623 * 89021
42908134667 = 165037 * 259991
144064607993 = 324589 * 443837
14055375555899 = 3773629 * 3724631
34326163013579 = 4942513 * 6945083
635676232543327 = 28513789 * 22293643
4228743692662373 = 64463821 * 65598713
44525895097265171 = 211263823 * 210759677
88671631232856109 = 269999071 * 328414579
8445394419907066249 = 3185955247 * 2650820167
508484280918603770621 = 17377315313 * 29261383117
12301305131668154065127 = 91341582047 * 134673659641
8834277945256453860289739 = 2536339835969 * 3483081336331
