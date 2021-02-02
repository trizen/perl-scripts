#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 09 July 2018
# https://github.com/trizen

# Find (almost) all solutions to the quadratic congruence:
#   x^2 = a (mod n)

use 5.020;
use warnings;

use experimental qw(signatures);

use List::Util qw(uniq);
use Set::Product::XS qw(product);
use ntheory qw(factor_exp is_prime chinese);
use Math::AnyNum qw(:overload kronecker powmod valuation ipow);

sub tonelli_shanks ($n, $p) {

    $n %= $p;

    return $p if ($n == 0);

    my $q = $p - 1;
    my $s = valuation($q, 2);

    powmod($n, $q >> 1, $p) == $p - 1 and return;

    $s == 1
      and return powmod($n, ($p + 1) >> 2, $p);

    $q >>= $s;

    my $z = 1;
    for (my $i = 2 ; $i < $p ; ++$i) {
        if (kronecker($i, $p) == -1) {
            $z = $i;
            last;
        }
    }

    my $c = powmod($z, $q, $p);
    my $r = powmod($n, ($q + 1) >> 1, $p);
    my $t = powmod($n, $q, $p);

    while (($t - 1) % $p != 0) {

        my $k = 1;
        my $v = $t * $t % $p;

        for (my $i = 1 ; $i < $s ; ++$i) {
            if (($v - 1) % $p == 0) {
                $k = powmod($c, 1 << ($s - $i - 1), $p);
                $s = $i;
                last;
            }
            $v = $v * $v % $p;
        }

        $r = $r * $k % $p;
        $c = $k * $k % $p;
        $t = $t * $c % $p;
    }

    return $r;
}

sub sqrt_mod_n ($z, $n) {

    if ($n <= 1) {    # no solutions for n<=1
        return;
    }

    $z %= $n;

    if ($z == 0) {
        return 0;
    }

    if (!($n & 1)) {    # n is even

        if (!($n & ($n - 1))) {    # n is a power of two

            if ($n == 2) {
                return (1) if ($z & 1);
                return;
            }

            if ($n == 4) {
                return (1, 3) if ($z % 4 == 1);
                return;
            }

            if ($n == 8) {
                return (1, 3, 5, 7) if ($z % 8 == 1);
                return;
            }

            if ($z == 1) {
                return (1, ($n >> 1) - 1, ($n >> 1) + 1, $n - 1);
            }
        }

        my @roots;
        my $k = valuation($n, 2);

        foreach my $s (sqrt_mod_n($z, $n >> 1)) {

            my $i = ((($s * $s - $z) >> ($k - 1)) % 2);
            my $r = ($s + ($i << ($k - 2)));

            if (($r * $r) % $n == $z) {
                push(@roots, $r, $n - $r);
            }
        }

        return sort { $a <=> $b } uniq(@roots);
    }

    if (is_prime($n)) {
        my $r = tonelli_shanks($z, $n) // return;
        return sort { $a <=> $b } ($r, $n - $r);
    }

    my @pe = factor_exp($n);    # factorize `n` into prime powers

    if (@pe == 1) {
        my $p = Math::AnyNum->new($pe[0][0]);
        my $x = tonelli_shanks($z, $p) // return;
        my $r = $n / $p;
        my $e = ($n - 2 * $r + 1) >> 1;
        my $t = (powmod($x, $r, $n) * powmod($z, $e, $n)) % $n;
        return if ($t == 0);
        return sort { $a <=> $b } ($t, $n - $t);
    }

    my @chinese;

    foreach my $p (@pe) {
        my $m = ipow($p->[0], $p->[1]);
        my @r = sqrt_mod_n($z, $m);
        push @chinese, [map { [$_, $m] } @r];
    }

    my @roots;

    product {
        push @roots, chinese(@_);
    } @chinese;

    return sort { $a <=> $b } uniq(grep { ($_ * $_) % $n == $z } @roots);
}

my @tests = (
    [1104, 6630],
    [2641, 4465],
    [993,  2048],
    [472,   972],
    [441,   920],
    [841,   905],
    [289,   992],
);

sub bf_sqrtmod ($z, $n) {
    grep { ($_ * $_) % $n == $z } 1 .. $n;
}

foreach my $t (@tests) {
    my @r = sqrt_mod_n($t->[0], $t->[1]);
    say "x^2 = $t->[0] (mod $t->[1]) = {", join(', ', @r), "}";
    die "error1 for (@$t) -- @r" if (@r != grep { ($_ * $_) % $t->[1] == $t->[0] } @r);
    die "error2 for (@$t) -- @r" if (join(' ', @r) ne join(' ', bf_sqrtmod($t->[0], $t->[1])));
}

say '';

# The algorithm also works for arbitrary large integers
say join(' ', sqrt_mod_n(13**18 * 5**7 - 1, 13**18 * 5**7));    #=> 633398078861605286438568 2308322911594648160422943 6477255756527023177780182 8152180589260066051764557

foreach my $n (1 .. 100) {
    my $m = int(rand(10000));
    my $z = int(rand($m));

    my @a1 = sqrt_mod_n($z, $m);
    my @a2 = bf_sqrtmod($z, $m);

    if ("@a1" ne "@a2") {
        warn "\nerror for ($z, $m):\n\t(@a1) != (@a2)\n";
    }
}

say '';

# Too few solutions for some inputs
say 'x^2 = 1701 (mod 6300) = {' . join(' ', sqrt_mod_n(1701, 6300)) . '}';
say 'x^2 = 1701 (mod 6300) = {' . join(', ', bf_sqrtmod(1701, 6300)) . '}';

# No solutions for some inputs (although solutions do exist)
say join(' ', sqrt_mod_n(306, 810));
say join(' ', sqrt_mod_n(2754, 6561));
say join(' ', sqrt_mod_n(17640, 48465));

__END__
x^2 = 1104 (mod 6630) = {642, 1152, 1968, 2478, 4152, 4662, 5478, 5988}
x^2 = 2641 (mod 4465) = {1501, 2071, 2394, 2964}
x^2 = 993 (mod 2048) = {369, 655, 1393, 1679}
x^2 = 472 (mod 972) = {38, 448, 524, 934}
x^2 = 441 (mod 920) = {21, 71, 159, 209, 251, 301, 389, 439, 481, 531, 619, 669, 711, 761, 849, 899}
x^2 = 841 (mod 905) = {29, 391, 514, 876}
x^2 = 289 (mod 992) = {17, 79, 417, 479, 513, 575, 913, 975}
