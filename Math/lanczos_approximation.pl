#!/usr/bin/perl

# Algorithm from Wikipedia:
#   https://en.wikipedia.org/wiki/Lanczos_approximation#Simple_implementation

use 5.020;
use strict;
use warnings;

use Math::AnyNum qw(:overload pi real imag);
use experimental qw(signatures lexical_subs);

sub gamma($z) {
    my $epsilon = 0.0000001;

    my sub withinepsilon($x) {
        abs($x - abs($x)) <= $epsilon;
    }

    state $p = [
        676.5203681218851,     -1259.1392167224028,
        771.32342877765313,    -176.61502916214059,
        12.507343278686905,    -0.13857109526572012,
        9.9843695780195716e-6,  1.5056327351493116e-7,
    ];

    my $result;
    if (real($z) < 0.5) {
        $result = (pi / (sin(pi * $z) * gamma(1 - $z)));
    }
    else {
        $z -= 1;
        my $x = 0.99999999999980993;

        while (my ($i, $pval) = each @$p) {
            $x += $pval / ($z + $i + 1);
        }

        my $t = ($z + @$p - 0.5);
        $result = (sqrt(pi * 2) * $t**($z + 0.5) * exp(-$t) * $x);
    }

    withinepsilon(imag($result)) ? real($result) : $result;
}

foreach my $i (0.5, 4, 5, 6, 30, 40, 50) {
    printf("gamma(%3s) =~ %s\n", $i, gamma($i));
}

__END__
gamma(0.5) =~ 1.77245385090551659496855986697771284175944211142
gamma(  4) =~ 6.00000000000000628999184513591742545418327380194
gamma(  5) =~ 24.0000000000000308599507225303222574058679398028
gamma(  6) =~ 120.000000000000178632999163000072600390777175518
gamma( 30) =~ 8841761993739669928012342097034.15093049782426111
gamma( 40) =~ 20397882081197200259694400837033107505429486392
gamma( 50) =~ 6.08281864034254395430563164837656389765153447987e62
