#!/usr/bin/perl

# Find all the factorions in base n.

# See also:
#   https://oeis.org/A193163
#   https://rosettacode.org/wiki/Factorions

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);
use Algorithm::Combinatorics qw(combinations_with_repetition);

sub max_power ($base = 10) {
    my $m = 1;
    my $f = factorial($base-1);
    while ($m * $f >= $base**($m-1)) {
        $m += 1;
    }
    return $m-1;
}

sub factorions ($base = 10) {

    my @result;
    my @digits    = (0 .. $base-1);
    my @factorial = map { factorial($_) } @digits;

    foreach my $k (1 .. max_power($base)) {
        my $iter = combinations_with_repetition(\@digits, $k);
        while (my $comb = $iter->next) {
            my $n = vecsum(map { $factorial[$_] } @$comb);
            if (join(' ', sort { $a <=> $b } todigits($n, $base)) eq join(' ', @$comb)) {
                push @result, $n;
            }
        }
    }

    return @result;
}

foreach my $base (2 .. 14) {
    my @r = factorions($base);
    say "Factorions in base $base are (@r)";
}

__END__
Factorions in base 2 are (1 2)
Factorions in base 3 are (1 2)
Factorions in base 4 are (1 2 7)
Factorions in base 5 are (1 2 49)
Factorions in base 6 are (1 2 25 26)
Factorions in base 7 are (1 2)
Factorions in base 8 are (1 2)
Factorions in base 9 are (1 2 41282)
Factorions in base 10 are (1 2 145 40585)
Factorions in base 11 are (1 2 26 48 40472)
Factorions in base 12 are (1 2)
Factorions in base 13 are (1 2 519326767)
Factorions in base 14 are (1 2 12973363226)
