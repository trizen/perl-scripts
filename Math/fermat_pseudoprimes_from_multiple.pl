#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 March 2023
# https://github.com/trizen

# Generate Fermat pseudoprimes from a given multiple, to a given base.

# See also:
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.036;
use ntheory qw(:all);

sub fermat_pseudoprimes_from_multiple ($base, $m, $callback) {

    my $L = znorder($base, $m);
    my $v = invmod($m, $L) // return;

    for (my $p = $v ; ; $p += $L) {
        if (is_pseudoprime($m * $p, $base)) {
            $callback->($m * $p);
        }
    }
}

fermat_pseudoprimes_from_multiple(2, 341, sub ($n) { say $n });
