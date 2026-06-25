#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 25 June 2026
# https://github.com/trizen

# A sublinear algorithm for computing the partial-sums of `uphi(k)`, for `1 <= k <= n`:
#
#   Sum_{k=1..n} uphi(k)
#
# where uphi(k) is the unitary totient function.

# See also:
#   https://oeis.org/A047994

use 5.036;
use ntheory qw(:all);

sub uphi_powerful($n) {

    my $prod = 1;

    foreach my $pe (factor_exp($n)) {
        my ($p, $e) = @$pe;
        next if ($e < 2);
        $prod *= ($e - 1) * ($p - 1);
    }

    return $prod;
}

sub uphi_sum($n) {

    my $sqrt_n = sqrtint($n);

    my $P = powerful_numbers(1, $n);
    my @F = map { uphi_powerful($_) } @$P;

    my @S = (0);
    for my $i (0 .. $#F) {
        $S[$i + 1] = $S[$i] + $F[$i];
    }

    my $A = 0;
    for my $i (0 .. $#$P) {
        my $k = $P->[$i];
        last if ($k > $sqrt_n);
        $A = addint($A, mulint($F[$i], sumtotient(divint($n, $k))));
    }

    for my $k (1 .. $sqrt_n) {
        $A = addint($A, mulint($S[powerful_count(divint($n, $k))], euler_phi($k)));
    }

    my $B = mulint(sumtotient($sqrt_n), $S[powerful_count($sqrt_n)]);

    return subint($A, $B);
}

foreach my $n (1 .. 10) {
    say "S(10^$n) = ", uphi_sum(powint(10, $n));
}

__END__
S(10^1) = 38
S(10^2) = 3547
S(10^3) = 352798
S(10^4) = 35226152
S(10^5) = 3522256181
S(10^6) = 352221532396
S(10^7) = 35222114211978
S(10^8) = 3522211043323211
S(10^9) = 352221101115270062
S(10^10) = 35222110053700570860
