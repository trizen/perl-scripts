#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 May 2016
# Website: https://github.com/trizen

# Generate a random L-System.

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(:overload is_power);
use ntheory qw(is_prime factor);

my @vars = ('F', 'G', 'H');

sub is_triangular {
    my ($x) = @_;
    int(sqrt(8 * $x + 1))**2 == (8 * $x + 1);
}

sub is_square {
    my ($x) = @_;
    int(sqrt($x))**2 == $x;
}

sub divide {
    my ($str, $i) = @_;

    my @parts = ($str);

    for (1 .. @vars - 1) {
        my $rand;

        my $i     = int(rand(@parts));
        my $part  = $parts[$i];
        my $count = 0;

        do {
            $rand = int(rand(length($part)));
            if (++$count > 10) {
                generate();
                return;
            }
          } while (
            do {
                my $s = substr($part, 0, $rand);
                ($s =~ tr/[//) != ($s =~ tr/]//);
            }
          );

        my ($x, $y) = (substr($part, 0, $rand), substr($part, $rand));
        splice(@parts, $i, 1, $x, $y);
    }

    foreach my $part (@parts) {
        if (
            $part eq ''
            or not $part =~ /\w/

            # TODO: check each path (not only the first one)
            or (($parts[0] =~ tr/A-Z//cdsr) =~ /^$vars[0]+\z/o
                and @vars > 1)
          ) {
            $i ||= 0;
            if ($i < 10) {
                return divide($str, $i + 1);
            }
            else {
                generate();
                return;
            }
        }
    }

    return @parts;
}

sub generate {

    my $start     = int(rand(1000)) + 0;
    my $limit     = $start + 10;
    my $deviation = 50;

    my @open;
    my $str = '';

    for (
        my $n = $start ;
        $n <= $limit ? 1 : @open ? do {
            $limit += 1;
            if ($limit - $start > $deviation) { return generate() }
            1;
        }
        : 0 ; $n++
      ) {

        if (is_triangular($n) or is_square($n)) {
            for (1 .. rand(5)) {
                $str .= ('+', '-')[rand(2)];
            }
        }

        if (is_prime($n) or is_power($n)) {
            if (@open and rand(1) < 0.5) {
                $str .= ']';
                pop @open;
            }
            else {
                $str .= '[';
                push @open, 1;
            }
        }

        for (1 .. rand(5)) {
            if (rand(1) < 0.5) {
                $str .= $vars[rand @vars];
            }
        }

        if (rand(1) < 0.5) {
            $str .= ('+', '-')[rand(2)];
        }
    }

    my @parts = divide($str);
    foreach my $i (0 .. $#parts) {
        say "$vars[$i] => \"$parts[$i]\",";
    }
}

generate();
