#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 18 August 2016
# Website: https://github.com/trizen

# Generate Pythagorean triples whose sum goes up to a certain limit.

# See also: https://projecteuler.net/problem=75
#           https://en.wikipedia.org/wiki/Pythagorean_triple

use 5.010;
use strict;
use warnings;

use ntheory qw(gcd);

sub pythagorean_triples {
    my ($limit) = @_;

    my @triples;
    my $end = int(sqrt($limit));

    foreach my $n (1 .. $end - 1) {
        for (my $m = $n + 1 ; $m <= $end ; $m += 2) {

            my $x = ($m**2 - $n**2);
            my $y = (2 * $m * $n);
            my $z = ($m**2 + $n**2);

            last if $x + $y + $z > $limit;

            if (gcd($n, $m) == 1) {    # n and m coprime

                my $k = 1;

                while (1) {
                    my $x = $k * $x;
                    my $y = $k * $y;
                    my $z = $k * $z;

                    last if $x + $y + $z > $limit;

                    push @triples, [$x, $y, $z];
                    ++$k;
                }
            }
        }
    }

    map { $_->[1] } sort { $a->[0] <=> $b->[0] } map {
        [$_->[0] + $_->[1] + $_->[2], [sort { $a <=> $b } @{$_}]]
    } @triples;
}

my @triples = pythagorean_triples(50);

foreach my $triple (@triples) {
    say "P(@$triple) = ", $triple->[0] + $triple->[1] + $triple->[2];
}

__END__
P(3 4 5) = 12
P(6 8 10) = 24
P(5 12 13) = 30
P(9 12 15) = 36
P(8 15 17) = 40
P(12 16 20) = 48
