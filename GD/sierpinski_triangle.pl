#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 20 December 2014
# https://github.com/trizen

# Generate a graphical Sierpinski triangle of a given size.

use 5.010;
use strict;
use warnings;
use GD::Simple;

sub sierpinski {
    my ($n)   = @_;
    my @down  = '*';
    my $space = ' ';
    foreach (1 .. $n) {
        @down = (map({ $space . $_ . $space } @down), map({ $_ . ' ' . $_ } @down));
        $space = $space . $space;
    }
    return @down;
}

my @lines = sierpinski(8);

my $size = $ARGV[0] // 2;
my $img = GD::Simple->new(length($lines[0]) * $size, scalar(@lines) * $size);

foreach my $i (0 .. $#lines) {
    foreach my $j ($i * $size .. $i * $size + $size) {
        $img->moveTo(0, $j);
        my $row = $lines[$i];
        while (1) {
            if ($row =~ s/^(\s+)//) {
                $img->fgcolor('black');
                $img->line($size * length($1));
            }
            elsif ($row =~ s/^(\S+)//) {
                $img->fgcolor('red');
                $img->line($size * length($1));
            }
            else {
                last;
            }
        }
    }
}

open my $fh, '>:raw', 'triangle.png';
print $fh $img->png;
close $fh;
