#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 19 January 2017
# https://github.com/trizen

# A concept for a new pseudorandom number generator,
# based on the idea of the RSA encryption algorithm.

# Under development and analysis...

use 5.010;
use strict;
use warnings;

use Math::BigNum;
use ntheory qw(random_strong_prime);

{
    my $p = Math::BigNum->new(random_strong_prime(128));
    my $q = Math::BigNum->new(random_strong_prime(128));

    my $n = $p * $q;
    my $h = $n >> 1;

    my $min = Math::BigNum->new(65537);
    my $phi = ($p - 1) * ($q - 1);

    my $e;
#<<<
    do {
        $e = $min->irand($n);
    } until (
            $e < $phi
        and $e->gcd($phi) == 1
        and ($e - 1)->gcd($p - 1) == 2
        and ($e - 1)->gcd($q - 1) == 2
    );
#>>>

    sub RSA_PRNG {
        my ($seed) = @_;

        my $state = Math::BigNum->new(abs($seed));

        sub {
            $state = (($h * $state) & $h)->modpow($e, $n) & 0x7fff_ffff;
        };
    }
}

my $rand = RSA_PRNG(42);

foreach my $i (1 .. 20) {
     say $rand->();
}
