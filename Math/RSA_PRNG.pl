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

use Math::AnyNum qw(gcd irand powmod);
use ntheory qw(random_strong_prime);

{
    my $p = Math::AnyNum->new(random_strong_prime(256));
    my $q = Math::AnyNum->new(random_strong_prime(256));

    my $n = $p * $q;
    my $phi = ($p - 1) * ($q - 1);

    my $e;
#<<<
    do {
        $e = irand(65537, $n);
    } until (
            $e < $phi
        and gcd($e,     $phi  ) == 1
        and gcd($e - 1, $p - 1) == 2
        and gcd($e - 1, $q - 1) == 2
    );
#>>>

    sub RSA_PRNG {
        my ($seed) = @_;

        my $state = abs($seed);

        sub {
            $state = powmod($state + 11, $e, $n) & 0x7fff_ffff;
        };
    }
}

my $rand = RSA_PRNG(42);

foreach my $i (1 .. 20) {
    say $rand->();
}
