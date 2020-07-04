#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 July 2017
# https://github.com/trizen

# Harmonic sum of prime powers <= n, defined as:
#
#    Sum_{p <= n} (Sum_{1 <= k <= floor(log(n)/log(p))} 1/p^k)
#
# where p runs over the prime number <= n.

# This is equivalent with:
#   Sum_{p <= n} (p^(floor(log(n)/log(p))) - 1) / (p^(floor(log(n)/log(p))) * (p-1))

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes);
use Math::AnyNum qw(:overload ilog);

sub harmonic_prime_powers {
    my ($n) = @_;

    my $sum = 0;

    forprimes {
        my $p = $_;
        my $k = $p**ilog($n, $p);
        $sum += ($k - 1) / ($k * ($p - 1));
    } $n;

    return $sum;
}

foreach my $n (1 .. 30) {
    say harmonic_prime_powers($n);
}

__END__
0
1/2
5/6
13/12
77/60
77/60
599/420
1303/840
4189/2520
4189/2520
48599/27720
48599/27720
659507/360360
659507/360360
659507/360360
1364059/720720
23909723/12252240
23909723/12252240
466536977/232792560
466536977/232792560
466536977/232792560
466536977/232792560
10963143031/5354228880
10963143031/5354228880
55886560931/26771144400
55886560931/26771144400
170634254393/80313433200
170634254393/80313433200
5028706810597/2329089562800
5028706810597/2329089562800
