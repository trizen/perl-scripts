#!/usr/bin/perl

# Author: Trizen
# Date: 12 March 2022
# https://github.com/trizen

# A new integer factorization method, using the binary exponentiation algorithm with modular exponentiation.

# We call it the "Modular Binary Exponentiation" (MBE) factorization method.

# Similar in flavor to the Pollard's p-1 method.

# See also:
#   https://en.wikipedia.org/wiki/Exponentiation_by_squaring

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::GMPz;

sub MBE_factor ($n, $max_k = 1000) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $t = Math::GMPz::Rmpz_init();
    my $g = Math::GMPz::Rmpz_init();

    my $a = Math::GMPz::Rmpz_init();
    my $b = Math::GMPz::Rmpz_init();
    my $c = Math::GMPz::Rmpz_init();

    foreach my $k (1 .. $max_k) {

        #say "Trying k = $k";

        Math::GMPz::Rmpz_div_ui($t, $n, $k + 1);

        Math::GMPz::Rmpz_set($a, $t);
        Math::GMPz::Rmpz_set($b, $t);
        Math::GMPz::Rmpz_set_ui($c, 1);

        foreach my $i (0 .. Math::GMPz::Rmpz_sizeinbase($b, 2) - 1) {

            if (Math::GMPz::Rmpz_tstbit($b, $i)) {

                Math::GMPz::Rmpz_powm($c, $a, $c, $n);
                Math::GMPz::Rmpz_sub_ui($g, $c, 1);
                Math::GMPz::Rmpz_gcd($g, $g, $n);

                if (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0 and Math::GMPz::Rmpz_cmp($g, $n) < 0) {
                    return $g;
                }
            }

            Math::GMPz::Rmpz_powm($a, $a, $a, $n);
        }
    }

    return;
}

say MBE_factor("3034271543203");                                    #=> 604727
say MBE_factor("43120971427631");                                   #=> 5501281
say MBE_factor("1548517437362569");                                 #=> 24970961
say MBE_factor("18446744073709551617");                             #=> 274177
say MBE_factor("5889680315647781787273935275179391");               #=> 133337
say MBE_factor("25246363781991463940137062180162737");              #=> 6156182033
say MBE_factor("133337481996728163387583397826265769");             #=> 401417
say MBE_factor("950928942549203243363840778331691788194718753");    #=> 340282366920938463463374607431768211457
