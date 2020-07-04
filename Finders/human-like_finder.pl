#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 April 2014
# Website: http://github.com/trizen

# A smart human-like substring finder
# Steps:
#  1. loop from i=1 and count up to int(sqrt(len(text)))
#  2. loop from pos=(i-1)*len(substr)*2 and add int(len(text)/i) to pos while pos <= len(text)
#  3. jump to position pos and scan back and forward and stop if the string is found somewhere nearby
#  4. loop #2 end
#  5. loop #1 end
#  6. return -1

use 5.010;
use strict;
use warnings;

my $TOTAL = 0;    # count performance
sub DEBUG () { 1 }    # verbose mode

sub random_find {
    my ($text, $substr) = @_;

    my $tlen = length($text);
    my $slen = length($substr);

    my $tmax = $tlen - $slen;
    my $smax = int($slen / 2);    # this value influences the performance

    my $counter = 0;
    my $locate  = sub {
        my ($pos, $guess) = @_;

        for my $i (0 .. $smax) {

            ++$counter if DEBUG;    # measure performance

            if (    $pos + $i <= $tmax
                and substr($guess, $i) eq substr($substr, 0, $slen - $i)
                and substr($text,  $pos + $i,             $slen) eq $substr) {
                printf("RIGHT (i: %d; counter: %d):\n>  %*s\n>  %s\n", $i, $counter, $i + $slen, $substr, $guess) if DEBUG;
                $TOTAL += $counter if DEBUG;
                return $pos + $i;
            }
            elsif (    $pos - $i >= 0
                   and substr($substr, $i) eq substr($guess, 0, $slen - $i)
                   and substr($text,   $pos - $i,            $slen) eq $substr) {
                printf("LEFT (i: %d; counter: %d):\n>  %s\n>  %*s\n", $i, $counter, $substr, $i + $slen, $guess) if DEBUG;
                $TOTAL += $counter if DEBUG;
                return $pos - $i;
            }
        }

        return;
    };

    foreach my $i (1 .. int(sqrt($tlen))) {
        my $delta = int($tlen / $i);

        for (my $pos = ($i - 1) * $slen * 2 ; $pos <= $tlen ; $pos += $delta) {

            say "POS: $pos" if DEBUG;
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
    }

    return -1;
}

my $text = join('', <DATA>);
my $split = 30;

foreach my $str (unpack("(A$split)*", $text)) {
    if (random_find($text, $str) == -1) {
        die "Error!";
    }
    say '-' x 80 if DEBUG;
}

say "TOTAL: ", $TOTAL if DEBUG;

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
