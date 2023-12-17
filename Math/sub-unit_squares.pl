#!/usr/bin/perl

# Efficient algorithm for generating sub-unit squares.

# A sub-unit square is a square number that remains a square after having a 1 subtracted from each digit in the square.

# See also:
#   https://oeis.org/A061844
#   https://rosettacode.org/wiki/Sub-unit_squares

use 5.036;
use ntheory      qw(:all);
use Math::GMP    qw(:constant);
#use Math::AnyNum qw(:overload);

sub difference_of_two_squares_solutions ($n) {    # solutions x to x^2 - y^2 = n

    my @solutions;
    my $limit = sqrtint($n);

    foreach my $divisor (divisors($n)) {

        last if $divisor > $limit;

        my $p = $divisor;
        my $q = $n / $divisor;

        ($p + $q) % 2 == 0 or next;

        my $x = ($q + $p) >> 1;
        unshift @solutions, $x;
    }

    return @solutions;
}

my $N    = 34;         # how many terms to compute
my %seen = (1 => 1);

my $index = 1;
say($index, ': ', 1);

OUTER: for (my $n = 1 ; ; ++$n) {

    my $r = (10**$n - 1) / 9;

    foreach my $x (difference_of_two_squares_solutions($r)) {

        my $xsqr = $x**2;
        my @d    = todigits($xsqr);

        next if $d[0] == 1;
        next if !vecall { $_ } @d;
        next if !is_square(fromdigits([map { $_ - 1 } @d]));

        if (!$seen{$xsqr}++) {
            say(++$index, ': ', $xsqr);
            last OUTER if ($index >= $N);
        }
    }
}

__END__
1: 1
2: 36
3: 3136
4: 24336
5: 5973136
6: 71526293136
7: 318723477136
8: 264779654424693136
9: 24987377153764853136
10: 31872399155963477136
11: 58396845218255516736
12: 517177921565478376336
13: 252815272791521979771662766736
14: 518364744896318875336864648336
15: 554692513628187865132829886736
16: 658424734191428581711475835136
17: 672475429414871757619952152336
18: 694688876763154697414122245136
19: 711197579293752874333735845136
20: 975321699545235187287523246336
21: 23871973274358556957126877486736
22: 25347159162241162461433882565136
23: 34589996454813135961785697637136
24: 2858541763747552538199941619545257144336
25: 214785886789716796533667464535274377236736
26: 233292528132679183463629157143235636286736
27: 244671849793441155421899813243325528686736
28: 271571567929448516411695557685613529966736
29: 322388381596588665613523969581347191316736
30: 385414415625146742626881165526237149942336
31: 494827714874767379344736911473964125592336
32: 729191918879671448289782722539515523333136
33: 739265858539339252384919139328667324488336
34: 451616391374794616993675837721511769881724292768597136
