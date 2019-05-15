#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 May 2019
# https://github.com/trizen

# Generate the smallest extended Chernick-Carmichael number with k prime factors.

# OEIS sequence:
#   https://oeis.org/A318646 -- The least Chernick's "universal form" Carmichael number with n prime factors.

# See also:
#   https://oeis.org/wiki/Carmichael_numbers
#   http://www.ams.org/journals/bull/1939-45-04/S0002-9904-1939-06953-X/home.html

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

# Generate the factors of a Chernick number, given n
# and k, where k is the number of distinct prime factors.
sub chernick_carmichael_factors ($n, $k) {
    (6 * $n + 1, 12 * $n + 1, (map { (1 << $_) * 9 * $n + 1 } 1 .. $k - 2));
}

# Find the smallest Chernick-Carmichael number with k prime factors.
sub extended_chernick_carmichael_number ($k, $callback) {

    my $multiplier = 1;

    if ($k > 4) {
        $multiplier = 1 << ($k - 4);
    }

    for (my $n = 1 ; ; ++$n) {
        my @f = chernick_carmichael_factors($n * $multiplier, $k);
        next if not vecall { is_prime($_) } @f;
        $callback->(vecprod(@f), @f);
        last;
    }
}

foreach my $k (3 .. 9) {
    extended_chernick_carmichael_number(
        $k,
        sub ($n, @f) {
            say "a($k) = $n";
        }
    );
}

__END__
a(3) = 1729
a(4) = 63973
a(5) = 26641259752490421121
a(6) = 1457836374916028334162241
a(7) = 24541683183872873851606952966798288052977151461406721
a(8) = 53487697914261966820654105730041031613370337776541835775672321
a(9) = 58571442634534443082821160508299574798027946748324125518533225605795841
