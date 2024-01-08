#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 January 2019
# https://github.com/trizen

# A recursive formula for computing the Fubini numbers.

# See also:
#   https://oeis.org/A000670

use 5.010;
use strict;
use warnings;

use Memoize qw(memoize);
use Math::AnyNum qw(:overload binomial sum);

memoize('nth_fubini_number');

sub nth_fubini_number {
    my ($n) = @_;
    return 1 if ($n == 0);
    sum(map { nth_fubini_number($_) * binomial($n, $_) } 0 .. $n-1);
}

foreach my $i (0 .. 20) {
    say "F($i) = ", nth_fubini_number($i);
}

__END__
F(0) = 1
F(1) = 1
F(2) = 3
F(3) = 13
F(4) = 75
F(5) = 541
F(6) = 4683
F(7) = 47293
F(8) = 545835
F(9) = 7087261
F(10) = 102247563
F(11) = 1622632573
F(12) = 28091567595
F(13) = 526858348381
F(14) = 10641342970443
F(15) = 230283190977853
F(16) = 5315654681981355
F(17) = 130370767029135901
F(18) = 3385534663256845323
F(19) = 92801587319328411133
F(20) = 2677687796244384203115
