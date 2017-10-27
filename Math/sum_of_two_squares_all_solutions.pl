#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 October 2017
# https://github.com/trizen

# A recursive algorithm for finding all the non-negative integer solutions to the equation:
#   a^2 + b^2 = n
# for any given positive integer `n` for which such a solution exists.

# Example:
#   99025 = 41^2 + 312^2 = 48^2 + 311^2 = 95^2 + 300^2 = 104^2 + 297^2 = 183^2 + 256^2 = 220^2 + 225^2

# This algorithm is efficient when the factorization of `n` can be computed.

# Blog post:
#   https://trizenx.blogspot.com/2017/10/representing-integers-as-sum-of-two.html

# See also:
#   https://oeis.org/A001481

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Set::Product::XS qw(product);
use ntheory qw(sqrtmod factor_exp chinese);

sub sum_of_two_squares_solutions ($n) {

    $n == 0 and return [0, 0];

    my $prod1 = 1;
    my $prod2 = 1;

    my @prime_powers;

    foreach my $f (factor_exp($n)) {
        if ($f->[0] % 4 == 3) {    # p = 3 (mod 4)
            $f->[1] % 2 == 0 or return;    # power must be even
            $prod2 *= $f->[0]**($f->[1] >> 1);
        }
        elsif ($f->[0] == 2) {             # p = 2
            if ($f->[1] % 2 == 0) {        # power is even
                $prod2 *= $f->[0]**($f->[1] >> 1);
            }
            else {                         # power is odd
                $prod1 *= $f->[0];
                $prod2 *= $f->[0]**(($f->[1] - 1) >> 1);
                push @prime_powers, [$f->[0], 1];
            }
        }
        else {                             # p = 1 (mod 4)
            $prod1 *= $f->[0]**$f->[1];
            push @prime_powers, $f;
        }
    }

    $prod1 == 1 and return [$prod2, 0];
    $prod1 == 2 and return [$prod2, $prod2];

    my %table;
    foreach my $f (@prime_powers) {
        my $pp = $f->[0]**$f->[1];
        my $r = sqrtmod($pp - 1, $pp);
        push @{$table{$pp}}, [$r, $pp], [$pp - $r, $pp];
    }

    my @square_roots;

    product {
        push @square_roots, chinese(@_);
    } values %table;

    my @solutions;

    foreach my $r (@square_roots) {

        my $s = $r;
        my $q = $prod1;

        while ($s * $s > $prod1) {
            ($s, $q) = ($q % $s, $s);
        }

        push @solutions, [$prod2 * $s, $prod2 * ($q % $s)];
    }

    foreach my $f (@prime_powers) {
        for (my $i = $f->[1] % 2; $i < $f->[1]; $i += 2) {

            my $sq = $f->[0]**(($f->[1] - $i) >> 1);
            my $pp = $f->[0]**($f->[1] - $i);

            push @solutions, map {
                [map { $sq * $prod2 * $_ } @$_]
            } __SUB__->($prod1 / $pp);
        }
    }

    return sort { $a->[0] <=> $b->[0] } do {
        my %seen;
        grep { !$seen{$_->[0]}++ } map {
            [sort { $a <=> $b } @$_]
        } @solutions;
    };
}

foreach my $n (1 .. 1e5) {
    (my @solutions = sum_of_two_squares_solutions($n)) || next;

    say "$n = " . join(' = ', map { "$_->[0]^2 + $_->[1]^2" } @solutions);

    # Verify solutions
    foreach my $solution (@solutions) {
        if ($n != $solution->[0]**2 + $solution->[1]**2) {
            die "error for $n: (@$solution)\n";
        }
    }
}

__END__
999826 = 99^2 + 995^2 = 315^2 + 949^2 = 525^2 + 851^2 = 699^2 + 715^2
999828 = 318^2 + 948^2
999844 = 312^2 + 950^2 = 410^2 + 912^2
999848 = 62^2 + 998^2
999850 = 43^2 + 999^2 = 321^2 + 947^2 = 565^2 + 825^2
999853 = 387^2 + 922^2
999857 = 401^2 + 916^2 = 544^2 + 839^2
999860 = 154^2 + 988^2 = 698^2 + 716^2
999869 = 262^2 + 965^2 = 613^2 + 790^2
999881 = 341^2 + 940^2 = 484^2 + 875^2
999882 = 309^2 + 951^2 = 651^2 + 759^2
999890 = 421^2 + 907^2 = 473^2 + 881^2
999892 = 324^2 + 946^2
999898 = 213^2 + 977^2 = 697^2 + 717^2
999909 = 222^2 + 975^2 = 678^2 + 735^2
999914 = 667^2 + 745^2
999917 = 109^2 + 994^2
999937 = 44^2 + 999^2 = 89^2 + 996^2
999938 = 77^2 + 997^2
999940 = 126^2 + 992^2 = 178^2 + 984^2 = 306^2 + 952^2 = 448^2 + 894^2 = 578^2 + 816^2 = 696^2 + 718^2
999941 = 370^2 + 929^2 = 446^2 + 895^2
999944 = 638^2 + 770^2
999946 = 585^2 + 811^2
999949 = 243^2 + 970^2 = 290^2 + 957^2 = 450^2 + 893^2 = 493^2 + 870^2
999952 = 444^2 + 896^2
999953 = 568^2 + 823^2
999954 = 327^2 + 945^2 = 375^2 + 927^2
999956 = 500^2 + 866^2
999961 = 644^2 + 765^2
999962 = 239^2 + 971^2 = 541^2 + 841^2
999968 = 452^2 + 892^2
999970 = 247^2 + 969^2 = 627^2 + 779^2
999973 = 63^2 + 998^2 = 118^2 + 993^2 = 273^2 + 962^2 = 442^2 + 897^2 = 622^2 + 783^2 = 658^2 + 753^2
999981 = 141^2 + 990^2
999986 = 365^2 + 931^2 = 695^2 + 719^2
999997 = 194^2 + 981^2 = 454^2 + 891^2
1000000 = 0^2 + 1000^2 = 280^2 + 960^2 = 352^2 + 936^2 = 600^2 + 800^2
