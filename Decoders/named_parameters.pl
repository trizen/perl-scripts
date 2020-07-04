#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 23 October 2015
# Website: https://github.com/trizen

# Code-concept for implementing the "named-parameters" feature in programming languages.

=for Sidef example:

    func test (x, y, z) {
        say (x, y, z);      # prints: '123'
    }

    test(1,2,3);
    test(1, y: 2, z: 3);
    test(x: 1, y: 2, z: 3);
    test(y: 2, z: 3, x: 1);
    ...

=cut

use 5.010;
use strict;
use warnings;

use List::Util qw(shuffle);

sub test {
    my @args = @_;
    my @vars = (\my $x, \my $y, \my $z);

    my %table = (
                 x => 0,
                 y => 1,
                 z => 2,
                );

    my @left;
    my %seen;

    foreach my $arg (@args) {
        if (ref($arg) eq 'ARRAY') {
            if (exists $table{$arg->[0]}) {
                ${$vars[$table{$arg->[0]}]} = $arg->[1];
                undef $seen{$vars[$table{$arg->[0]}]};
            }
            else {
                die "No such named argument: <<$arg->[0]>>";
            }
        }
        else {
            push @left, $arg;
        }
    }

    foreach my $var (@vars) {
        next if exists $seen{$var};
        if (@left) {
            ${$var} = shift @left;
        }
    }

    say "$x $y $z";
    ($x == 1 and $y == 2 and $z == 3) or die "error!";
}

test(1, ['y', 2], 3);
test(1, 3, ['y', 2]);
test(1, ['z', 3], 2);
test(1, 2, ['z', 3]);
test(1, 3, ['y', 2]);
test(['y', 2], 1, 3);
test(['x', 1], ['z', 3], ['y', 2]);
test(shuffle(['x', 1], 3, ['y', 2]));
test(shuffle(['x', 1], 2, ['z', 3]));
test(shuffle(1, ['y', 2], ['z', 3]));
test(shuffle(['z', 3], ['x', 1], ['y', 2]));
test(shuffle(['z', 3], 1, ['y', 2]));
