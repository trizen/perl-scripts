#!/usr/bin/perl

# Simulation of the 100 Prisoners Riddle.

# See also the Veritasium video on this problem:
#   https://yewtu.be/watch?v=iSNsgj1OCLA

use 5.014;
use strict;
use warnings;

use List::Util qw(shuffle);

my $ok        = 0;
my $runs      = 10000;
my $prisoners = 100;

for my $n (1 .. $runs) {

    my @boxes = shuffle(0 .. $prisoners - 1);

    my $success = 1;

    foreach my $k (0 .. $prisoners - 1) {

        my $found = 0;
        my $pick  = $boxes[$k];

        for (my $tries = $prisoners >> 1 ; $tries > 0 ; --$tries) {
            if ($pick == $k) {
                $found = 1;
                last;
            }
            $pick = $boxes[$pick];
        }

        if (not $found) {
            $success = 0;
            last;
        }
    }

    if ($success) {
        ++$ok;
    }
}

say "Probability of success: ", ($ok / $runs * 100), '%';

__END__
Probability of success: 31.52%
