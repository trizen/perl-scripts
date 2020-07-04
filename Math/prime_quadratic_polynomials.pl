#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 12 April 2015
# http://github.com/trizen

# A program that finds quadratic polynomials which will generate primes (with some gaps)
# -- algorithm complexity: O(n) --

# See also: http://en.wikipedia.org/wiki/Formula_for_primes

use 5.010;
use strict;
use warnings;

use ntheory qw(is_prime);

my $i = 1;
my $j = 1;

my $n = shift(@ARGV) // 8000000;    # duration: about 7 seconds
my $limit = int(sqrt($n)) - 1;

my %top;                          # store some info about primes
my $top = 10;                     # how many formulas to display at the end

for my $m (reverse(0 .. $limit)) {
    my $pos = $m;
    for my $n ($j .. $i**2) {
        $top{$pos}{height} //= $i;
        $top{$pos}{count}  //= 0;
        if (is_prime($j)) {
            $top{$pos}{count}++;
            $top{$pos}{first} //= $j;
        }
        ++$pos;
        ++$j;
    }
    ++$i;
}

my $counter = 0;
foreach my $i (sort { $top{$b}{count} <=> $top{$a}{count} } keys %top) {
    say(
        "height: "            => $top{$i}{height},
        "; count: "           => $top{$i}{count},
        "; first: "           => $top{$i}{first},
        "\nf(n) = n^2 + n + " => $top{$i}{height},
        "\ng(n) = n^2 + "     => ($top{$i}{height} * 2 + 1) . 'n + ' . (($top{$i}{height} + 1)**2 - 1),
        "\n"
       );
    last if ++$counter == $top;
}
