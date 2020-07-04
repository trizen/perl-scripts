#!/usr/bin/perl

#
## Test Perl's pseudorandom number generator with `dieharder`.
#

# usage:
#       perl dieharder.pl > rand.txt && dieharder -g 202 -f rand.txt -a

use 5.014;
use strict;
use warnings;

my $seed  = srand();
my $count = 1e6;
my $bits  = 32;

print <<"EOT";
#==================================================================
# generator lcg  seed = $seed
#==================================================================
type: d
count: $count
numbit: $bits
EOT

my $max = 2**$bits;

for (1 .. $count) {
    say int(rand($max));
}
