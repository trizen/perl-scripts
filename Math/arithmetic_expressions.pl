#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 August 2016
# Website: https://github.com/trizen

# Generate arithmetic expressions, using a set of 4 integers and 4 operators.
# Problem from: https://projecteuler.net/problem=93

use 5.010;
use strict;
use warnings;

use ntheory qw(forperm);

my @op = ('+', '-', '*', '/');

my @expr = (
            "%d %s %d %s %d %s %d",
            "%d %s (%d %s (%d %s %d))",
            "%d %s ((%d %s %d) %s %d)",
            "(%d %s (%d %s %d)) %s %d",
            "%d %s (%d %s %d %s %d)",
            "%d %s (%d %s %d) %s %d",
            "%d %s %d %s (%d %s %d)",
            "((%d %s %d) %s %d) %s %d",
            "(%d %s %d) %s (%d %s %d)",
           );

sub evaluate {
    my ($nums, $ops, $table) = @_;
    foreach my $expr (@expr) {

        my $e = sprintf($expr,
            $nums->[0], $ops->[0],
            $nums->[1], $ops->[1],
            $nums->[2], $ops->[2],
            $nums->[3]
        );

        my $n = eval $e;

        if (not $@
            and $n > 0
            and int($n) eq $n) {
            push @{$table->{$n}}, $e;
        }
    }
}

sub compute {
    my ($set, $table) = @_;

    forperm {
        my @nums = @{$set}[@_];

        foreach my $i (0 .. 3) {
            foreach my $j (0 .. 3) {
                foreach my $k (0 .. 3) {
                    my @ops = @op[$i, $j, $k];
                    evaluate(\@nums, \@ops, $table);
                }
            }
        }

    }
    scalar(@$set);
}

my @set = (1, 2, 3, 4);
my $num = 28;

compute(\@set, \my %table);

if (exists $table{$num}) {
    say "\n=> Using the set [@set], the number $num can be represented as:\n";
    say join("\n", @{$table{$num}});
}
else {
    say "[!] The number $num cannot be represented as an arithmetic expression, using the set [@set].";
}

__END__

Using the set [1 2 3 4], the number 28 can be represented as:

(1 + (2 * 3)) * 4
(1 + (3 * 2)) * 4
((2 * 3) + 1) * 4
((3 * 2) + 1) * 4
4 * (1 + (2 * 3))
4 * (1 + 2 * 3)
4 * (1 + (3 * 2))
4 * (1 + 3 * 2)
4 * ((2 * 3) + 1)
4 * (2 * 3 + 1)
4 * ((3 * 2) + 1)
4 * (3 * 2 + 1)
