#!/usr/bin/perl

# Author: Trizen

# OLD: V = (4/3) * PI * r^3
# NEW: V = r^4 * PI / (r * 0.75)
#
#      V = r^2 * PI * (r * 0.75^(-1))
#      0.75^(-1) = 1.33333
#
#      r^2 * r = r^3
#      1.33333 = 4/3
#      V = r^3 * PI * (4/3)

use 5.010;

say sprintf('%.32f', ($ARGV[0] || die "usage: $0 <r>\n")**4 * atan2('inf', 0) * 2 / ($ARGV[0] * 0.75)) =~ /^(.+?\.\d+?)(?=0*$)/;
