#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 September 2014
# Website: http://github.com/trizen

use 5.010;
use strict;
use warnings;

my $num = 851230412;
my $lim = int(log($num) / log(10));

for (my $i = 0, my $j = 0, my $k = 1 ; $i <= $lim ; $i++, $k = 10**$i) {
    say my $u = ($num - $j) % ($k * 10) / $k;
    $j += $u * $k;
}

__END__
2
1
4
0
3
2
1
5
8
