#!/usr/bin/perl

# Efficient algorithm due to Aleksey Koval for computing the Lucas V sequence (mod m).

# See also:
#   https://en.wikipedia.org/wiki/Lucas_sequence

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::GMPz;

sub lucas_V_mod ($P, $Q, $n, $m) {

    $n = Math::GMPz->new("$n");
    $P = Math::GMPz->new("$P");
    $Q = Math::GMPz->new("$Q");
    $m = Math::GMPz->new("$m");

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $bit (split(//, Math::GMPz::Rmpz_get_str($n, 2))) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
        Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

        if ($bit) {
            Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);
            Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $m);
            Math::GMPz::Rmpz_submul($V1, $P, $Q1);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
            Math::GMPz::Rmpz_mod($V1, $V1, $m);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
            Math::GMPz::Rmpz_submul($V2, $P, $Q1);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
            Math::GMPz::Rmpz_mod($V2, $V2, $m);
        }
    }

    Math::GMPz::Rmpz_mod($V1, $V1, $m);

    return $V1;
}

say lucas_V_mod( 1, -1, 123456, 12345);    #=> 4487
say lucas_V_mod(-3,  4, 987654, 12345);    #=> 3928
say lucas_V_mod(-5, -7, 314159, 12345);    #=> 4565
