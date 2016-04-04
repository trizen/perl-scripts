#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 April 2016
# Website: https://github.com/trizen

# Recursive matrix multiplication, using a divide and conquer algorithm.
# See also: https://en.wikipedia.org/wiki/Matrix_multiplication

# NOTE: works only with n*n matrices, where n must be a power of 2.

use 5.010;
use strict;
use warnings;

sub add {
    my ($A, $B) = @_;

    my $C = [[]];

    foreach my $i (0 .. $#{$A}) {
        foreach my $j (0 .. $#{$A->[$i]}) {
            $C->[$i][$j] += $A->[$i][$j] + $B->[$i][$j];
        }
    }

    $C;
}

sub msplit {
    my ($A, $B, $C, $D) = @_;

    my $end = $#{$A};
    my $mid = int($end / 2);

    my @A = @{$A}[0 .. $mid];
    my @B = @{$B}[0 .. $mid];

    my @C = @{$A}[$mid + 1 .. $end];
    my @D = @{$B}[$mid + 1 .. $end];

    my @E = @{$C}[0 .. $mid];
    my @F = @{$D}[0 .. $mid];

    my @G = @{$C}[$mid + 1 .. $end];
    my @H = @{$D}[$mid + 1 .. $end];

#<<<
    if ($end > 3) {
        return
            msplit(\@A, \@C, \@B, \@D),
            msplit(\@E, \@G, \@F, \@H);
    }
#>>>

#<<<
    [
        [@A, @B],
        [@C, @D],
        [@E, @F],
        [@G, @H],
    ]
#>>>
}

#
## Known issue: broken
#
sub merge_rows {
    my (@blocks) = @_;

    if (@{$blocks[0]} > 4) {

        my @merged;
        while (@{$blocks[0]}) {
            my @rows;
            foreach my $block (@blocks) {
                push @rows, [splice(@{$block}, 0, 4)];
            }
            push @merged, @{merge_rows(@rows)};
        }

        return \@merged;
    }

    my @A;

    foreach my $i (0 .. 3) {
        push @{$A[$i]}, @{$blocks[0][$i]}, @{$blocks[1][$i]};
        push @{$A[$i + 4]}, @{$blocks[2][$i]}, @{$blocks[3][$i]};
    }

    return \@A;
}

#
## Known issue: broken
#
sub merge {
    my (@blocks) = @_;

    while (@blocks > 4) {
        push @blocks, merge_rows(splice(@blocks, 0, 4));
    }

    return merge_rows(@blocks);
}

sub mul {
    my ($A, $B) = @_;

    ## Base case:
#<<<
    if ($#{$A} == 1 and $#{$A->[0]} == 1 and $#{$B} == 1 and $#{$B->[0]} == 1) {
        return [
            [
                $A->[0][0] * $B->[0][0] + $A->[0][1] * $B->[1][0],
                $A->[0][0] * $B->[0][1] + $A->[0][1] * $B->[1][1],
            ],
            [
                $A->[1][0] * $B->[0][0] + $A->[1][1] * $B->[1][0],
                $A->[1][0] * $B->[0][1] + $A->[1][1] * $B->[1][1],
            ],
        ];
    }
#>>>

    my $end = $#{$A};
    my $mid = int($end / 2);

    my @A = map { [@{$_}[0 .. $mid]] } @{$A}[0 .. $mid];
    my @B = map { [@{$_}[$mid + 1 .. $end]] } @{$A}[0 .. $mid];

    my @C = map { [@{$_}[0 .. $mid]] } @{$A}[$mid + 1 .. $end];
    my @D = map { [@{$_}[$mid + 1 .. $end]] } @{$A}[$mid + 1 .. $end];

    my @E = map { [@{$_}[0 .. $mid]] } @{$B}[0 .. $mid];
    my @F = map { [@{$_}[$mid + 1 .. $end]] } @{$B}[0 .. $mid];

    my @G = map { [@{$_}[0 .. $mid]] } @{$B}[$mid + 1 .. $end];
    my @H = map { [@{$_}[$mid + 1 .. $end]] } @{$B}[$mid + 1 .. $end];

#<<<
    [
        (
            [map{@{$_}} @{add(mul(\@A, \@E), mul(\@B, \@G))}],
            [map{@{$_}} @{add(mul(\@A, \@F), mul(\@B, \@H))}],
            [map{@{$_}} @{add(mul(\@C, \@E), mul(\@D, \@G))}],
            [map{@{$_}} @{add(mul(\@C, \@F), mul(\@D, \@H))}]
        ),
    ];
#>>>
}

sub mmult {
    our @a;
    local *a = shift;
    our @b;
    local *b = shift;
    my @p    = [];
    my $rows = @a;
    my $cols = @{$b[0]};
    my $n    = @b - 1;
    for (my $r = 0 ; $r < $rows ; ++$r) {

        for (my $c = 0 ; $c < $cols ; ++$c) {
            foreach (0 .. $n) {
                $p[$r][$c] += $a[$r][$_] * $b[$_][$c];
            }
        }
    }
    return [@p];
}

sub new_matrix {
    my ($n) = @_;
    [map { [$n * $_ - $n + 1 .. $_ * $n] } 1 .. $n];
}

sub display_matrix {
    my ($A, $w) = @_;
    say join(
        "\n",
        map {
            join(' ', map { sprintf("%${w}d", $_) } @{$_})
          } @{$A}
    );
}

#
## Demo:
#

my $A = [[3, 4], [5, 6]];

use Data::Dump qw(pp);
pp mul($A, $A);
pp mmult($A, $A);

my $B = new_matrix(4);

pp mmult($B, $B);
pp mul($B, $B);

my $C = new_matrix(8);
my $D = mmult($C, $C);

display_matrix($D, 6);

my $x = mul($C, $C);
pp msplit(@{$x});
