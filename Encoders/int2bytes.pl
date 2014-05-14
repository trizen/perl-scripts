#!/usr/bin/perl

# Author: Șuteu "Trizen" Daniel
# License: GPLv3
# Date: 18 August 2013
# http://trizenx.blogspot.com

# Get all the shortest possible combinations of byte values for a large integer.

use 5.010;
use strict;
use warnings;

use List::Util qw(min);

sub _make_map {
    my ($int) = @_;

    my @groups = ([], [], []);
    for my $i (1 .. 3) {
        foreach my $j (0 .. length($int) - $i) {
            $i > 1 && substr($int, $j, 1) == 0 && next;
            (my $num = substr($int, $j, $i)) > 255 && next;
            $groups[$i - 1][$j] = $num;
        }
    }

    my @map = [[]];
    for (my $j = 0 ; $j <= $#{$groups[0]} ; $j++) {
        for (my $i = $j ; $i <= $#{$groups[0]} ; $i++) {
            if (defined($groups[2][$i])) {
                push @{$map[$j][$j]}, $groups[2][$i];
                $i += 2;
            }
            elsif (defined($groups[1][$i])) {
                push @{$map[$j][$j]}, $groups[1][$i];
                $i += 1;
            }
            else {
                push @{$map[$j][$j]}, $groups[0][$i];
            }
        }
    }

    return \@map;
}

sub int2bytes {
    my ($int) = @_;

    my $data = _make_map($int);

    my @nums;
    foreach my $arr (@{$data}) {
        for my $i (0 .. $#{$arr}) {
            if (ref($arr->[$i]) eq 'ARRAY') {
                my $head = _make_map(substr($int, 0, $i));
                push @nums, [@{$head->[0][0]}, @{$arr->[$i]}];
            }
        }
    }

    my $min = min(map { $#{$_} } @nums);
    my @bytes = do {
        my %seen;
        grep { !$seen{join(' ', @{$_})}++ } grep { $#{$_} == $min } @nums;
    };

    return \@bytes;
}

#
## MAIN
#

my $bigint = shift() // '8379776984727378713267797976';
my $array  = int2bytes($bigint);

foreach my $byte_seq (@{$array}) {
    say "@{$byte_seq}";
    say map { chr } @{$byte_seq};
    print "\n";
}
