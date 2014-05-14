#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15th October 2013
# http://trizenx.blogspot.com
# Email: <echo dHJpemVueEBnbWFpbC5jb20K | base64 -d>

# Smart word wrap algorithm
# See: http://en.wikipedia.org/wiki/Word_wrap#Minimum_raggedness

use 5.016;
use strict;
use warnings;

our $WIDTH = 6;    # this value can be changed

###########################################################################
######################## BEGINING OF THE ALGORITHM ########################
###########################################################################

## This is the ugliest function! It, recursively,
## prepares the words for the make_paths() function.
sub prepare_words {
    my @array = @_;

    my @root;
    my $len = 0;

    for (my $i = 0 ; $i <= $#array ; $i++) {
        $len += (my $wordLen = length($array[$i]));

        if ($len > $WIDTH) {
            if ($wordLen > $WIDTH) {
                $len -= $wordLen;
                splice(@array, $i, 1, unpack "(A$WIDTH)*", $array[$i]);
                $i--, next;
            }
            last;
        }

        ## A performance improvement (fast, but buggy!)
        #next if $len < int($WIDTH/3);

        push @root, [@array[0 .. $i], __SUB__->(@array[$i + 1 .. $#{array}])];
        last if ++$len >= $WIDTH;
    }

    @root ? @root : @array ? \@array : ();
}

## This function creates all the
## avaible paths, for further processing.
sub make_paths {
    my (@array) = @_;

    my @head;
    while (@array) {
        last if ref($array[0]) eq 'ARRAY';
        push @head, shift @array;
    }

    my @row;
    foreach my $path (@array) {
        push @row, {"@head" => __SUB__->(@{$path})};
    }

    @row ? \@row : "@head";
}

## This function combines the
## the parents with the childrens.
sub combine {
    my ($root, $hash) = @_;

    my @row;
    while (my ($key, $value) = each %{$hash}) {
        push $root, $key;

        if (ref $value eq 'ARRAY') {
            foreach my $item (@{$value}) {
                push @row, __SUB__->($root, $item);
            }
        }
        else {
            push @row, @{$root}, $value;
        }

        pop $root;
    }

    \@row;
}

## This function normalizez the combinations.
## Example: [[["abc"]]] is normalized to ["abc"];
sub normalize {
    my ($array_ref) = @_;

    my @strings;
    foreach my $item (@{$array_ref}) {

        if (ref $item eq 'ARRAY') {
            push @strings, normalize($item);
        }
        else {
            push @strings, $array_ref;
            last;
        }
    }

    @strings;
}

## This function finds the best
## combination avaiable and returns it.
sub find_best {
    my (@arrays) = @_;

    my %best = (score => 'inf');

    foreach my $array_ref (@arrays) {

        my $score = 0;
        foreach my $string (@{$array_ref}) {
            $score += ($WIDTH - length($string))**2;
        }

        if ($score < $best{score}) {
            $best{score} = $score;
            $best{value} = $array_ref;
        }
    }

    exists($best{value}) ? @{$best{value}} : ();
}

## This is the main function of the algorithm
## which calls all the other functions and
## returns the best possible wrapped string.
sub smart_wrap {
    my ($text) = @_;

    my @words =
      ref($text) eq 'ARRAY'
      ? @{$text}
      : split(' ', $text);

    my @paths;
    foreach my $group (prepare_words(@words)) {
        push @paths, make_paths(@{$group});
    }

    my @combinations;
    while (@paths) {

        if (ref($paths[0]) eq 'ARRAY') {
            push @paths, @{shift @paths};
            next;
        }

        my $path = shift @paths;
        push @combinations, ref($path) eq 'HASH' ? [combine([], $path)] : [$path];
    }

    join("\n", find_best(normalize(\@combinations)));
}

##########################################################################
########################## END OF THE ALGORITHM ##########################
##########################################################################

#
## Usage example
#

my $text = 'aaa bb cc ddddd';

say "=>>> SMART WRAP:";
say smart_wrap($text);

say "\n=>>> GREEDY WRAP (Text::Wrap):";
require Text::Wrap;
$Text::Wrap::columns = $WIDTH;
$Text::Wrap::columns += 1;
say Text::Wrap::wrap('', '', $text);
