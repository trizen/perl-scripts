#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 March 2023
# https://github.com/trizen

# Generate Fermat pseudoprimes from a given multiple, to a given base.

# See also:
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.036;
use Math::GMPz;
use ntheory qw(:all);

sub fermat_pseudoprimes_from_multiple ($base, $m, $callback) {

    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();
    my $w = Math::GMPz::Rmpz_init_set_ui($base);

    my $L = znorder($base, $m);

    $m = Math::GMPz->new("$m");
    $L = Math::GMPz->new("$L");

    Math::GMPz::Rmpz_invert($v, $m, $L) || return;

    for (my $p = Math::GMPz::Rmpz_init_set($v) ; ; Math::GMPz::Rmpz_add($p, $p, $L)) {

        Math::GMPz::Rmpz_mul($v, $m, $p);
        Math::GMPz::Rmpz_sub_ui($u, $v, 1);
        Math::GMPz::Rmpz_powm($u, $w, $u, $v);

        if (Math::GMPz::Rmpz_cmp_ui($u, 1) == 0) {
            $callback->(Math::GMPz::Rmpz_init_set($v));
        }
    }
}

fermat_pseudoprimes_from_multiple(2, 341, sub ($n) { say $n });
