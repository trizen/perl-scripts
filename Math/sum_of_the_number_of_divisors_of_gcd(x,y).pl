#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 January 2019
# https://github.com/trizen

# Fast formula for computing:
#   a(n) = sum of the number of divisors of gcd(x,y) with x*y <= n.

# See also:
#   https://oeis.org/A268732    -- Sum of the numbers of divisors of gcd(x,y) with x*y <= n.
#   https://oeis.org/A034444    -- Partial sums of A034444: sum of number of unitary divisors from 1 to n.
#   https://oeis.org/A180361    -- Sum of number of unitary divisors (A034444) from 1 to 10^n

# Adrian Dudek, on the Success of Mishandling Euclid's Lemma:
#   https://arxiv.org/abs/1602.03555

# Asymptotic formula:
#   a(n) ~ 1/6 * π^2 * n * (2 * (-12 * log(A) + γ + log(2) + log(π)) + log(n) + 2*γ - 1) + O(sqrt(n)*log(n))
#
# where γ is the Euler-Mascheroni constant and "A" is the Glaisher-Kinkelin constant.

# Alternative asymptotic formula:
#   a(n) ~ (n * zeta(2) * (log(n) + 2*γ - 1 + c)) + O(sqrt(n)*log(n))
#
#  where γ is the Euler-Mascheroni and c = 2*Zeta'(2)/Zeta(2) = -1.1399219861890656127997287200...

use 5.020;
use strict;
use warnings;

use ntheory qw(moebius);
use experimental qw(signatures);
use Math::AnyNum qw(:overload pi EulerGamma isqrt zeta round);

sub asymptotic_formula($n) {

    # c = 2*Zeta'(2)/Zeta(2) = (12 * Zeta'(2))/π^2 = 2*(-12*log(A) + γ + log(2) + log(π))
    my $c = -1.13992198618906561279972872003946000480696456161386195911639472087583455473348121357;

    # Asymptotic formula based on Merten's theorem (1874) (see: https://oeis.org/A064608)
    ($n * zeta(2) * (log($n) + 2 * EulerGamma + $c - 1));
}

sub asymptotic_formula2($n) {

    # The Glaisher-Kinkelin constant
    my $A = 1.28242712910062263687534256886979172776768892732500119206374002174040630885882646112973649195820237439420646120399;

    # Asymptotic formula in terms of the Glaisher-Kinkelin constant
    zeta(2) * $n * (2 * (-12 * log($A) + EulerGamma + log(2*pi)) + log($n) + 2*EulerGamma - 1);
}

sub sum_of_number_of_divisors_of_gcd ($n) {    # based on formula by Jerome Raulin (https://oeis.org/A064608)

    my $total = 0;

    foreach my $k (1 .. isqrt($n)) {
        my $t = 0;
        foreach my $j (1 .. isqrt($n / ($k * $k))) {
            $t += int($n / ($j * $k * $k));
        }

        my $r = isqrt($n / ($k * $k));
        $total += (2 * $t - $r * $r);
    }

    return $total;
}

say join(', ', map { sum_of_number_of_divisors_of_gcd($_) } 1 .. 20);

foreach my $k (1 .. 8) {

    my $n = 10**$k;
    my $t = sum_of_number_of_divisors_of_gcd($n);
    my $u = asymptotic_formula($n);

    printf("a(10^%s) = %10s ~ %-15s -> %s\n", $k, $t, round($u, -2), $t / $u);
}

__END__
[0, 1, 3, 5, 9, 11, 15, 17, 23, 27, 31, 33, 41, 43, 47, 51, 60, 62, 70, 72, 80]

a(10^1)  =                31 ~ 21.66                -> 1.43085716814724731567697388362262512087796085132
a(10^2)  =               629 ~ 595.41               -> 1.05640884486870073219427770179934635115325018838
a(10^3)  =              9823 ~ 9741.73              -> 1.00834196073027036381381492602216565392721426965
a(10^4)  =            135568 ~ 135293.35            -> 1.00202999682691312076763529313619057317755443274
a(10^5)  =           1732437 ~ 1731693.62           -> 1.00042928187585922855456102384841804396816671626
a(10^6)  =          21107131 ~ 21104536.81          -> 1.00012292075282086768302929969619689628662614091
a(10^7)  =         248928748 ~ 248921374.75         -> 1.00002962076965424120327637576433900637540389794
a(10^8)  =        2867996696 ~ 2867973813.70        -> 1.00000797855916535575678041071686222727851109258
a(10^9)  =       32467409097 ~ 32467338798.29       -> 1.00000216521302261846703873643427029189711363986
a(10^10) =      362549612240 ~ 362549394595.78      -> 1.00000060031604804834071744691960444929352043683
a(10^11) =     4004254692640 ~ 4004254012086.08     -> 1.00000016995772897612356184672572401706556174343
a(10^12) =    43830142939380 ~ 43830140782143.61    -> 1.00000004921810301432497497420018745129768545890
a(10^13) =   476177421208658 ~ 476177414434264.13   -> 1.00000001422661735697513455710167585383336332082
a(10^14) =  5140534231877816 ~ 5140534210470921.03  -> 1.00000000416433275074901946766616776434113033877
a(10^15) = 55192942833495679 ~ 55192942765992007.53 -> 1.00000000122304896383936291361582837193299642341
