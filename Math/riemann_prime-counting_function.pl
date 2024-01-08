#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 27 February 2019
# https://github.com/trizen

# Compute the Riemann prime-power counting function for 10^n.

# OEIS sequences:
#   https://oeis.org/A322713 -- numerator of the Riemann prime counting function for 10^n.
#   https://oeis.org/A322714 -- denominator of the Riemann prime counting function for 10^n.

# See also:
#   https://mathworld.wolfram.com/RiemannPrimeCountingFunction.html
#   https://en.wikipedia.org/wiki/Arithmetic_function#%CF%80(x),_%CE%A0(x),_%CE%B8(x),_%CF%88(x)_%E2%80%93_prime_count_functions

# PARI program:
#   a(n) = sum(k=1, logint(n, 2), primepi(sqrtnint(n, k))/k);

use 5.020;
use strict;
use warnings;

use ntheory qw(prime_count);
use experimental qw(signatures);
use Math::AnyNum qw(:overload iroot ipow10 ilog2);

my %primepi_lookup = (    # https://oeis.org/A006880
                       ipow10(0)  => 0,
                       ipow10(1)  => 4,
                       ipow10(2)  => 25,
                       ipow10(3)  => 168,
                       ipow10(4)  => 1229,
                       ipow10(5)  => 9592,
                       ipow10(6)  => 78498,
                       ipow10(7)  => 664579,
                       ipow10(8)  => 5761455,
                       ipow10(9)  => 50847534,
                       ipow10(10) => 455052511,
                       ipow10(11) => 4118054813,
                       ipow10(12) => 37607912018,
                       ipow10(13) => 346065536839,
                       ipow10(14) => 3204941750802,
                       ipow10(15) => 29844570422669,
                       ipow10(16) => 279238341033925,
                       ipow10(17) => 2623557157654233,
                       ipow10(18) => 24739954287740860,
                       ipow10(19) => 234057667276344607,
                       ipow10(20) => 2220819602560918840,
                       ipow10(21) => 21127269486018731928,
                       ipow10(22) => 201467286689315906290,
                       ipow10(23) => 1925320391606803968923,
                       ipow10(24) => 18435599767349200867866,
                       ipow10(25) => 176846309399143769411680,
                       ipow10(26) => 1699246750872437141327603,
                       ipow10(27) => 16352460426841680446427399,
                     );

sub primepi ($n) {
    $primepi_lookup{$n} //= Math::AnyNum->new(prime_count($n));
}

sub riemann_prime_power_count ($n) {

    my $sum = Math::AnyNum->new(0);

    foreach my $k (1 .. ilog2($n)) {
        $sum += primepi(iroot($n, $k)) / $k;
    }

    return $sum;
}

foreach my $k (0 .. 27) {
    my $riemann_pi = riemann_prime_power_count(ipow10($k));
    printf("RiemannPI(10^%s) = %s / %s\n", $k, $riemann_pi->nude);
}

__END__
RiemannPI(10^0) = 0 / 1
RiemannPI(10^1) = 16 / 3
RiemannPI(10^2) = 428 / 15
RiemannPI(10^3) = 445273 / 2520
RiemannPI(10^4) = 56175529 / 45045
RiemannPI(10^5) = 991892879 / 102960
RiemannPI(10^6) = 18296822833013 / 232792560
RiemannPI(10^7) = 3559637526370229 / 5354228880
RiemannPI(10^8) = 6427431691337929 / 1115464350
RiemannPI(10^9) = 14804074778750628149 / 291136195350
RiemannPI(10^10) = 9387415960571046321167 / 20629078984800
RiemannPI(10^11) = 594663752918349842404169 / 144403552893600
RiemannPI(10^12) = 200936708396848319452718531 / 5342931457063200
RiemannPI(10^13) = 296345083061712053722716462103 / 856326196254765600
RiemannPI(10^14) = 30189234512048649753828116713823 / 9419588158802421600
RiemannPI(10^15) = 92489654985220588144991271054976597 / 3099044504245996706400
RiemannPI(10^16) = 1146617973013522976708984977425080657 / 4106233968125945635980
RiemannPI(10^17) = 43091758212832458215850119943990751261 / 16424935872503782543920
RiemannPI(10^18) = 29968472027360099705216121701124772705819 / 1211339020597153962614100
RiemannPI(10^19) = 34589828635127927869863999345206682161220613 / 147783360512852783438920200
RiemannPI(10^20) = 138189551154910199110253731685916742453919111 / 62224572847516961447966400
RiemannPI(10^21) = 88080566389377854878591135538815093294467340937 / 4169046380783636417013748800
RiemannPI(10^22) = 82713438240421499874570664161132532019632247186099473 / 410555180440430163438262940577600
RiemannPI(10^23) = 263483420261441147355705259456363418174163088008435757 / 136851726813476721146087646859200
RiemannPI(10^24) = 199312549377508874879173849072922864723503113431443720379 / 10811286418264660970540924101876800
RiemannPI(10^25) = 1428216268887073538506983112166274277395419122408122239510533 / 8076030954443701744994070304101969600
RiemannPI(10^26) = 13723169359285085091924336231689687414362369542759969479728573 / 8076030954443701744994070304101969600
RiemannPI(10^27) = 21331406381807452349995058664653365273837322008799142085480723 / 1304476869229563439754033134419374400
