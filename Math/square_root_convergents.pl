#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 August 2016
# License: GPLv3
# https://github.com/trizen

# Find the convergents of a square root for a non-square positive integer.

# See also:
#    https://en.wikipedia.org/wiki/Pell%27s_equation#Solutions
#    https://en.wikipedia.org/wiki/Continued_fraction#Infinite_continued_fractions
#    http://www.wolframalpha.com/input/?i=Convergents%5BSqrt%5B61%5D%5D

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload isqrt);

sub sqrt_convergents {
    my ($n) = @_;

    my $x = isqrt($n);
    my $y = $x;
    my $z = 1;

    my @convergents = ($x);

    do {
        $y = int(($x + $y) / $z) * $z - $y;
        $z = int(($n - $y * $y) / $z);
        push @convergents, int(($x + $y) / $z);
    } until (($y == $x) && ($z == 1));

    return @convergents;
}

sub continued_frac {
    my ($i, $c) = @_;
    $i < 0 ? 0 : 1/($c->[$i] + continued_frac($i - 1, $c));
}

my @c = sqrt_convergents(61);

for my $i (0 .. $#c) {
    say continued_frac($i, \@c);
}

__END__

# Example for n=61:

1/7
7/8
8/39
39/125
125/164
164/453
453/1070
1070/1523
1523/5639
5639/24079
24079/29718
29718/440131
