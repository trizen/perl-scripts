#!/usr/bin/perl

# One-Roll Yahtzee Fever

# http://www.youtube.com/watch?v=dXGhzY2p2ug

my (@list) = (0) x 5;
my $count = 0;

do {
    foreach my $num (@list) {
        $num = int(rand 6) + 1;
    }
    ++$count;
} until grep({$_ == $list[0]} @list) == @list;

print "Rolls: $count\tNumber: $list[0]\n";
