#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 July 2016
# Website: https://github.com/trizen

# Compute the inverse of n-factorial.
# The function is defined only for factorial numbers.
# It may return non-sense for non-factorials.

use 5.010;
use strict;
use warnings;

use ntheory qw(primes);
use List::Util qw(all);
use Math::AnyNum qw(:overload);

sub power {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    $s;
}

sub inverse_of_factorial {
    my ($f) = @_;

    return 1 if ($f == 1);
    return 2 if ($f == 2);
    return 3 if ($f == 6);
    return 4 if ($f == 24);
    return 5 if ($f == 120);

    my $bin = $f->as_bin;
    my $t = length($bin) - rindex($bin, '1') - 1;

    my $c = $t->ilog2;
    my $p = 1 << $c;
    my $d = int($t * ($p / ($p - 1)));

    $d->is_real || return;

    for my $x (reverse(0 .. $c)) {
        if (power($d + $x, 2) == $t) {

            my $n = $d + $x;
            my $primes = primes(3, $n);

            my $bool = all {
                $f->is_div($_**power($n, $_));
            }
            @{$primes};

            return ($bool ? $n : $n - 1);
        }
    }

    return;
}

my @factorials = (

    # 7!
    5040,

    # 11!
    39916800,

    # 22!
    1124000727777607680000,

    # 31!
    8222838654177922817725562880000000,

    # 33!
    8683317618811886495518194401280000000,

    # 82!
    475364333701284174842138206989404946643813294067993328617160934076743994734899148613007131808479167119360000000000000000000,

    # 90!
    1485715964481761497309522733620825737885569961284688766942216863704985393094065876545992131370884059645617234469978112000000000000000000000,
);

foreach my $f (@factorials) {
    say inverse_of_factorial($f);
}
