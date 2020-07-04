#!/usr/bin/perl

# A new factorization algorithm for semiprimes, by estimating phi(n).

# The algorithm is called "Phi-Finder" and is due to Kyle Kloster (2010), described in his thesis:
#   Factoring a semiprime n by estimating φ(n)

# See also:
#   http://gregorybard.com/papers/phi_version_may_7.pdf

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Math::GMPz;
use ntheory qw(is_prime is_square sqrtint logint powmod random_nbit_prime);

sub phi_factor($n) {

    return ()   if $n <= 1;
    return ($n) if is_prime($n);

    if (is_square($n)) {
        return sqrtint($n);
    }

    $n = Math::GMPz->new($n);

    my $E  = $n - 2 * sqrtint($n) + 1;
    my $E0 = Math::GMPz->new(powmod(2, -$E, $n));

    my $L = logint($n, 2);
    my $i = 0;

    while ($E0 & ($E0 - 1)) {
        $E0 <<= $L;
        $E0 %= $n;
        ++$i;
    }

    my $t = 0;

    foreach my $k (0 .. $L) {
        if (powmod(2, $k, $n) == $E0) {
            $t = $k;
            last;
        }
    }

    my $phi = abs($i * $L - $E - $t);

    my $q = ($n - $phi + 1);
    my $p = ($q + sqrtint($q * $q - 4 * $n)) >> 1;

    return $p;
}

foreach my $k (10 .. 30) {

    my $n = Math::GMPz->new(random_nbit_prime($k)) * random_nbit_prime($k);
    my $p = phi_factor($n);

    say "$n = ", $p, ' * ', $n / $p;
}
