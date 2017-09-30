#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 21 August 2016
# Edit: 30 September 2017
# https://github.com/trizen

# An efficient algorithm for computing large Fibonacci numbers, modulus some n.

# Algorithm from:
#   http://codeforces.com/blog/entry/14516

use 5.020;
use strict;
use warnings;

use ntheory qw(mulmod addmod);
use experimental qw(signatures);

sub fibmod($n, $mod, $cache={}) {

    $n <= 1 && return $n;

    sub ($n) {

        $n <= 1 && return 1;

        if (exists($cache->{$n})) {
            return $cache->{$n};
        }

        my $k = $n >> 1;

#<<<
        $cache->{$n} = (
            ($n % 2 == 0)
                ? addmod(mulmod(__SUB__->($k), __SUB__->($k    ), $mod), mulmod(__SUB__->($k - 1), __SUB__->($k - 1), $mod), $mod)
                : addmod(mulmod(__SUB__->($k), __SUB__->($k + 1), $mod), mulmod(__SUB__->($k - 1), __SUB__->($k    ), $mod), $mod)
        );
#>>>

    }->($n - 1);
}

say fibmod(329468, 10**10, {});     # 352786941
