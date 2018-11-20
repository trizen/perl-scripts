#!/usr/bin/perl

# A simple implementation of a nice algorithm for computing the Mertens function:
#   M(x) = Sum_{k=1..n} moebius(k)

# Algorithm due to Marc Deleglise and Joel Rivat:
#   https://projecteuclid.org/euclid.em/1047565447

# This implementation is not particularly optimized.

# See also:
#   https://oeis.org/A002321
#   https://oeis.org/A084237
#   https://en.wikipedia.org/wiki/Mertens_function
#   https://en.wikipedia.org/wiki/M%C3%B6bius_function

use 5.016;
use ntheory qw(sqrtint moebius);
use experimental qw(signatures);

sub mertens_function ($x) {

    my $u = sqrtint($x);

    my @M  = (0);
    my @mu = moebius(0, $u);        # list of Moebius(k) for k=0..floor(sqrt(n))

    # Partial sums of the Moebius function:
    #   M[n] = Sum_{k=1..n} moebius(k)

    for my $i (1 .. $#mu) {
        $M[$i] += $M[$i - 1] + $mu[$i];
    }

    my $sum = $M[$u];

    foreach my $m (1 .. $u) {

        $mu[$m] || next;

        my $S1_t = 0;
        foreach my $n (int($u / $m) + 1 .. sqrtint(int($x / $m))) {
            $S1_t += $M[int($x / ($m * $n))];
        }

        my $S2_t = 0;
        foreach my $n (sqrtint(int($x / $m)) + 1 .. int($x / $m)) {
            $S2_t += $M[int($x / ($m * $n))];
        }

        $sum -= $mu[$m] * ($S1_t + $S2_t);
    }

    return $sum;
}

foreach my $n (1 .. 6) {
    say "M(10^$n) = ", mertens_function(10**$n);
}

__END__
M(10^1) = -1
M(10^2) = 1
M(10^3) = 2
M(10^4) = -23
M(10^5) = -48
M(10^6) = 212
M(10^7) = 1037
M(10^8) = 1928
M(10^9) = -222
