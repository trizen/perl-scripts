#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 02 July 2014
# Edit: 15 July 2014
# http://github.com/trizen

# Map a mathematical function on the xOy axis.

use 5.010;
use strict;
use autodie;
use warnings;

use GD::Simple qw();
use Getopt::Long qw(GetOptions);

my $e = exp(1);
my $pi = atan2(0, -'inf');

my $size = 150;
my $step = 1e-2;
my $from = -5;
my $to   = abs($from);

my $v = !1;
my $f = sub { my ($x) = @_; $x**2 + 1 };

my $output_file  = 'graph.png';
my $image_viewer = 'gliv';

GetOptions(
    'size|s=f'     => \$size,
    'step=f'       => \$step,
    'from=f'       => \$from,
    'to|t=f'       => \$to,
    'verbose|v!'   => \$v,
    'output|o=s'   => \$output_file,
    'viewer|iv=s'  => \$image_viewer,
    'function|f=s' => sub {
        my (undef, $value) = @_;
        $f = eval("sub {my(\$x) = \@_; $value}") // die "Invalid function '$value': $@";
    },
  )
  || die("Error in command line arguments\n");

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
for (my $x = $from ; $x <= $to ; $x += $step) {
    my $y = eval { $f->($x) };

    if ($@) {
        warn "f($x) is not defined!\n";
        next;
    }

    $y = sprintf('%.0f', $y);
    say "($x, $y)" if $v;    # this line prints the coordonates
    assign($x, $y, 'o');     # this line maps the value of (x, f(x)) on the graph
}

# Init the GD::Simple module
my $img = GD::Simple->new($i * 2, $i * 2);

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
open my $fh, '>', $output_file;
print {$fh} $img->png;
close $fh;

# Display the graph
system($image_viewer, $output_file);
