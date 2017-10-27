#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 13 October 2017
# https://github.com/trizen

# Find the greatest divisor (mod m) of `n` that does not exceed the square root of `n`.

# See also:
#   https://projecteuler.net/problem=266

use 5.020;
use warnings;

use ntheory qw(factor mulmod);
use experimental qw(signatures);

sub pseudo_square_root_mod ($n, $mod) {

    my $sqrt_log = log($n) / 2;
    my @factors  = factor($n);
    my $end      = $#factors;

    my $maximum_log = 0;
    my $maximum_num = 0;

    sub ($i, $log, $prod) {

        if ($log > $maximum_log) {
            $maximum_log = $log;
            $maximum_num = $prod;
        }

        if ($i > $end) {
            return;
        }

        if ($log + log($factors[$i]) <= $sqrt_log) {
            __SUB__->($i + 1, $log, $prod) if ($i < $end);
            __SUB__->($i + 1, $log + log($factors[$i]), mulmod($prod, $factors[$i], $mod));
        }

    }->(0, 0, 1);

    return $maximum_num;
}

say pseudo_square_root_mod(479001600,   10**16);    #=> 21600
say pseudo_square_root_mod(6469693230,  10**16);    #=> 79534
say pseudo_square_root_mod(12398712476, 10**16);    #=> 68

say pseudo_square_root_mod('614889782588491410',              10**8);     #=> 83152070
say pseudo_square_root_mod('3217644767340672907899084554130', 10**16);    #=> 1793779293633437
