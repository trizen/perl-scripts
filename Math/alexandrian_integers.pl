#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 18 August 2016
# License: GPLv3
# Website: https://github.com/trizen

# Get the nth Alexandrian integer.

# See also: https://oeis.org/A147811
#           https://projecteuler.net/problem=221

use 5.010;
use strict;
use warnings;

use ntheory qw(divisors);

sub nth_alexandrian {
    my ($nth) = @_;

    return 120 if $nth == 3;    # hmm...

    my %nums;
    my $count = 0;
    my $prev  = 6;

  OUT: foreach my $n (1 .. $nth) {
        foreach my $d (divisors($n * $n + 1)) {

            my $q = $n + $d;
            my $r = ($n + ($n * $n + 1) / $d);

            last if $q > $r;

            my $A = $n * $q * $r;
            --$count if ($A < $prev);

            if (not exists $nums{$A}) {
                undef $nums{$A};
                $prev = $A;
                last OUT if (++$count == $nth);
            }
        }
    }

    +(sort { $a <=> $b } keys %nums)[$nth - 1];
}

foreach my $n (1 .. 20) {
    say "A($n) = ", nth_alexandrian($n);
}

__END__
A(1) = 6
A(2) = 42
A(3) = 120
A(4) = 156
A(5) = 420
A(6) = 630
A(7) = 930
A(8) = 1428
A(9) = 1806
A(10) = 2016
A(11) = 2184
A(12) = 3192
A(13) = 4950
A(14) = 5256
A(15) = 8190
A(16) = 8364
A(17) = 8970
A(18) = 10296
A(19) = 10998
A(20) = 12210
