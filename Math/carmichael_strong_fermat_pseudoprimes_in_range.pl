#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 24 September 2022
# https://github.com/trizen

# Generate all the Carmichael numbers with n prime factors in a given range [A,B] that are also strong Fermat pseudoprimes to a given base. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub divceil ($x,$y) {   # ceil(x/y)
    my $q = divint($x, $y);
    ($q*$y == $x) ? $q : ($q+1);
}

sub carmichael_numbers_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k+1)>>1);

    if ($A > $B) {
        return;
    }

    my $generator = sub ($m, $lambda, $p, $k, $k_exp, $congr, $u = undef, $v = undef) {

        if ($k == 1) {

            forprimes {
                my $t = $m*$_;
                if (($t-1)%$lambda == 0 and ($t-1)%($_-1) == 0) {
                    my $valuation = valuation($_ - 1, 2);
                    if ($valuation > $k_exp and powmod($base, (($_ - 1) >> $valuation) << $k_exp, $_) == ($congr % $_)) {
                        $callback->($t);
                    }
                }
            } $u, $v;

            return;
        }

        my $s = rootint(divint($B, $m), $k);

        for (my $r; $p <= $s; $p = $r) {

            $r = next_prime($p);

            my $L = lcm($lambda, $p-1);
            gcd($L, $m) == 1 or next;

            my $valuation = valuation($p - 1, 2);
            $valuation > $k_exp                                                    or next;
            powmod($base, (($p - 1) >> $valuation) << $k_exp, $p) == ($congr % $p) or next;

            # gcd($m*$p, euler_phi($m*$p)) == 1 or die "$m*$p: not cyclic";

            my $t = $m*$p;
            my $u = divceil($A, $t);
            my $v = divint($B, $t);

            if ($u <= $v) {
                __SUB__->($t, $L, $r, $k - 1, $k_exp, $congr, (($k==2 && $r>$u) ? $r : $u), $v);
            }
        }
    };

    # Case where 2^d == 1 (mod p), where d is the odd part of p-1.
    $generator->(1, 1, 3, $k, 0, 1);

    # Cases where 2^(d * 2^v) == -1 (mod p), for some v >= 0.
    foreach my $v (0 .. logint($B, 2)) {
        $generator->(1, 1, 3, $k, $v, -1);
    }
}

# Generate all the 3-Carmichael numbers in the range [1, 10^8] that are also strong pseudoprimes to base 2.

my $k    = 3;
my $base = 2;
my $from = 1;
my $upto = 1e8;

my @arr; carmichael_numbers_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
15841, 29341, 52633, 252601, 314821, 1909001, 3581761, 4335241, 5049001, 5444489, 15247621, 29111881, 35703361, 36765901, 53711113, 68154001, 99036001
