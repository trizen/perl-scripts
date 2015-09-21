#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 21 September 2015
# Website: https://github.com/trizen

# Recursive computation of Bernoulli numbers.

# See: https://en.wikipedia.org/wiki/Bernoulli_number#Recursive_definition
#      https://en.wikipedia.org/wiki/Binomial_coefficient#Recursive_formula

use 5.010;
use strict;
use warnings;

use bigrat (try => 'GMP');
use Memoize qw( memoize );

no warnings qw(recursion);

memoize('binomial');
memoize('bern_helper');
memoize('bernoulli_number');

sub binomial {
    my ($n, $k) = @_;
    $k == 0 || $n == $k ? 1.0 : binomial($n - 1, $k - 1) + binomial($n - 1, $k);
}

sub bern_helper {
    my ($n, $k) = @_;
    binomial($n, $k) * (bernoulli_number($k) / ($n - $k + 1));
}

sub bern_diff {
    my ($n, $k, $d) = @_;
    $n < $k ? $d : bern_diff($n, $k + 1, $d - bern_helper($n + 1, $k));
}

sub bernoulli_number {
    my ($n) = @_;

    return 1 / 2 if $n == 1;
    return 0 / 1 if $n % 2;

    $n > 0 ? bern_diff($n - 1, 0, 1.0) : 1.0;
}

for my $i (0 .. 50) {
    printf "B%-2d = %s\n", $i, bernoulli_number($i + 0);
}

__END__
B0  = 1
B1  = 1/2
B2  = 1/6
B3  = 0
B4  = -1/30
B5  = 0
B6  = 1/42
B7  = 0
B8  = -1/30
B9  = 0
B10 = 5/66
B11 = 0
B12 = -691/2730
B13 = 0
B14 = 7/6
B15 = 0
B16 = -3617/510
B17 = 0
B18 = 43867/798
B19 = 0
B20 = -174611/330
B21 = 0
B22 = 854513/138
B23 = 0
B24 = -236364091/2730
B25 = 0
B26 = 8553103/6
B27 = 0
B28 = -23749461029/870
B29 = 0
B30 = 8615841276005/14322
B31 = 0
B32 = -7709321041217/510
B33 = 0
B34 = 2577687858367/6
B35 = 0
B36 = -26315271553053477373/1919190
B37 = 0
B38 = 2929993913841559/6
B39 = 0
B40 = -261082718496449122051/13530
B41 = 0
B42 = 1520097643918070802691/1806
B43 = 0
B44 = -27833269579301024235023/690
B45 = 0
B46 = 596451111593912163277961/282
B47 = 0
B48 = -5609403368997817686249127547/46410
B49 = 0
B50 = 495057205241079648212477525/66
