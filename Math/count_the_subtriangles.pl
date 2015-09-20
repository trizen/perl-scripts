#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 September 2015
# Website: https://github.com/trizen

# A general formula for counting the number of possible triangles inside a triangle.
# The formula is: Σ{n=0,h} (2n+1)(h-n-1)

# For example, the following triangle:
#    1
#   234
#  56789

# Has 5 different triangles inside:
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

sub count_triangles {
    my ($height) = @_;

    my $total = 0;
    foreach my $n (0 .. $height / 2) {
        $total += (2 * $n + 1) * ($height - $n - 1);
    }

    $total;
}

foreach my $i (1 .. 10) {
    CORE::say "$i: ", count_triangles($i);
}
