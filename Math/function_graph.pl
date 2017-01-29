#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 02 July 2014
# http://github.com/trizen

# Map a mathematical function on the xOy axis.

use 5.010;
use strict;
use warnings;

# Generic creation of a matrix
sub create_matrix {
    my ($size, $val) = @_;
    int($size / 2), [map { [($val) x ($size)] } 0 .. $size - 1];
}

# Create a matrix
my ($i, $matrix) = create_matrix(65, ' ');

# Assign the point inside the matrix
sub assign {
    my ($x, $y, $value) = @_;

    $x += $i;
    $y += $i + 1;

    $matrix->[-$y][$x] = $value;
}

# Map the function
foreach my $x (-5 .. 5) {
    my $fx = $x**2 + 1;    # this is the function
    say "($x, $fx)";       # this line prints the coordinates
    assign($x, $fx, 'o');  # this line maps the value of (x, f(x)) on the graph
}

# Display the graph
while (my ($k, $row) = each @{$matrix}) {
    while (my ($l, $col) = each @{$row}) {
        if ($col eq ' ') {
            if ($k == $i) {    # the 'x' line
                print '-';
            }
            elsif ($l == $i) {    # the 'y' line
                print '|';
            }
            else {                # space
                print $col;
            }
        }
        else {                    # everything else
            print $col;
        }
    }
    print "\n";                   # new line
}
