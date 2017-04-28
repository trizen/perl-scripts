#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 September 2016
# https://github.com/trizen

# An experimental binary sieve for prime numbers.

=for comment

We can represent the first n numbers (greater than 1) as a sequence of 1-bits in the following way:

    11111 is equivalent with (2, 3, 4, 5, 6)

From this, we can start XOR-ing and AND-ing the bits until they end up representing only the prime numbers.

Example:

    x = 11111111

    p = x
    x ^= 101010
    x &= p

    p = x
    x ^= 1001
    x &= p

In the end, x is: 11010100, where each bit of 1 represents a prime number in the following set: (2, 3, 4, 5, 6, 7, 8, 9)

Visualizing this, each number that has a bit of 1 in its corresponding position, is a prime number:

    [2, 3, 4, 5, 6, 7, 8, 9]
    [1, 1, 0, 1, 0, 1, 0, 0]

For making this a general-purpose sieve, more work is required.

=cut

use 5.010;
use strict;
use warnings;

#use Math::AnyNum qw(:overload);
use ntheory qw(todigitstring);

my $n = 9;
my $t = (1 << ($n - 1)) - 1;

my $k = 1;

sub formula {
    my ($s) = @_;
    2**($k) / (2**($k + 1) - 1) * (2**($s * int($n / $s)) - 1);
}

say todigitstring($t, 2);

my $sum  = 0;
my $pow  = 1 << ($n - 2);

say todigitstring($pow, 2);

foreach my $z (2 .. sqrt($n)) {
    $z   += 0;
    $sum += $z;

    my $prev = $t;
    $t ^= formula($z) >> $sum;
    $t &= $prev;

    say "$z -> ", todigitstring(formula($z) >> $sum, 2);
    say "t -> ", todigitstring($t, 2);

    ++$k;
}
