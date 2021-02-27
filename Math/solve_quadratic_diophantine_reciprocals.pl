#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 February 2021
# https://github.com/trizen

# Algorithm for finding primitve solutions (x,y,z) with 1 <= x,y,z <= N and x <= y, to the Diophantine reciprocal equation:
#   1/x^2 + 1/y^2 = k/z^2

# A solution (x,y,z) is a primitive solution if gcd(x,y,z) = 1.

# It is easy to see that:
#   (x^2 + y^2)/k = v^4, for some integer v.

# Multiplying both sides by k, we have:
#   x^2 + y^2 = k * v^4

# By finding integer solutions (x,y) to the above Diophantine equation, we can then compute `z` as:
#   z = sqrt((x^2 * y^2 * k)/(x^2 + y^2))
#     = sqrt((x^2 * y^2) / v^4)

# We need to iterate over 1 <= v <= sqrt(N).

# See also:
#   https://projecteuler.net/problem=748

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);
use Set::Product::XS qw(product);

my %cache;

sub sum_of_two_squares_solutions ($n) {

    $n == 0 and return [0, 0];

    if (exists $cache{$n}) {
        return @{$cache{$n}};
    }

    my $prod1 = 1;
    my $prod2 = 1;

    my @prime_powers;

    foreach my $f (factor_exp($n)) {
        if ($f->[0] % 4 == 3) {    # p = 3 (mod 4)
            $f->[1] % 2 == 0 or return;    # power must be even
            $prod2 = mulint($prod2, powint($f->[0], $f->[1] >> 1));
        }
        elsif ($f->[0] == 2) {             # p = 2
            if ($f->[1] % 2 == 0) {        # power is even
                $prod2 = mulint($prod2, powint($f->[0], $f->[1] >> 1));
            }
            else {                         # power is odd
                $prod1 = mulint($prod1, $f->[0]);
                $prod2 = mulint($prod2, powint($f->[0], ($f->[1] - 1) >> 1));
                push @prime_powers, [$f->[0], 1];
            }
        }
        else {                             # p = 1 (mod 4)
            $prod1 = mulint($prod1, powint($f->[0], $f->[1]));
            push @prime_powers, $f;
        }
    }

    $prod1 == 1 and return [$prod2, 0];
    $prod1 == 2 and return [$prod2, $prod2];

    my %table;
    foreach my $f (@prime_powers) {

        my $pp = powint($f->[0], $f->[1]);
        my $r  = sqrtmod(-1, $pp);

        if (not defined($r)) {
            require Math::Sidef;
            $r = Math::Sidef::sqrtmod(-1, $pp);
        }

        push @{$table{$pp}}, [$r, $pp], [subint($pp, $r), $pp];
    }

    my @square_roots;

    product {
        push @square_roots, chinese(@_);
    } values %table;

    my @solutions;

    foreach my $r (@square_roots) {

        my $s = $r;
        my $q = $prod1;

        while (mulint($s, $s) > $prod1) {
            ($s, $q) = (modint($q, $s), $s);
        }

        push @solutions, [mulint($prod2, $s), mulint($prod2, modint($q, $s))];
    }

    foreach my $f (@prime_powers) {
        for (my $i = $f->[1] % 2 ; $i < $f->[1] ; $i += 2) {

            my $sq = powint($f->[0], ($f->[1] - $i) >> 1);
            my $pp = powint($f->[0], $f->[1] - $i);

            push @solutions, map {
                [map { vecprod($sq, $prod2, $_) } @$_]
            } __SUB__->(divint($prod1, $pp));
        }
    }

    @{
        $cache{$n} = [
            do {
                my %seen;
                grep { !$seen{$_->[0]}++ } map {
                    [sort { $a <=> $b } @$_]
                } @solutions;
            }
        ]
     };
}

sub S ($N, $k) {

    my $total = 0;
    my $limit = int(sqrt($N));

    my @solutions;

    foreach my $v (1 .. $limit) {

        my $w = powint($v, 4);

        foreach my $pair (sum_of_two_squares_solutions(mulint($k, $w))) {

            my ($x, $y) = @$pair;

            $y <= $N or next;

            my $t = vecprod($x, $x, $y, $y);

            modint($t, $w) == 0 or next;

            my $z = divint($t, $w);

            if (is_square($z)) {

                $z = sqrtint($z);
                $z <= $N or next;

                if (gcd($x, $y, $z) == 1) {
                    push @solutions, [$x, $y, $z];
                }
            }
        }
    }

    return @solutions;
}

my $N = 10000;
my $k = 5;

say <<"EOT";

:: Primitve solutions (x,y,z) with 1 <= x,y,z <= $N and x <= y, to equation:

    1/x^2 + 1/y^2 = $k/z^2
EOT

foreach my $triple (S($N, $k)) {
    my ($x, $y, $z) = @$triple;
    say "($x, $y, $z)";
}

__END__

:: Primitve solutions (x,y,z) with 1 <= x,y,z <= 10000 and x <= y, to equation:

    1/x^2 + 1/y^2 = 5/z^2

(1, 2, 2)
(10, 55, 22)
(247, 286, 418)
(26, 377, 58)
(374, 527, 682)
(17, 646, 38)
(950, 1025, 1558)
(551, 1798, 1178)
(638, 1769, 1342)
(2146, 2183, 3422)
(407, 3034, 902)
(2378, 2911, 4118)
(902, 3649, 1958)
(583, 6254, 1298)
(3286, 5353, 6262)
(5002, 6649, 8938)
(2318, 7991, 4978)
(2015, 9230, 4402)
(5135, 7930, 9638)
