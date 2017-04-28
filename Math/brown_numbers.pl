#!/usr/bin/perl

# See: http://www.youtube.com/watch?v=-Djj6pfR9KU

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(factorial is_power);

for my $i (1 .. 60) {
    my $n = factorial($i) + 1;
    is_power($n) || next;
    printf("(%d, %d)\n", int(sqrt($n)), $i);
}

__END__
(5, 4)
(11, 5)
(71, 7)
