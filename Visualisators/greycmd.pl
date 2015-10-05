#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 05 October 2015
# Website: https://github.com/trizen

# Colorize the output of a given command in nuances of grey.

# Example: perl greycmd.pl ls -l

use 5.010;
use strict;
use warnings;

use Encode qw(decode_utf8);
use Text::Tabs qw(expand);
use List::Util qw(shuffle max);
use Term::ANSIColor qw(colored colorstrip);

@ARGV || die "usage: $0 [cmd]\n";

my $text = expand(colorstrip(decode_utf8(scalar(`@{[map{quotemeta}@ARGV]}`) // exit 2)));

my @lines = split(/\R/, $text);

@lines || exit;    # no output -- exit

my @colors = (map { "grey$_" } 0 .. 23);

my $max = max(map { length($_) } @lines);
my @chars = map { split //, sprintf("%-*s", $max, $_) } @lines;

my $r = 1 + int($max / @colors);

my $j = 0;
my $k = 0;

foreach my $i (0 .. $#chars) {

    if ($i % $max == 0) {
        $j = 0;
    }

    if ($k++ % $r == 0) {
        ++$j;
    }

    $chars[$i] eq ' ' and next;             # ignore spaces
    $chars[$i] =~ /[[:print:]]/ or next;    # ignore non-printable characters

    $chars[$i] = colored($chars[$i], $colors[$j % @colors]);
}

binmode(STDOUT, ':utf8');

my $str = '';
foreach my $i (0 .. $#chars) {
    $str .= $chars[$i];
    if (($i + 1) % $max == 0) {
        $str = unpack('A*', $str) . "\n";
    }
}
print $str;
