#!/usr/bin/perl

# Find all solutions to the quadratic congruence:
#   x^2 = a (mod n)

# Based on algorithm by Hugo van der Sanden:
#   https://github.com/danaj/Math-Prime-Util/pull/55

use 5.020;
use strict;
use warnings;

use Test::More tests => 11;

use experimental qw(signatures);
use Math::AnyNum qw(:overload ipow);
use ntheory qw(factor_exp sqrtmod forsetproduct chinese);

sub sqrtmod_all ($A, $N) {

    $A = Math::AnyNum->new("$A");
    $N = Math::AnyNum->new("$N");

    $N = -$N if ($N < 0);
    $N == 0 and return ();
    $N == 1 and return (0);
    $A = ($A % $N);

    my $sqrtmod_pk = sub ($A, $p, $k) {
        my $pk = ipow($p, $k);

        if ($A % $p == 0) {

            if ($A % $pk == 0) {
                my $low  = ipow($p, $k >> 1);
                my $high = ($k & 1) ? ($low * $p) : $low;
                return map { $high * $_ } 0 .. $low - 1;
            }

            my $A2 = $A / $p;
            return () if ($A2 % $p != 0);
            my $pj = $pk / $p;

            return map {
                my $q = $_;
                map { $q * $p + $_ * $pj } 0 .. $p - 1
            } __SUB__->($A2 / $p, $p, $k - 2);
        }

        my $q = sqrtmod($A, $pk) // eval {
            require Math::Sidef;
            Math::Sidef::sqrtmod($A, $pk);
        } || return;

        return ($q, $pk - $q) if ($p != 2);
        return ($q)           if ($k == 1);
        return ($q, $pk - $q) if ($k == 2);

        my $pj = ipow($p, $k - 1);
        my $q2 = ($q * ($pj - 1)) % $pk;

        return ($q, $pk - $q, $q2, $pk - $q2);
    };

    my @congruences;

    foreach my $pe (factor_exp($N)) {
        my ($p, $k) = @$pe;
        my $pk = ipow($p, $k);
        push @congruences, [map { [$_, $pk] } $sqrtmod_pk->($A, $p, $k)];
    }

    my @roots;

    forsetproduct {
        push @roots, chinese(@_);
    } @congruences;

    @roots = map  { Math::AnyNum->new($_) } @roots;
    @roots = grep { ($_ * $_) % $N == $A } @roots;
    @roots = sort { $a <=> $b } @roots;

    return @roots;
}

#<<<
is_deeply([sqrtmod_all(43, 97)],       [25, 72]);
is_deeply([sqrtmod_all(472, 972)],     [38, 448, 524, 934]);
is_deeply([sqrtmod_all(43, 41 * 97)],  [557, 1042, 2935, 3420]);
is_deeply([sqrtmod_all(1104, 6630)],   [642, 1152, 1968, 2478, 4152, 4662, 5478, 5988]);
is_deeply([sqrtmod_all(993, 2048)],    [369, 655, 1393, 1679]);
is_deeply([sqrtmod_all(441, 920)],     [21, 71, 159, 209, 251, 301, 389, 439, 481, 531, 619, 669, 711, 761, 849, 899]);
is_deeply([sqrtmod_all(841, 905)],     [29, 391, 514, 876]);
is_deeply([sqrtmod_all(289, 992)],     [17, 79, 417, 479, 513, 575, 913, 975]);
is_deeply([sqrtmod_all(306, 810)],     [66, 96, 174, 204, 336, 366, 444, 474, 606, 636, 714, 744]);
is_deeply([sqrtmod_all(2754, 6561)],   [126, 603, 855, 1332, 1584, 2061, 2313, 2790, 3042, 3519, 3771, 4248, 4500, 4977, 5229, 5706, 5958, 6435]);
is_deeply([sqrtmod_all(17640, 48465)], [2865, 7905, 8250, 13290, 19020, 24060, 24405, 29445, 35175, 40215, 40560, 45600]);
#>>>

say join', ', sqrtmod_all(-1, 13**18 * 5**7);    # 633398078861605286438568, 2308322911594648160422943, 6477255756527023177780182, 8152180589260066051764557
