#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 September 2015
# Website: https://github.com/trizen

# A general formula for counting the number of possible triangles inside a triangle.

## The formula is:
#
#    Sum((2n+1)(k-n-1), {n=0, k-1})
#
# where "k" is the number of rows of the triangle.

# For example, the following triangle:
#    1
#   234
#  56789

# Has 3 rows and 5 different triangles inside:
#    1
#   234
#  56789
#
#    1
#   234
#
#    2
#   567
#
#    3
#   678
#
#    4
#   789

sub count_subtriangles {
    my ($height) = @_;

    my $total = 0;
    foreach my $n (0 .. $height - 1) {
        $total += (2 * $n + 1) * ($height - $n - 1);
    }

    $total;
}

foreach my $i (1 .. 20) {
    printf("%2d: %s\n", $i, count_subtriangles($i));
}

__END__
 1: 0
 2: 1
 3: 5
 4: 14
 5: 30
 6: 55
 7: 91
 8: 140
 9: 204
10: 285
11: 385
12: 506
13: 650
14: 819
15: 1015
16: 1240
17: 1496
18: 1785
19: 2109
20: 2470
