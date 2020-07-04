#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 06 July 2015
# Website: https://github.com/trizen

# Prime factorization in polynomial time (concept only)

use 5.010;
use strict;
use warnings;

#
## The backwards process of:
#

#   23 *
#   17
#  ----
#  161
#  23
# -----
#  391

# 23
my $x2 = 2;
my $x1 = 3;

# 17
my $y2 = 1;
my $y1 = 7;

# {
#    1=10*(a*c/10-floor(a*c/10)),
#    9=10*(b*c/10-floor(b*c/10))+floor(a*c/10)+10*(a*d/10-floor(a*d/10)),
#    3=floor((b*c+floor(a*c/10))/10)+10*(b*d/10-floor(b*d/10))
# }

# Last digit
say(($x1 * $y1) % 10);

# Middle digit
say((($x2 * $y1) % 10) + int($x1 * $y1 / 10) + (($x1 * $y2) % 10));

# First digit
say(int((($x2 * $y1) + int($x1 * $y1 / 10)) / 10) + (($x2 * $y2) % 10));


#
## Alternate forms:
#

say "-" x 80;

# Last digit
say(($x1 * $y1 / 10 - int($x1 * $y1 / 10)) * 10);

# Middle digit
say(int($x1 * $y1 / 10) - 10 * int($x1 * $y2 / 10) + $x1 * $y2 - 10 * int($x2 * $y1 / 10) + $x2 * $y1);

# First digit
say(int($x2 * $y1 / 10 + int($x1 * $y1 / 10) / 10) + 10 * ($x2 * $y2 / 10 - int($x2 * $y2 / 10)));
