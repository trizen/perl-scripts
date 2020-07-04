#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 11 January 2019
# https://github.com/trizen

# Fast program for computing the numbers `n` such that the denominator of Bernoulli(n) is a record.

# OEIS sequences:
#   https://oeis.org/A100195
#   https://oeis.org/A100194

# See also:
#   https://en.wikipedia.org/wiki/Bernoulli_number
#   https://mathworld.wolfram.com/BernoulliNumber.html
#   https://en.wikipedia.org/wiki/Von_Staudt%E2%80%93Clausen_theorem

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(divisors is_prime vecprod);

sub bernoulli_denominator ($n) {    # denominator of the n-th Bernoulli number

    return 1 if ($n <= 0);
    return 1 if ($n > 1 and $n % 2);

    vecprod(map { $_ + 1 } grep { is_prime($_ + 1) } divisors($n));
}

sub records_upto ($n, $callback) {

    for (my ($k, $m) = (0, -1) ; $k <= $n ; $k += 2) {

        my $sum = 0;
        foreach my $d (divisors($k)) {
            if (is_prime($d + 1)) {
                $sum += log($d + 1);
            }
        }

        if ($sum > $m) {
            $m = $sum;
            $callback->($k);
        }
    }
}

records_upto(1e4, sub ($k) { say "B($k) = ", bernoulli_denominator($k) });

__END__
B(0) = 2
B(2) = 6
B(4) = 30
B(6) = 42
B(10) = 66
B(12) = 2730
B(30) = 14322
B(36) = 1919190
B(60) = 56786730
B(72) = 140100870
B(108) = 209191710
B(120) = 2328255930
B(144) = 2381714790
B(180) = 7225713885390
B(240) = 9538864545210
B(360) = 21626561658972270
B(420) = 446617991732222310
B(540) = 115471236091149548610
B(840) = 5145485882746933233510
B(1008) = 14493038256293268734790
B(1080) = 345605409620810598989730
B(1200) = 42107247672297314156359710
B(1260) = 4554106624556364764691012210
B(1620) = 24743736851520275624910204330
B(1680) = 802787680649929796414310788070
B(2016) = 1908324101335116127448341021830
B(2160) = 1324918483651364394207119201026530
B(2520) = 9655818125018463593525930077544596530
B(3360) = 176139196253087613320507734410708168870
B(3780) = 20880040554948303778681975110988542692370
B(5040) = 1520038371910163024272084596792024938493098335890
B(6480) = 2386506545702609292996755910476726098859145077130
B(7560) = 334731403390662540713247087231623394273840419057927010
B(8400) = 30721852291400450355987797336504062619723310330260297070
