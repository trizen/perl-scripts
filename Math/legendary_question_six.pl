#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 June 2019
# https://github.com/trizen

# The problem:
#   Let "a" and "b" be positive integers such that a*b + 1 divides a^2 + b^2.
#   Show that (a^2 + b^2) / (a*b + 1) is the square of an integer.

# This program presents an efficient method for computing non-trivial solutions to the legendary question six.

# The Legend of Question Six - Numberphile
# https://www.youtube.com/watch?v=Y30VF3cSIYQ

# The Return of the Legend of Question Six - Numberphile
# https://www.youtube.com/watch?v=L0Vj_7Y2-xY

# Solutions for (a^2 + b^2) / (1 + ab) = 4, are given by consecutive values of A052530 = { 2, 8, 30, 112, 418, 1560, 5822, ... }.

# Example:
#   (  2^2 +   8^2) / (    2*8 + 1) = 4
#   (  8^2 +  30^2) / (   8*30 + 1) = 4
#   ( 30^2 + 112^2) / ( 30*112 + 1) = 4
#   (112^2 + 418^2) / (112*418 + 1) = 4

# Similar sequences provide solutions for other values:

# For 3^2: A065100 = { 3, 27, 240, 2133, 18957, 168480, ... }
# For 4^2: A154021 = { 4, 64, 1020, 16256, 259076, 4128960, ... }
# For 5^2: A154022 = { 5, 125, 3120, 77875, 1943755, 48516000, ... }
# For 6^2: A154023 = { 6, 216, 7770, 279504, 10054374, 361677960, ... }

# More generally, let U(n,x) be the Chebyshev polynomials of the second kind, then (a^2 + b^2) / (1 + ab) = m^2, has solutions of the form:
#
#   a = m * U(n, m^2 / 2)
#   b = m * U(n+1, m^2 / 2)
#
# for any given positive integer m.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use Math::AnyNum qw(:overload chebyshevU);

sub lq6_solutions ($m, $how_many = 5) {
    map {
        [$m * chebyshevU($_, $m*$m / 2), $m * chebyshevU($_ + 1, $m*$m / 2)]
    } 0 .. $how_many-1;
}

foreach my $k (2 .. 10) {
    my @S = lq6_solutions($k);
    say "(a^2 + b^2) / (1 + ab) = $k^2 has solutions: ", join(', ', map { "[@$_]" } @S);
}

__END__
(a^2 + b^2) / (1 + ab) = 2^2 has solutions: [2 8], [8 30], [30 112], [112 418], [418 1560]
(a^2 + b^2) / (1 + ab) = 3^2 has solutions: [3 27], [27 240], [240 2133], [2133 18957], [18957 168480]
(a^2 + b^2) / (1 + ab) = 4^2 has solutions: [4 64], [64 1020], [1020 16256], [16256 259076], [259076 4128960]
(a^2 + b^2) / (1 + ab) = 5^2 has solutions: [5 125], [125 3120], [3120 77875], [77875 1943755], [1943755 48516000]
(a^2 + b^2) / (1 + ab) = 6^2 has solutions: [6 216], [216 7770], [7770 279504], [279504 10054374], [10054374 361677960]
(a^2 + b^2) / (1 + ab) = 7^2 has solutions: [7 343], [343 16800], [16800 822857], [822857 40303193], [40303193 1974033600]
(a^2 + b^2) / (1 + ab) = 8^2 has solutions: [8 512], [512 32760], [32760 2096128], [2096128 134119432], [134119432 8581547520]
(a^2 + b^2) / (1 + ab) = 9^2 has solutions: [9 729], [729 59040], [59040 4781511], [4781511 387243351], [387243351 31361929920]
(a^2 + b^2) / (1 + ab) = 10^2 has solutions: [10 1000], [1000 99990], [99990 9998000], [9998000 999700010], [999700010 99960003000]
