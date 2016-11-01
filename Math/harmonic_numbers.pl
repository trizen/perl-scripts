#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 01 November 2016
# https://github.com/trizen

# Computing the nth-harmonic number as an exact fraction.

# See also:
#   https://en.wikipedia.org/wiki/Harmonic_series_(mathematics)

use 5.016;
use warnings;
use Math::BigNum;

# Inspired by Dana Jacobsen's code from Math::Prime::Util::PP.
# https://metacpan.org/pod/Math::Prime::Util::PP
my $harmonic_split = sub {
    my ($num, $den) = @_;

    my $diff = $den - $num;

    if ($diff == 1) {
        ($diff, $num);
    }
    elsif ($diff == 2) {
        (($num << 1) + 1, $num * $num + $num);
    }
    else {
        my $m = Math::GMPz::Rmpz_init_set($num);
        Math::GMPz::Rmpz_add($m, $m, $den);
        Math::GMPz::Rmpz_div_2exp($m, $m, 1);

        my ($p, $q) = __SUB__->($num, $m);
        my ($r, $s) = __SUB__->($m,   $den);

        Math::GMPz::Rmpz_mul($p, $p, $s);
        Math::GMPz::Rmpz_mul($r, $r, $q);
        Math::GMPz::Rmpz_add($p, $p, $r);
        Math::GMPz::Rmpz_mul($q, $q, $s);

        ($p, $q);
    }
};

sub harmfrac {
    my ($ui) = @_;

    $ui = int($ui);
    $ui || return Math::BigNum->zero;
    $ui < 0 and return Math::BigNum->nan;

    # Use binary splitting for large values of n. (by Fredrik Johansson)
    # http://fredrik-j.blogspot.ro/2009/02/how-not-to-compute-harmonic-numbers.html
    if ($ui > 15000) {
        my $num = Math::GMPz::Rmpz_init_set_ui(1);
        my $den = Math::GMPz::Rmpz_init_set_ui($ui + 1);

        ($num, $den) = $harmonic_split->($num, $den);

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_num($q, $num);
        Math::GMPq::Rmpq_set_den($q, $den);
        Math::GMPq::Rmpq_canonicalize($q);

        return Math::BigNum->new($q);
    }

    my $num = Math::GMPz::Rmpz_init_set_ui(1);
    my $den = Math::GMPz::Rmpz_init_set_ui(1);

    for (my $k = 2 ; $k <= $ui ; ++$k) {
        Math::GMPz::Rmpz_mul_ui($num, $num, $k);    # num = num * k
        Math::GMPz::Rmpz_add($num, $num, $den);     # num = num + den
        Math::GMPz::Rmpz_mul_ui($den, $den, $k);    # den = den * k
    }

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_num($r, $num);
    Math::GMPq::Rmpq_set_den($r, $den);
    Math::GMPq::Rmpq_canonicalize($r);

    Math::BigNum->new($r);
}

foreach my $i (0 .. 30) {
    printf "%20s / %-20s\n", split('/', harmfrac($i)->as_frac);
}
