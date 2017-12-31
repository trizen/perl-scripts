#!/usr/bin/perl

# Formula due to Ramanujan for computing the nth-Bernoulli number.

# This are the unreduced fractions.

# See also:
#   https://en.wikipedia.org/wiki/Bernoulli_number#Ramanujan's_congruences

use 5.020;
use warnings;

use experimental qw(signatures);

use List::Util qw(sum);
use Math::Bacovia qw(Fraction Number);
use Math::AnyNum qw(binomial bernfrac);

sub ramanujan_bernoulli_number ($n, $cache = {}) {

    return Fraction(1, 2) if ($n   == 1);
    return Fraction(0, 1) if ($n%2 == 1);

    $cache->{$n} //= do {
        (($n%6 == 4 ? Fraction(-1, 2) : 1) * Fraction($n+3, 3) -
            (sum(map {
                Number(binomial($n+3, $n - 6*$_)) * __SUB__->($n - 6*$_, $cache)
            } 1 .. ($n - $n%6) / 6) // 0)
        ) / Number(binomial($n+3, $n))
    };
}

foreach my $n (1..15) {
    say ramanujan_bernoulli_number(2*$n);
}

__END__
Fraction(5, 30)
Fraction(-7, 210)
Fraction(18, 756)
Fraction(-495, 14850)
Fraction(27300, 360360)
Fraction(-783594, 3095820)
Fraction(1060290000, 908820000)
Fraction(-3120392555280, 439977938400)
Fraction(1540021169559600, 28015065842400)
Fraction(-1138211737294401000000, 2151123774030000000)
Fraction(2845151832177208505952000000, 459479203757525952000000)
Fraction(-149443274714737339648102583520000, 1726066502932685055105600000)
Fraction(13609846707523944448974596493300000000000000, 9547304673537038744166600000000000000)
Fraction(-11263363110434888054130093206882749787055697920000000000, 412604138431303034312458421474352537600000000000)
Fraction(3343163067256114252216624560628967465552283801361747968000000000, 5557296138055536045317952219562393233733243699200000000)
