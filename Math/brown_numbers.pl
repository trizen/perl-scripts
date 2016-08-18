#!/usr/bin/perl

# See: http://www.youtube.com/watch?v=-Djj6pfR9KU

use 5.010;
use strict;
use warnings;

use Math::BigNum;

for my $i (1 .. 60) {
    my $n = Math::BigNum->new($i)->fac + 1;
    $n->is_ppow || next;
    printf("(%d, %d)\n", int(sqrt($n)), $i);
}

__END__
(5, 4)
(11, 5)
(71, 7)
