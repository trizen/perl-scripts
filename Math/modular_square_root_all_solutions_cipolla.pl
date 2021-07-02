#!/usr/bin/perl

# Find all the solutions to the quadratic congruence:
#   x^2 = a (mod n)

# Based on algorithm by Hugo van der Sanden:
#   https://github.com/danaj/Math-Prime-Util/pull/55

# See also:
#   https://rosettacode.org/wiki/Cipolla's_algorithm

use 5.020;
use strict;
use warnings;

use Test::More tests => 12;

use experimental qw(signatures);
use ntheory qw(factor_exp chinese forsetproduct kronecker);
use Math::AnyNum qw(:overload powmod ipow);

sub cipolla ($n, $p) {

    $n %= $p;

    return undef if kronecker($n, $p) != 1;

    if ($p == 2) {
        return ($n & 1);
    }

    my $w2;
    my $a = 0;

    $a++ until kronecker(($w2 = ($a * $a - $n) % $p), $p) < 0;

    my %r = (x => 1, y => 0);
    my %s = (x => $a, y => 1);
    my $i = $p + 1;

    while (1 <= ($i >>= 1)) {
        %r = (
              x => (($r{x} * $s{x} + $r{y} * $s{y} * $w2) % $p),
              y => (($r{x} * $s{y} + $s{x} * $r{y}) % $p)
             )
          if ($i & 1);
        %s = (
              x => (($s{x} * $s{x} + $s{y} * $s{y} * $w2) % $p),
              y => (($s{x} * $s{y} + $s{x} * $s{y}) % $p)
             );
    }

    $r{y} ? undef : $r{x};
}

sub sqrtmod_prime_power ($n, $p, $e) {    # sqrt(n) modulo a prime power p^e

    if ($e == 1) {
        return cipolla($n, $p);
    }

    # t = p^(k-1)
    my $t = ipow($p, $e - 1);

    # pp = p^k
    my $pp = $t * $p;

    # n %= p^k
    $n %= $pp;

    if ($n == 0) {
        return 0;
    }

    if ($p == 2) {

        if ($e == 1) {
            return (($n & 1) ? 1 : 0);
        }

        if ($e == 2) {
            return (($n % 4 == 1) ? 1 : 0);
        }

        ($n % 8 == 1) || return;

        my $r = __SUB__->($n, $p, $e - 1) // return;

        # (((r^2 - n) / 2^(e-1))%2) * 2^(e-2) + r
        return ((((($r * $r - $n) >> ($e - 1)) % 2) << ($e - 2)) + $r);
    }

    my $s = cipolla($n, $p) // return;

    # u = (p^k - 2*(p^(k-1)) + 1) / 2
    my $u = ($pp - 2 * $t + 1) >> 1;

    # sqrtmod(a, p^k) = (powmod(sqrtmod(a, p), p^(k-1), p^k) * powmod(a, u, p^k)) % p^k
    (powmod($s, $t, $pp) * powmod($n, $u, $pp)) % $pp;
}

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

        my $q = sqrtmod_prime_power($A, $p, $k) // return;

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

my @tests = ([1104, 6630], [2641, 4465], [993, 2048], [472, 972], [441, 920], [841, 905], [289, 992]);

sub bf_sqrtmod ($z, $n) {
    grep { ($_ * $_) % $n == $z } 0 .. $n - 1;
    #ntheory::allsqrtmod($z, $n);
}

foreach my $t (@tests) {
    my @r = sqrtmod_all($t->[0], $t->[1]);
    say "x^2 = $t->[0] (mod $t->[1]) = {", join(', ', @r), "}";
    die "error1 for (@$t) -- @r" if (@r != grep { ($_ * $_) % $t->[1] == $t->[0] } @r);
    die "error2 for (@$t) -- @r" if (join(' ', @r) ne join(' ', bf_sqrtmod($t->[0], $t->[1])));
}

say '';

# The algorithm also works for arbitrary large integers
say join(' ', sqrtmod_all(13**18 * 5**7 - 1, 13**18 * 5**7));

foreach my $n (1 .. 100) {
    my $m = int(rand(10000));
    my $z = int(rand($m));

    my @a1 = sqrtmod_all($z, $m);
    my @a2 = bf_sqrtmod($z, $m);

    if ("@a1" ne "@a2") {
        warn "\nerror for ($z, $m):\n\t(@a1) != (@a2)\n";
    }
}

say '';

# Too few solutions for some inputs
say 'x^2 = 1701 (mod 6300) = {' . join(' ',  sqrtmod_all(1701, 6300)) . '}';
say 'x^2 = 1701 (mod 6300) = {' . join(', ', bf_sqrtmod(1701, 6300)) . '}';

# No solutions for some inputs (although solutions do exist)
say join(' ', sqrtmod_all(306,   810));
say join(' ', sqrtmod_all(2754,  6561));
say join(' ', sqrtmod_all(17640, 48465));

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

is_deeply([sqrtmod_all(-1, 13**18 * 5**7)],
          [633398078861605286438568, 2308322911594648160422943, 6477255756527023177780182, 8152180589260066051764557]);
