#!/usr/bin/perl

# Finding the longest repeated substring

# Java code from:
#   http://stackoverflow.com/questions/10355103/finding-the-longest-repeated-substring

use 5.010;
use strict;
use warnings;

no warnings 'recursion';

my $max_len = 0;
my $max_str = "";

sub insert_in_suffix_tree {
    my ($root, $str, $index, $original_suffix, $level) = @_;
    $level //= 0;

    push @{$root->{indexes}}, $index;

    if ($#{$root->{indexes}} > 0 && $max_len < $level) {
        $max_len = $level;
        $max_str = substr($original_suffix, 0, $level);
    }

    return if ($str eq q{});

    my $child;
    my $first_char = substr($str, 0, 1);
    if (not exists $root->{children}{$first_char}) {
        $child = {};
        $root->{children}{$first_char} = $child;
    }
    else {
        $child = $root->{children}{$first_char};
    }

    insert_in_suffix_tree($child, substr($str, 1), $index, $original_suffix, $level + 1);
}

my $str = @ARGV ? join('', <>) : "abracadabra";

my %root;
foreach my $i (0 .. length($str) - 1) {
    my $s = substr($str, $i);
    insert_in_suffix_tree(\%root, $s, $i, $s);
}

say "[$max_len]: $max_str";
