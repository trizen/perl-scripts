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

use Math::BigInt (try => 'GMP');

sub arithmethic_decoding {
    my ($enc, $freq, $pow) = @_;

    if (defined $pow) {
        $enc *= 10**$pow;
    }

    my $base = Math::BigInt->new(0);
    $base += $_ for values %{$freq};

    my $lim = $base - 1;
    my @range = map { chr } 0 .. 255;

    # Create the cumulative frequency table
    my %cf;
    my $total = Math::BigInt->new(0);
    foreach my $c (@range) {
        if (exists $freq->{$c}) {
            $cf{$c} = $total;
            $total += $freq->{$c};
        }
    }

    # Calculate the probabilities
    # my %prob;
    # my $uniq = (keys %{$freq});
    # while (my ($c, $f) = each %{$freq}) {
    #     $prob{$c} = (($f - 1) / $uniq) * $lim;
    # }

    # Create the dictionary
    my %dict;
    my $j = 0;
    for my $i (0 .. $#range) {
        my $char = $range[$i];
        if (exists $freq->{$char}) {
            $dict{$j} = $range[$i];
            $j += $freq->{$char};
        }
    }

    # Fill the gaps in the dictionary
    my $lchar;
    foreach my $i (0 .. $base) {
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
    for (my $i = $lim ; $i >= 0 ; $i--) {
        my $div = ($enc / $base**$i);

        my $c  = $dict{$div};
        my $fv = $freq->{$c};
        my $cv = $cf{$c};

        my $rem = ($enc - $base**$i * $cv) / $fv;

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
    my $total = Math::BigInt->new(0);
    foreach my $c (@range) {
        if (exists $freq{$c}) {
            $cf{$c} = $total;
            $total += $freq{$c};
        }
    }

    # Limit and base
    my $lim  = Math::BigInt->new($#chars);
    my $base = $lim + 1;

    # Lower bound
    my $L = Math::BigInt->new(0);

    # Product of all frequencies
    my $pf = Math::BigInt->new(1);

    # Each term is multiplied by the product of the
    # frequencies of all previously occurring symbols
    for (my $i = 0 ; $i < $base ; $i++) {
        my $x = $cf{$chars[$i]} * $base**($lim - $i);
        $L->badd($x * $pf);
        $pf->bmul($freq{$chars[$i]});
    }

    # Upper bound
    my $U = $L + $pf;

    #~ say $L;
    #~ say $U;

    # Pick the middle point number in the interval
    #~ return (\%freq, int(($L + $U) / 2));

    # Create a value with the longest possible trail
    # of zeroes, remove them and return its power of 10
    #~ my $pow = int(log($U - $L) / log(10));
    #~ return (int(($U - 1) / (10**$pow)), \%freq, $pow);

    my $pow = Math::BigInt->new($U - $L)->blog(10);
    my $enc = ($U - 1)->bdiv(Math::BigInt->new(10)->bpow($pow));

    return ($enc, \%freq, $pow);
}

#
## Run some tests
#
foreach my $str (
    qw(DABDDB DABDDBBDDBA ABBDDD ABRACADABRA CoMpReSSeD Sidef Trizen Google TOBEORNOTTOBEORTOBEORNOT),
    'In a positional numeral system the radix, or base, is numerically equal to a number of different symbols '
    . 'used to express the number. For example, in the decimal system the number of symbols is 10, namely 0, 1, 2, '
    . '3, 4, 5, 6, 7, 8, and 9. The radix is used to express any finite integer in a presumed multiplier in polynomial '
    . 'form. For example, the number 457 is actually 4×102 + 5×101 + 7×100, where base 10 is presumed but not shown explicitly.'
  ) {
    my ($enc, $freq, $pow) = arithmethic_coding($str);
    my $dec = arithmethic_decoding($enc, $freq, $pow);

    say "Encoded:  $enc";
    say "Decoded:  $dec";

    if ($str ne $dec) {
        die "\tHowever that is incorrect!";
    }

    say "-" x 80;
}
