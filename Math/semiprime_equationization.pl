#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 July 2015
# Website: https://github.com/trizen

# Split a semiprime into a group of equations.

use 5.016;
use strict;
use integer;
use warnings;

sub semiprime_equationization {
    my ($semiprime, $xlen, $ylen) = @_;

    $xlen -= 1;
    $ylen -= 1;

    my @map;
    my $mem = '0';
    my @result;

    my %vars;
    foreach my $j (0 .. $ylen) {
        foreach my $i (0 .. $xlen) {
            my $expr = '(' . join(' + ', "(x[$i] * y[$j])", grep { $_ ne '0' } $mem) . ')';

            $vars{"xy$i$j"} = $expr;
            my $n = "xy$i$j";

            if ($i == $xlen) {
                push @{$map[$j]}, "($n % 10)", "int($n / 10)";
                $mem = '0';
            }
            else {
                push @{$map[$j]}, "($n % 10)";
                $mem = "int($n / 10)";
            }
        }

        my $n = $ylen - $j;
        if ($n > 0) {
            push @{$map[$j]}, ((0) x $n);
        }

        my $m = $ylen - $n;
        if ($m > 0) {
            unshift @{$map[$j]}, ((0) x $m);
        }
    }

    my @number = reverse split //, $semiprime;
    my @mrange = (0 .. $#map);

    my %seen;
    my $initializer = sub {
        my ($str) = @_;
        while ($str =~ /\b(xy\d+)/g) {
            if (not $seen{$1}++) {
                my $init = "$1 = $vars{$1}";
                __SUB__->($init);
                push @result, $init;
            }
        }
    };

    foreach my $i (0 .. $#number) {
        my $expr = '(' . join(' + ', grep { $_ ne '0' } (map { $map[$_][$i] } @mrange), $mem) . ')';
        $initializer->($expr);

        push @result, "n$i = $expr";
        my $n = "n$i";

        if ($i == 0 or $i == $#number) {
            push @result, "$number[$i] = $n";
            $mem = '0';
        }
        else {
            push @result, "$number[$i] = ($n % 10)";
            $mem = "int($n / 10)";
        }
    }

    return @result;
}

# 71 * 43
#say for semiprime_equationization('3053', 2, 2);

# 251 * 197
say for semiprime_equationization('49447', 3, 3);

# 37975227936943673922808872755445627854565536638199 * 40094690950920881030683735292761468389214899724061
#say for semiprime_equationization('1522605027922533360535618378132637429718068114961380688657908494580122963258952897654000350692006139', 50, 50);
