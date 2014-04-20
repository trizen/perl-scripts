#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 April 2014
# Website: http://github.com/trizen

# A human-like substring finder
# Steps:
#  1. look at a random position in text and scan back and forward and stop if the string is found somewhere near
#  2. go back to 1, but return -1 if we tried len(text) times without success

use 5.010;
use strict;
use warnings;

sub DEBUG () { 1 }    # verbose mode

sub random_find {
    my ($text, $substr) = @_;

    my $tlen = length($text);
    my $slen = length($substr);

    my $tmax = $tlen - $slen;
    my $smax = int($slen / 1.75);    # this value influences the performance

    my $locate = sub {
        my ($pos, $guess) = @_;

        for my $i (0 .. $smax) {
            if (    $pos + $i <= $tmax
                and substr($guess, $i) eq substr($substr, 0, $slen - $i)
                and substr($text,  $pos + $i,             $slen) eq $substr) {
                printf("RIGHT (%d):\n>  %*s\n>  %s\n", $i, $i + $slen, $substr, $guess) if DEBUG;
                return $pos + $i;
            }
            elsif (    $pos - $i >= 0
                   and substr($substr, $i) eq substr($guess, 0, $slen - $i)
                   and substr($text,   $pos - $i,            $slen) eq $substr) {
                printf("LEFT (%d):\n>  %s\n>  %*s\n", $i, $substr, $i + $slen, $guess) if DEBUG;
                return $pos - $i;
            }
        }

        return;
    };

    ## An inifinite loop might be used here for a 100%-sure match
    for (0 .. $tlen) {

        my $pos = int(rand($tlen));
        if ($pos + $slen <= $tlen) {
            if (defined(my $i = $locate->($pos, substr($text, $pos, $slen)))) {
                say "** FORWARD MATCH!" if DEBUG;
                return $i;
            }
        }

        if ($pos >= $slen) {
            if (defined(my $i = $locate->($pos - $slen, substr($text, $pos - $slen, $slen)))) {
                say "** BACKWARD MATCH!" if DEBUG;
                return $i;
            }
        }
    }

    return -1;
}

my $text = join('', <DATA>);
my $sstr = "by appending one character";

say "POS: ", random_find($text, $sstr);

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
