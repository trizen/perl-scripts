#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 19 August 2025
# https://github.com/trizen

# A recursive sorting algorithm for strings, based on a dream that I had, similar to Radix sort.

# The running time of the algorithm is:
#   O(n * len(s))
# where `n` is the number of strings being sorted and `s` is the longest string in the array.

use 5.036;
use List::Util qw(shuffle);
use Test::More tests => 20;

sub dream_sort($arr, $i = 0) {

    my @buckets;

    foreach my $item (@$arr) {
        my $byte = substr($item, $i, 1) // '';
        if ($byte eq '') {
            $byte = 0;
        }
        else {
            $byte = ord($byte) + 1;
        }
        push @{$buckets[$byte]}, $item;
    }

    my @sorted;

    if (defined($buckets[0])) {
        push @sorted, @{$buckets[0]};
    }

    foreach my $k (1 .. $#buckets) {
        my $entry = $buckets[$k];
        if (defined($entry)) {
            if (scalar(@$entry) == 1) {
                push @sorted, $entry->[0];
            }
            else {
                push @sorted, @{__SUB__->($entry, $i + 1)};
            }
        }
    }

    return \@sorted;
}

sub sort_test($arr) {
    my @sorted = sort @$arr;
    is_deeply(dream_sort($arr),             \@sorted);
    is_deeply(dream_sort([reverse @$arr]),  \@sorted);
    is_deeply(dream_sort(\@sorted),         \@sorted);
    is_deeply(dream_sort([shuffle(@$arr)]), \@sorted);
}

sort_test(["abc",  "abd"]);
sort_test(["abc",  "abc"]);
sort_test(["abcd", "abc"]);
sort_test(["John", "Kate", "Zerg", "Alice", "Joe", "Jane"]);

sort_test(
    do {
        open my $fh, '<:raw', __FILE__;
        local $/;
        [split(' ', scalar <$fh>)];
    }
);
