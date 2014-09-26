#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 02 July 2014
# Edit: 15 July 2014
# http://github.com/trizen

# Map a mathematical function on the xOy axis.
# usage: perl fgraph.pl 'function' 'graph-size' 'from' 'to'
# usage: perl fgraph.pl '$x**2 + 1'

use 5.010;
use strict;
use warnings;

my $e = exp(1);
my $pi = atan2(0, -'inf');

my $function = @ARGV ? shift @ARGV : ();

my $f =
  defined($function)
  ? (eval("sub {my(\$x) = \@_; $function}") // die "Invalid function '$function': $@")
  : sub { my ($x) = @_; $x**2 + 1 };

my $size = 150;
my $range = [-8, 8];

if (@ARGV) {
    $size = shift @ARGV;
}

if (@ARGV) {
    $range->[0] = shift @ARGV;
}

if (@ARGV) {
    $range->[1] = shift @ARGV;
}

if (@ARGV) {
    die "Too many arguments! (@ARGV)";
}

# Generic creation of a matrix
sub create_matrix {
    my ($size, $val) = @_;
    int($size / 2), [map { [($val) x ($size)] } 0 .. $size - 1];
}

# Create a matrix
my ($i, $matrix) = create_matrix($size, ' ');

# Assign the point inside the matrix
sub assign {
    my ($x, $y, $value) = @_;

    $x += $i;
    $y += $i;

    $matrix->[-$y][$x] = $value;
}

# Map the function
foreach my $x ($range->[0] .. $range->[1]) {
    my $y = eval { $f->($x) };

    if ($@) {
        warn "Function f(x)=${\($function=~s/\$//rg=~s/\*\*/^/rg)} is not defined for x=$x\n";
        next;
    }

    say "($x, $y)";    # this line prints the coordonates
    assign($x, $y, 'o');    # this line maps the value of (x, f(x)) on the graph
}

# Init the GD::Simple module
require GD::Simple;
my $img = GD::Simple->new($i * 2, $i * 2);

my $imgFile = 'graph.png';

sub l {
    $img->line(shift);
}

sub c {
    $img->fgcolor(shift);
}

sub mv {
    $img->moveTo(@_);
}

mv(0, 0);

# Create the image from the 2D-matrix
while (my ($k, $row) = each @{$matrix}) {
    while (my ($l, $col) = each @{$row}) {
        if ($col eq ' ') {
            if ($k == $i) {    # the 'x' line
                c('white');
                l(1);
            }
            elsif ($l == $i) {    # the 'y' line
                c('white');
                l(1);
            }
            else {                # space
                c('black');
                l(1);
            }
        }
        else {                    # everything else
            c('red');
            l(1);
        }
    }
    mv(0, $k + 1);
}

# Create the PNG file
open my $fh, '>', $imgFile;
print {$fh} $img->png;
close $fh;

# Display the graph
system('gliv', $imgFile);
