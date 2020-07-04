#!/usr/bin/perl

# The DSC-Factorial algorithm (divide, swing and conquer), by Peter Luschny.

# See also:
#   https://oeis.org/A000142/a000142.pdf

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(forprimes);
use experimental qw(signatures);

sub Product ($s, $n, $m) {
    $n >  $m and return 1;
    $n == $m and return $s->[$n];
    my $k = ($n + $m) >> 1;
    Product($s, $n, $k) * Product($s, $k + 1, $m);
}

sub PrimeSwing($n) {
    my @factors;

    forprimes {
        my $prime = $_;
        my ($q, $p) = ($n, 1);

        while ($q > 0) {
            $q = int($q / $prime);
            $p *= $prime if ($q & 1);
        }

        push(@factors, Math::GMPz::Rmpz_init_set_ui($p)) if ($p > 1);
    } $n;

    Product(\@factors, 0, $#factors);
}

sub Factorial($n) {
    return 1 if ($n < 2);
    Factorial($n >> 1)**2 * PrimeSwing($n);
}

foreach my $n (0 .. 30) {
    say "$n! = ", Factorial($n);
}
