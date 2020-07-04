#!/usr/bin/perl

# Algorithm due to Aleksey Koval for computing the Lucas U and V sequences.

# See also:
#   https://en.wikipedia.org/wiki/Lucas_sequence

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::AnyNum qw(:overload digits);

sub lucasUV ($n, $P, $Q) {

    my ($V1, $V2) = (2, $P);
    my ($Q1, $Q2) = (1, 1);

    my @bits = digits($n, 2);

    while (@bits) {

        $Q1 *= $Q2;

        if (pop @bits) {
            $Q2 = ($Q1 * $Q);
            $V1 = ($V2 * $V1 - $P * $Q1);
            $V2 = ($V2 * $V2 - 2 * $Q2);
        }
        else {
            $Q2 = $Q1;
            $V2 = ($V2 * $V1 - $P * $Q1);
            $V1 = ($V1 * $V1 - 2 * $Q2);
        }
    }

    my $Uk = (2 * $V2 - $P * $V1) / ($P * $P - 4 * $Q);

    return ($Uk, $V1);
}

foreach my $n (1 .. 20) {
    say "[", join(', ', lucasUV($n, 1, -1)), "]";
}

__END__
[1, 1]
[1, 3]
[2, 4]
[3, 7]
[5, 11]
[8, 18]
[13, 29]
[21, 47]
[34, 76]
[55, 123]
[89, 199]
[144, 322]
[233, 521]
[377, 843]
[610, 1364]
[987, 2207]
[1597, 3571]
[2584, 5778]
[4181, 9349]
[6765, 15127]
