#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 August 2022
# https://github.com/trizen

# Generate all the Lucas-Carmichael numbers with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub divceil ($x,$y) {   # ceil(x/y)
    my $q = divint($x, $y);
    (mulint($q, $y) == $x) ? $q : ($q+1);
}

sub lucas_carmichael_numbers_in_range ($A, $B, $k, $callback) {

    $A = vecmax($A, pn_primorial($k));

    sub ($m, $lambda, $p, $k, $u = undef, $v = undef) {

        if ($k == 1) {

            forprimes {
                my $t = mulint($m, $_);
                if (modint($t+1, $lambda) == 0 and modint($t+1, $_+1) == 0) {
                    $callback->($t);
                }
            } $u, $v;

            return;
        }

        my $s = rootint(divint($B, $m), $k);

        for(my $r; $p <= $s; $p = $r) {

            $r = next_prime($p);
            my $t = mulint($m, $p);
            my $L = lcm($lambda, $p+1);

            ($p >= 3 and gcd($L, $t) == 1) or next;

            # gcd($t, divisor_sum($t)) == 1 or die "$t: not Lucas-cyclic";

            my $u = divceil($A, $t);
            my $v = divint($B, $t);

            if ($u <= $v) {
                __SUB__->($t, $L, $r, $k - 1, (($k==2 && $r>$u) ? $r : $u), $v);
            }
        }
    }->(1, 1, 3, $k);
}

# Generate all the Lucas-Carmichael numbers with 5 prime factors in the range [100, 10^8]

my $k    = 5;
my $from = 100;
my $upto = 1e8;

my @arr; lucas_carmichael_numbers_in_range($from, $upto, $k, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
588455, 1010735, 2276351, 2756159, 4107455, 4874639, 5669279, 6539819, 8421335, 13670855, 16184663, 16868159, 21408695, 23176439, 24685199, 25111295, 26636687, 30071327, 34347599, 34541639, 36149399, 36485015, 38999519, 39715319, 42624911, 43134959, 49412285, 49591919, 54408959, 54958799, 57872555, 57953951, 64456223, 66709019, 73019135, 77350559, 78402815, 82144799, 83618639, 86450399, 93277079, 96080039, 98803439
