#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 March 2023
# https://github.com/trizen

# Generate Lucas-Carmichael numbers from a given multiple.

# See also:
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub lucas_carmichael_from_multiple ($m, $callback) {

    my $t = Math::GMPz::Rmpz_init();
    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    my $L = lcm(map { addint($_, 1) } factor($m));

    $m = Math::GMPz->new("$m");
    $L = Math::GMPz->new("$L");

    Math::GMPz::Rmpz_invert($v, $m, $L) || return;
    Math::GMPz::Rmpz_sub($v, $L, $v);

    for (my $p = Math::GMPz::Rmpz_init_set($v) ; ; Math::GMPz::Rmpz_add($p, $p, $L)) {

        Math::GMPz::Rmpz_gcd($t, $m, $p);
        Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 or next;

        my @factors = factor_exp($p);
        (vecall { $_->[1] == 1 } @factors) || next;

        Math::GMPz::Rmpz_mul($v, $m, $p);
        Math::GMPz::Rmpz_add_ui($u, $v, 1);

        Math::GMPz::Rmpz_set_str($t, lcm(map { addint($_->[0], 1) } @factors), 10);

        if (Math::GMPz::Rmpz_divisible_p($u, $t)) {
            $callback->(Math::GMPz::Rmpz_init_set($v));
        }
    }
}

lucas_carmichael_from_multiple(11 * 17, sub ($n) { say $n });
