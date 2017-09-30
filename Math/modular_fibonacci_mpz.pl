#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 June 2017
# https://github.com/trizen

# An efficient algorithm for computing large Fibonacci numbers, modulo some n.

# Algorithm from:
#   http://codeforces.com/blog/entry/14516

use 5.020;
use strict;
use warnings;

use Math::GMPz qw();
use experimental qw(signatures);

sub fibmod($n, $mod, $cache={}) {

    $n <= 1 && return $n;

    sub ($n) {

        $n <= 1 && return do {
            state $one = Math::GMPz::Rmpz_init_set_ui(1)
        };

        if (exists($cache->{$n})) {
            return $cache->{$n};
        }

        my $k = $n >> 1;

        $cache->{$n} = (
                        $n % 2 == 0
                        ? (__SUB__->($k) * __SUB__->($k)     + __SUB__->($k - 1) * __SUB__->($k - 1)) % $mod
                        : (__SUB__->($k) * __SUB__->($k + 1) + __SUB__->($k - 1) * __SUB__->($k)    ) % $mod
                       );
    }->($n - 1);
}

say fibmod(329468, 10**10, {});     # 352786941
