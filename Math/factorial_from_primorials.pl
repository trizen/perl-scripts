#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 21 March 2019
# https://github.com/trizen

# Find the unique integer k such that the product of the primorials of all its prime factors, is equal to n!.

# Example:
#   a(10) = 5040 = 2^4 * 3^2 * 5 * 7

# By mapping each prime factor `p` to `primorial(p)`, we get:
#
#   primorial(2)^4 * primorial(3)^2 * primorial(5) * primorial(7) = 10!
#
# where `primorial(p)` is the product of primes <= p.

# OEIS sequence by Allan C. Wechsler (Mar 20 2019):
#   https://oeis.org/A307035

use 5.020;
use warnings;

use experimental qw(signatures);

use Math::GMPz;
use ntheory qw(:all);
use Math::Prime::Util::GMP;

my $UPTO  = 30;        # up to n-factorial
my $LIMIT = 10**14;    # search smooth numbers up to this limit

sub factorial_power ($n, $p) {
    ($n - vecsum(todigits($n, $p))) / ($p - 1);
}

my (%fac, %prim, %maxp);

forprimes {
    $maxp{$_} = 1 + (factorial_power($UPTO, $_) >> 1);
    $prim{$_} = Math::GMPz->new(Math::Prime::Util::GMP::primorial($_));
} $UPTO;

foreach my $n (1 .. $UPTO) {
    $fac{Math::Prime::Util::GMP::factorial($n)} = $n;
}

sub check_valuation ($n, $p) {
    valuation($n, $p) < $maxp{$p};
}

sub smooth_numbers ($limit, $primes) {

    my @h = (1);
    foreach my $p (@$primes) {

        say "Prime: $p";

        foreach my $n (@h) {
            if ($n * $p <= $limit and check_valuation($n, $p)) {
                push @h, $n * $p;
            }
        }
    }

    return \@h;
}

sub isok ($n) {
    my $t = Math::Prime::Util::GMP::vecprod(map { ($prim{$_->[0]})**$_->[1] } factor_exp($n));
    $fac{$t} // 0;
}

my $h = smooth_numbers($LIMIT, primes($UPTO));

say "\nFound: ", scalar(@$h), " terms";

foreach my $n (@$h) {
    if (my $k = isok($n)) {
        say "a($k) = $n -> ", join(' * ', map { "$_->[0]^$_->[1]" } factor_exp($n));
    }
}

__END__
a(1) = 1 ->
a(2) = 2 -> 2^1
a(3) = 3 -> 3^1
a(4) = 12 -> 2^2 * 3^1
a(5) = 20 -> 2^2 * 5^1
a(6) = 60 -> 2^2 * 3^1 * 5^1
a(7) = 84 -> 2^2 * 3^1 * 7^1
a(8) = 672 -> 2^5 * 3^1 * 7^1
a(9) = 1512 -> 2^3 * 3^3 * 7^1
a(10) = 5040 -> 2^4 * 3^2 * 5^1 * 7^1
a(11) = 7920 -> 2^4 * 3^2 * 5^1 * 11^1
a(12) = 47520 -> 2^5 * 3^3 * 5^1 * 11^1
a(13) = 56160 -> 2^5 * 3^3 * 5^1 * 13^1
a(14) = 157248 -> 2^6 * 3^3 * 7^1 * 13^1
a(15) = 393120 -> 2^5 * 3^3 * 5^1 * 7^1 * 13^1
a(16) = 6289920 -> 2^9 * 3^3 * 5^1 * 7^1 * 13^1
a(17) = 8225280 -> 2^9 * 3^3 * 5^1 * 7^1 * 17^1
a(18) = 37013760 -> 2^8 * 3^5 * 5^1 * 7^1 * 17^1
a(19) = 41368320 -> 2^8 * 3^5 * 5^1 * 7^1 * 19^1
a(20) = 275788800 -> 2^10 * 3^4 * 5^2 * 7^1 * 19^1
a(21) = 579156480 -> 2^9 * 3^5 * 5^1 * 7^2 * 19^1
a(22) = 1820206080 -> 2^10 * 3^5 * 5^1 * 7^1 * 11^1 * 19^1
a(23) = 2203407360 -> 2^10 * 3^5 * 5^1 * 7^1 * 11^1 * 23^1
a(24) = 26440888320 -> 2^12 * 3^6 * 5^1 * 7^1 * 11^1 * 23^1
a(25) = 73446912000 -> 2^12 * 3^4 * 5^3 * 7^1 * 11^1 * 23^1
a(26) = 173601792000 -> 2^13 * 3^4 * 5^3 * 7^1 * 13^1 * 23^1
a(27) = 585906048000 -> 2^10 * 3^7 * 5^3 * 7^1 * 13^1 * 23^1
a(28) = 3281073868800 -> 2^12 * 3^7 * 5^2 * 7^2 * 13^1 * 23^1
a(29) = 4137006182400 -> 2^12 * 3^7 * 5^2 * 7^2 * 13^1 * 29^1
a(30) = 20685030912000 -> 2^12 * 3^7 * 5^3 * 7^2 * 13^1 * 29^1
a(31) = 22111584768000 -> 2^12 * 3^7 * 5^3 * 7^2 * 13^1 * 31^1
a(32) = 707570712576000 -> 2^17 * 3^7 * 5^3 * 7^2 * 13^1 * 31^1
a(33) = 1667845251072000 -> 2^16 * 3^8 * 5^3 * 7^1 * 11^1 * 13^1 * 31^1
a(34) = 4362056810496000 -> 2^17 * 3^8 * 5^3 * 7^1 * 11^1 * 17^1 * 31^1
a(35) = 10178132557824000 -> 2^17 * 3^7 * 5^3 * 7^2 * 11^1 * 17^1 * 31^1
a(36) = 91603193020416000 -> 2^17 * 3^9 * 5^3 * 7^2 * 11^1 * 17^1 * 31^1
