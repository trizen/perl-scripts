#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 01 May 2015
# Website: http://github.com/trizen

#
## The arithmetic coding algorithm.
#

# See: http://en.wikipedia.org/wiki/Arithmetic_coding#Arithmetic_coding_as_a_generalized_change_of_radix

use 5.010;
use strict;
use warnings;

use bignum try => 'GMP';

sub arithmethic_decoding {
    my ($enc, $freq, $pow) = @_;

    if (defined $pow) {
        $enc *= 10**$pow;
    }

    my $base = 0;
    $base += $_ for values %{$freq};

    my $lim = $base - 1;
    my @range = map { chr } 0 .. 255;

    # Create the cumulative frequency table
    my %cf;
    my $total = 0;
    foreach my $c (@range) {
        if (exists $freq->{$c}) {
            $cf{$c} = $total;
            $total += $freq->{$c};
        }
    }

    # Calculate the probabilities
    my %prob;
    my $uniq = (keys %{$freq});
    while (my ($c, $f) = each %{$freq}) {
        $prob{$c} = (($f - 1) / $uniq) * $lim;
    }

    # Create the dictionary, based on the probabilities
    my %dict;
    my $j = 0;
    for my $i (0 .. $#range) {
        my $char = $range[$i];
        if (exists $prob{$char}) {
            $dict{$j} = $range[$i];
        }
        if (exists $freq->{$char}) {
            $j += $freq->{$char};
        }
    }

    # Fill the gaps in the dictionary
    my $lchar;
    foreach my $i (0 .. $lim) {
        if (exists $dict{$i}) {
            $lchar = $dict{$i};
        }
        elsif (defined $lchar) {
            $dict{$i} = $lchar;
        }
    }

    #~ say "-" x 80;
    #~ use Data::Dump qw(pp);
    #~ pp $freq;
    #~ pp \%prob;
    #~ pp \%dict;
    #~ pp \%cf;
    #~ say "-"x80;

    # Decode the input number
    my $decoded = '';
    foreach my $i (reverse 0 .. $lim) {
        my $div = int($enc / $base**$i);

        my $c  = $dict{$div % $base};
        my $fv = $freq->{$c};
        my $cv = $cf{$c};

        my $rem = int(($enc - $base**$i * $cv) / $fv);

        #~ say "$enc / $base^$i = $div ($c)";
        #~ say "($enc - $base^$i * $cv) / $fv = $rem\n";

        $enc = $rem;
        $decoded .= $c;
    }

    # Return the decoded output
    return $decoded;
}

sub arithmethic_coding {
    my ($str) = @_;
    my @chars = split(//, $str);

    # The dictionary
    my @range = map { chr } 0 .. 255;

    # The frequency characters
    my %freq;
    $freq{$_}++ for @chars;

    # The cumulative frequency
    my %cf;
    my $total = 0;
    foreach my $c (@range) {
        if (exists $freq{$c}) {
            $cf{$c} = $total;
            $total += $freq{$c};
        }
    }

    # Limit and base
    my $lim  = $#chars;
    my $base = $lim + 1;

    # Lower bound
    my $L = 0;

    # Each term is multiplied by the product of the
    # frequencies of all previously occurring symbols
    foreach my $i (0 .. $lim) {
        my $x = $cf{$chars[$i]} * $base**($lim - $i);
        my $y = 1;
        foreach my $k (0 .. $i - 1) {
            $y *= $freq{$chars[$k]};
        }
        $L += $x * $y;
    }

    # Product of all frequencies
    my $pf = 1;
    foreach my $i (0 .. $lim) {
        $pf *= $freq{$chars[$i]};
    }

    # Upper bound
    my $U = $L + $pf;

    #say $L;
    #say $U;

    # Pick the middle point number in the interval
    #return (\%freq, int(($L + $U) / 2));

    # Create a value with the longest possible trail
    # of zeroes, remove them and return its power of 10
    my $pow = int(log($U - $L) / log(10));
    return (int(($U - 1) / (10**$pow)), \%freq, $pow);
}

#
## Run some tests
#
foreach my $str (qw(DABDDB DABDDBBDDBA ABBDDD ABRACADABRA CoMpReSSeD Sidef Trizen Google TOBEORNOTTOBEORTOBEORNOT)) {
    my ($enc, $freq, $pow) = arithmethic_coding($str);
    my $dec = arithmethic_decoding($enc, $freq, $pow);

    say "Encoded:  $enc";
    say "Decoded:  $dec";

    if ($str ne $dec) {
        die "\tHowever that is incorrect!";
    }

    say "-" x 80;
}
