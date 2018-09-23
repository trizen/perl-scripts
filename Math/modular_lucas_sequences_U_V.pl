#!/usr/bin/perl

# Algorithm due to M. Joye and J.-J. Quisquater for efficiently computing the Lucas U and V sequences (mod m).

# See also:
#   https://en.wikipedia.org/wiki/Lucas_sequence

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::GMPz;

sub lucas_UV_mod ($P, $Q, $n, $m) {

    $n = Math::GMPz->new("$n");
    $P = Math::GMPz->new("$P");
    $Q = Math::GMPz->new("$Q");
    $m = Math::GMPz->new("$m");

    my $U1 = Math::GMPz::Rmpz_init_set_ui(1);

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    my $t = Math::GMPz::Rmpz_init_set_ui(2);
    my $s = Math::GMPz::Rmpz_remove($t, $n, $t);

    foreach my $bit (split(//, substr(Math::GMPz::Rmpz_get_str($t, 2), 0, -1))) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
        Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

        if ($bit) {

            #~ Q2 = (Q1 * Q)%m
            #~ U1 = (U1 * V2)%m
            #~ V1 = (V2*V1 - P*Q1)%m
            #~ V2 = (V2*V2 - 2*Q2)%m

            Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
            Math::GMPz::Rmpz_mul($U1, $U1, $V2);
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);

            Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $m);
            Math::GMPz::Rmpz_submul($V1, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);

            Math::GMPz::Rmpz_mod($V1, $V1, $m);
            Math::GMPz::Rmpz_mod($U1, $U1, $m);
        }
        else {
            #~ Q2 = Q1
            #~ U1 = (U1*V1 - Q1)%m
            #~ V2 = (V2*V1 - P*Q1)%m
            #~ V1 = (V1*V1 - 2*Q2)%m

            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($U1, $U1, $V1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_sub($U1, $U1, $Q1);

            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
            Math::GMPz::Rmpz_submul($V2, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);

            Math::GMPz::Rmpz_mod($V2, $V2, $m);
            Math::GMPz::Rmpz_mod($U1, $U1, $m);
        }
    }

    #~ Q1 = (Q1 * Q2)%m
    #~ Q2 = (Q1 * Q)%m
    #~ U1 = (U1*V1 - Q1)%m
    #~ V1 = (V2*V1 - P*Q1)%m
    #~ Q1 = (Q1 * Q2)%m

    Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
    Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
    Math::GMPz::Rmpz_mul($U1, $U1, $V1);
    Math::GMPz::Rmpz_mul($V1, $V1, $V2);
    Math::GMPz::Rmpz_sub($U1, $U1, $Q1);
    Math::GMPz::Rmpz_submul($V1, $Q1, $P);
    Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);

    for (1 .. $s) {

        #~ U1 = (U1 * V1)%m
        #~ V1 = (V1*V1 - 2*Q1)%m
        #~ Q1 = (Q1 * Q1)%m

        Math::GMPz::Rmpz_mul($U1, $U1, $V1);
        Math::GMPz::Rmpz_mod($U1, $U1, $m);
        Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
        Math::GMPz::Rmpz_submul_ui($V1, $Q1, 2);
        Math::GMPz::Rmpz_powm_ui($Q1, $Q1, 2, $m);
    }

    Math::GMPz::Rmpz_mod($U1, $U1, $m);
    Math::GMPz::Rmpz_mod($V1, $V1, $m);

    return ($U1, $V1);
}

say join(' ', lucas_UV_mod( 1, -1, 123456, 12345));    #=> 1122 4487
say join(' ', lucas_UV_mod(-3,  4, 987654, 12345));    #=> 3855 3928
say join(' ', lucas_UV_mod(-5, -7, 314159, 12345));    #=> 8038 4565
