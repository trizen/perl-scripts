#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 April 2015
# Website: https://github.com/trizen

# A very good and very fast compression algorithm. (concept only)

use 5.010;
use strict;
use warnings;

sub lzt_compress {
    my ($str) = @_;

    my $k   = 0;     # must be zero
    my $min = 4;     # the minimum length of a substring
    my $max = 15;    # the maximum length of a substring

    my $i        = 0;     # iterator (0 to length(str)-1)
    my $remember = 0;     # remember mode
    my $memo     = '';    # short-term memory

    my @dups;             # array of duplicated substrings with positions
    my @cache;            # cache of substrings
    my %dict;             # dictionary of substrings

    foreach my $c (split(//, $str)) {

        if (not $remember and exists $dict{$c}) {
            $remember = 1;    # activate the remember mode
        }

        $cache[$_] .= $c for ($k .. $i);    # create the substrings

        # If remember mode is one, do some checks.
        if ($remember) {

            # Check to see if $memo + the current character exists in the dictionary
            if (exists $dict{$memo . $c}) {
                ## say "found in cache [$i]: $memo$c";
            }

            # If it doesn't exists, then the $memo is the largest
            # duplicated substring in the dictionary at this point.
            else {
                $remember = 0;    # turn-off remember mode
                if (length($memo) >= $min) {    # check for the minimum length of the word
                    push @dups, [$dict{$memo}, length($memo), $memo, $i - length($memo)];
                }

                # $memo has been stored. Now, clear the memory.
                $memo = '';
            }

            # Remember one more character
            $memo .= $c;
        }

        # Increment the iterator
        $i++;

        # Create the dictionary from the cache of substrings
        foreach my $item (@cache) {
            exists($dict{$item})
              || ($dict{$item} = $i - length($item));
        }

        # Update the minimum length
        ++$k if (($i - $k) >= $max);
    }

    return \@dups;
}

#
## Usage
#

my $str = @ARGV ? do { local $/; <> } : "TOBEORNOTTOBEORTOBEORNOT#";
say '[', join(', ', @{$_}), ']' for @{lzt_compress($str)};
