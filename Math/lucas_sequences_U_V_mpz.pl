#!/usr/bin/perl

# Algorithm due to Aleksey Koval for computing the Lucas U and V sequences.

# See also:
#   https://en.wikipedia.org/wiki/Lucas_sequence

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::GMPz;

sub lucasUV ($n, $P, $Q) {

    $n = Math::GMPz->new("$n");
    $P = Math::GMPz->new("$P");
    $Q = Math::GMPz->new("$Q");

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    my $t = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    foreach my $bit (split(//, Math::GMPz::Rmpz_get_str($n, 2))) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);

        if ($bit) {
            Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);
            Math::GMPz::Rmpz_mul($t,  $P,  $Q1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V2);
            Math::GMPz::Rmpz_sub($V1, $V1, $t);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_mul($t,  $P,  $Q1);
            Math::GMPz::Rmpz_mul($V1, $V1, $V1);
            Math::GMPz::Rmpz_sub($V2, $V2, $t);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
        }
    }

    Math::GMPz::Rmpz_mul_2exp($t, $V2, 1);
    Math::GMPz::Rmpz_submul($t, $P, $V1);
    Math::GMPz::Rmpz_mul($v, $P, $P);
    Math::GMPz::Rmpz_submul_ui($v, $Q, 4);
    Math::GMPz::Rmpz_divexact($t, $t, $v);

    return ($t, $V1);
}

foreach my $n (1 .. 20) {
    say "[", join(', ', lucasUV($n, 1, -1)), "]";
}

__END__
[1, 1]
[1, 3]
[2, 4]
[3, 7]
[5, 11]
[8, 18]
[13, 29]
[21, 47]
[34, 76]
[55, 123]
[89, 199]
[144, 322]
[233, 521]
[377, 843]
[610, 1364]
[987, 2207]
[1597, 3571]
[2584, 5778]
[4181, 9349]
[6765, 15127]
