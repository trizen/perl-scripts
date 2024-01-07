#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 March 2023
# https://github.com/trizen

# Generate all the squarefree k-omega strong Fermat pseudoprimes in range [A,B] to multiple given bases. (not in sorted order)

# See also:
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.036;
use ntheory qw(:all);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub squarefree_strong_fermat_pseudoprimes_in_range ($A, $B, $k, $bases) {

    $A = vecmax($A, pn_primorial($k));
    $A > $B and return;

    my @bases     = @$bases;
    my $bases_lcm = lcm(@bases);

    my @list;

    sub ($m, $L, $lo, $k) {

        my $hi = rootint(divint($B, $m), $k);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            $lo = vecmax($lo, divceil($A, $m));
            $lo > $hi && return;

            my $t = invmod($m, $L) // return;
            $t > $hi && return;
            $t += $L * divceil($lo - $t, $L) if ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {
                if (is_prime($p) and $bases_lcm % $p != 0 and $m % $p != 0) {
                    my $v = $m * $p;
                    if (is_strong_pseudoprime($v, @bases)) {
                        push(@list, $v);
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            $bases_lcm % $p == 0 and next;

            my $lcm = lcm(map { znorder($_, $p) } @bases);
            gcd($m, $lcm) == 1 or next;

            __SUB__->($m * $p, lcm($L, $lcm), $p + 1, $k - 1);
        }
      }
      ->(1, 1, 2, $k);

    return sort { $a <=> $b } @list;
}

# Generate all the strong Fermat pseudoprimes to base 2,3 in range [1, 54029741]

my $from  = 1;
my $upto  = 54029741;
my @bases = (2, 3);

my @arr;
foreach my $k (2 .. 100) {
    last if pn_primorial($k) > $upto;
    push @arr, squarefree_strong_fermat_pseudoprimes_in_range($from, $upto, $k, \@bases);
}

say join(', ', sort { $a <=> $b } @arr);

__END__
1373653, 1530787, 1987021, 2284453, 3116107, 5173601, 6787327, 11541307, 13694761, 15978007, 16070429, 16879501, 25326001, 27509653, 27664033, 28527049, 54029741
