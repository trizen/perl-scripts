#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 December 2017
# https://github.com/trizen

# A new algorithm for computing the Fubini numbers.

# See also:
#   http://oeis.org/A000670

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload factorial);

sub fubini_numbers {
    my ($n) = @_;

    my @F = (1);

    foreach my $i (1 .. $n) {
        foreach my $k (0 .. $i - 1) {
            $F[$i] += $F[$k] / factorial($i - $k);
        }
    }

    map { $F[$_] * factorial($_) } 0 .. $#F;
}

my @F = fubini_numbers(20);

foreach my $i (0 .. $#F) {
    say "F($i) = $F[$i]";
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
