#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 25 October 2016
# Website: https://github.com/trizen

# sum(PI(n) - PI(n - sqrt(n)), {n=1, k})

# Interestingly,
#
#   PI(n) - PI(n - sqrt(n)) = 0
#
# only for n={1, 125, 126}, tested with n <= 10^6.

use 5.010;
use strict;
use warnings;

use ntheory qw(prime_count);

my $limit = shift(@ARGV) || 20;

my $sum = 0;
foreach my $n (1 .. $limit) {
    my $count = prime_count($n) - prime_count(int($n - sqrt($n)));
    $sum += $count;
    say $sum;
}

__END__
0
1
3
4
6
7
9
10
11
12
13
14
16
18
19
20
22
23
25
27
