#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 23 December 2023
# https://github.com/trizen

# Generate all the squarefree k-omega strong Fermat pseudoprimes in range [A,B] to multiple given bases. (not in sorted order)

# See also:
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(:all);
use experimental qw(signatures);

sub k_squarefree_strong_fermat_pseudoprimes_in_range ($A, $B, $k, $bases, $callback) {

    $A = vecmax($A, pn_primorial($k));

    my @bases     = @$bases;
    my $bases_lcm = lcm(@bases);

    $A = Math::GMPz->new("$A");
    $B = Math::GMPz->new("$B");

    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    my $generator = sub ($m, $L, $lo, $k) {

        Math::GMPz::Rmpz_tdiv_q($u, $B, $m);
        Math::GMPz::Rmpz_root($u, $u, $k);

        my $hi = Math::GMPz::Rmpz_get_ui($u);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            Math::GMPz::Rmpz_cdiv_q($u, $A, $m);

            if (Math::GMPz::Rmpz_fits_ulong_p($u)) {
                $lo = vecmax($lo, Math::GMPz::Rmpz_get_ui($u));
            }
            elsif (Math::GMPz::Rmpz_cmp_ui($u, $lo) > 0) {
                if (Math::GMPz::Rmpz_cmp_ui($u, $hi) > 0) {
                    return;
                }
                $lo = Math::GMPz::Rmpz_get_ui($u);
            }

            if ($lo > $hi) {
                return;
            }

            Math::GMPz::Rmpz_invert($v, $m, $L);

            if (Math::GMPz::Rmpz_cmp_ui($v, $hi) > 0) {
                return;
            }

            if (Math::GMPz::Rmpz_fits_ulong_p($L)) {
                $L = Math::GMPz::Rmpz_get_ui($L);
            }

            my $t = Math::GMPz::Rmpz_get_ui($v);
            $t > $hi && return;
            $t += $L while ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {

                is_prime($p) || next;
                $bases_lcm % $p == 0 and next;

                Math::GMPz::Rmpz_mul_ui($v, $m, $p);
                Math::GMPz::Rmpz_sub_ui($u, $v, 1);
                if (vecall { is_strong_pseudoprime($v, $_) } @bases) {
                    $callback->(Math::GMPz::Rmpz_init_set($v));
                }
            }

            return;
        }

        my $t   = Math::GMPz::Rmpz_init();
        my $lcm = Math::GMPz::Rmpz_init();

        foreach my $p (@{primes($lo, $hi)}) {

            $bases_lcm % $p == 0 and next;

            my $z = lcm(map { znorder($_, $p) } @bases);
            Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $m, $z) == 1 or next;
            Math::GMPz::Rmpz_lcm_ui($lcm, $L, $z);
            Math::GMPz::Rmpz_mul_ui($t, $m, $p);

            __SUB__->($t, $lcm, $p + 1, $k - 1);
        }
    };

    $generator->(Math::GMPz->new(1), Math::GMPz->new(1), 2, $k);
}

sub squarefree_strong_fermat_pseudoprimes_in_range ($from, $upto, $bases) {

    my @arr;

    for (my $k = 2 ; ; ++$k) {
        last if pn_primorial($k) > $upto;
        k_squarefree_strong_fermat_pseudoprimes_in_range($from, $upto, $k, $bases, sub ($n) { push @arr, $n });
    }

    @arr = sort { $a <=> $b } @arr;
    return @arr;
}

my @bases = (17, 31);

my $lo = Math::GMPz->new(2);
my $hi = 2 * $lo;

say ":: Searching for the smallest strong pseudoprime to bases: (@bases)";

while (1) {

    say ":: Sieving range: [$lo, $hi]";
    my @arr = squarefree_strong_fermat_pseudoprimes_in_range($lo, $hi, \@bases);

    if (@arr) {
        say "\nFound: $arr[0]";
        say "All terms: @arr\n" if (@arr > 1);
        last;
    }

    $lo = $hi + 1;
    $hi = 2 * $lo;
}

__END__
:: Searching for the smallest strong pseudoprime to bases: (17 31)
:: Sieving range: [2, 4]
:: Sieving range: [5, 10]
:: Sieving range: [11, 22]
:: Sieving range: [23, 46]
:: Sieving range: [47, 94]
:: Sieving range: [95, 190]
:: Sieving range: [191, 382]
:: Sieving range: [383, 766]
:: Sieving range: [767, 1534]
:: Sieving range: [1535, 3070]
:: Sieving range: [3071, 6142]
:: Sieving range: [6143, 12286]
:: Sieving range: [12287, 24574]
:: Sieving range: [24575, 49150]
:: Sieving range: [49151, 98302]
:: Sieving range: [98303, 196606]
:: Sieving range: [196607, 393214]

Found: 197209
All terms: 197209 269011

perl script.pl  0.19s user 0.01s system 98% cpu 0.205 total
