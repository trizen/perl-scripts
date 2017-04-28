#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 06 September 2015
# Website: https://github.com/trizen

# Generate closed-form formulas for zeta(2n).
# See also: https://en.wikipedia.org/wiki/Riemann_zeta_function

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload factorial);

sub bernoulli_number {
    my ($n) = @_;

    return 0 if $n > 1 && $n % 2;    # Bn = 0 for all odd n > 1

    my @A;
    for my $m (0 .. $n) {
        $A[$m] = 1 / ($m + 1);

        for (my $j = $m ; $j > 0 ; $j--) {
            $A[$j - 1] = $j * ($A[$j - 1] - $A[$j]);
        }
    }

    return $A[0];                    # which is Bn
}

sub zeta_2n {
    my ($n2) = 2 * $_[0];
    join('', (bernoulli_number($n2) * (-1)**($_[0] + 1) * 2**($n2 - 1) / factorial($n2)), " * pi^$n2");
}

for my $i (1 .. 10) {
    say "zeta(", 2 * $i, ") = ", zeta_2n($i);
}

__END__
zeta(2) = 1/6 * pi^2
zeta(4) = 1/90 * pi^4
zeta(6) = 1/945 * pi^6
zeta(8) = 1/9450 * pi^8
zeta(10) = 1/93555 * pi^10
zeta(12) = 691/638512875 * pi^12
zeta(14) = 2/18243225 * pi^14
zeta(16) = 3617/325641566250 * pi^16
zeta(18) = 43867/38979295480125 * pi^18
zeta(20) = 174611/1531329465290625 * pi^20
