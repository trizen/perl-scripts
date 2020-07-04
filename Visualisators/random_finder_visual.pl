#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 April 2015
# Website: http://github.com/trizen

#
## A recursive-random text finder with potential support for parallelization
#

# It tries to find a substring inside a given text, starting at random positions, by
# splitting (recursively) the text into halves, stopping when the window is too narrow.
# If the substring exists inside the text, it returns "true". "false" otherwise.

# This is the visual version of the algorithm.

use 5.016;
use strict;
use warnings;

use List::Util qw(shuffle);
use Term::ANSIColor qw(colored);

sub rec_find {
    my ($text, $substr) = @_;

    my $limit = length($substr);

    my $find = sub {
        my ($min, $max) = @_;

        my $middle = int(($max + $min) / 2);
        my $pos_l  = int(($middle + $min) / 2);
        my $pos_r  = int(($middle + $max) / 2);

        if (($middle - $pos_l) > $limit * 2) {
#<<<
            __SUB__->(@{$_}) for shuffle(
                [$pos_l, $middle],
                [$pos_r,    $max],
                [$min,    $pos_l],
                [$middle, $pos_r],
            );
#>>>
        }
        else {
            my $t = $text;
            substr($t, $min, $max - $min,
                colored(substr($t, $min, $max - $min), 'bold red'));
            system 'clear';
            print $t;
            sleep 1;
        }
    };

    my $min = 0;
    my $max = length($text);
    $find->($min, $max);
}

my $text = do { local $/; <DATA> };
rec_find($text, 'following blue');

__END__
The data structure has one node for every prefix of every
string in the dictionary. So if (bca) is in the dictionar
then there will be nodes for (bca), (bc), (b), and (). If
is in the dictionary then it is blue node. Otherwise it i
There is a black directed "child" arc from each node to a
is found by appending one character. So there is a black
There is a blue directed "suffix" arc from each node to t
possible strict suffix of it in the graph. For example, f
are (aa) and (a) and (). The longest of these that exists
graph is (a). So there is a blue arc from (caa) to (a). T
a green "dictionary suffix" arc from each node to the nex
in the dictionary that can be reached by following blue a
example, there is a green arc from (bca) to (a) because (
node in the dictionary (i.e. a blue node) that is reached
the blue arcs to (ca) and then on to (a).
