#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 May 2015
# Website: http://github.com/trizen

#
## The arithmetic coding algorithm.
#

# See: http://en.wikipedia.org/wiki/Arithmetic_coding#Arithmetic_coding_as_a_generalized_change_of_radix

use 5.010;
use strict;
use warnings;

use Math::BigInt (try => 'GMP');
use Math::BigFloat (try => 'GMP');

sub mass_function {    # for later use
    my ($freq, $total) = @_;

    my %mass;
    $mass{$_} = $freq->{$_} / $total for keys %{$freq};

    return \%mass;
}

sub asciibet {
    map { chr } 0 .. 255;
}

sub cumulative_freq {
    my ($freq) = @_;

    my %cf;
    my $total = Math::BigInt->new(0);
    foreach my $c (asciibet()) {
        if (exists $freq->{$c}) {
            $cf{$c} = $total;
            $total += $freq->{$c};
        }
    }

    return %cf;
}

sub arithmethic_coding {
    my ($str) = @_;
    my @chars = split(//, $str);

    # The frequency characters
    my %freq;
    $freq{$_}++ for @chars;

    # The cumulative frequency table
    my %cf = cumulative_freq(\%freq);

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

    my $pow = Math::BigInt->new($pf)->blog(10);
    my $enc = ($U - 1)->bdiv(Math::BigInt->new(10)->bpow($pow));

    my $a = Math::BigFloat->new("0.$L");
    my $b = Math::BigFloat->new("0.$U");

    my $n   = 0;
    my $bin = '';
    for (my $i = Math::BigFloat->new(1) ; ; $i++) {
        my $m = Math::BigFloat->new(1) / (2**$i);

        if ($n + $m < $b) {
            $n += $m;
            $bin .= '1';
        }
        else {
            $bin .= '0';
        }

        if ($n >= $a && $n < $b) {
            last;
        }
    }

    #~ say $L;
    #~ say $U;

    return ($bin, scalar($L->length), \%freq);
}

sub arithmethic_decoding {
    my ($enc, $pow, $freq) = @_;

    my $big_two = Math::BigInt->new(2);
    my $float   = Math::BigFloat->new(0);

    my @bin = split(//, $enc);
    foreach my $i (0 .. $#bin) {
        $float->badd(Math::BigFloat->new($bin[$i]) / ($big_two->copy->bpow($i + 1)));
    }

    $enc = $float->bmul(Math::BigInt->new(10)->bpow($pow))->as_int;

    my $base = Math::BigInt->new(0);
    $base += $_ for values %{$freq};

    # Create the cumulative frequency table
    my %cf = cumulative_freq($freq);

    # Calculate the probabilities
    # my %prob;
    # my $uniq = (keys %{$freq});
    # while (my ($c, $f) = each %{$freq}) {
    #     $prob{$c} = (($f - 1) / $uniq) * ($base-1);
    # }

    # Create the dictionary
    my %dict;
    while (my ($k, $v) = each %cf) {
        $dict{$v} = $k;
    }

    # Fill the gaps in the dictionary
    my $lchar;
    foreach my $i (0 .. $base - 1) {
        if (exists $dict{$i}) {
            $lchar = $dict{$i};
        }
        elsif (defined $lchar) {
            $dict{$i} = $lchar;
        }
    }

    # Decode the input number
    my $decoded = '';
    for (my $i = $base - 1 ; $i >= 0 ; $i--) {

        my $pow = $base**$i;
        my $div = ($enc / $pow);

        my $c  = $dict{$div};
        my $fv = $freq->{$c};
        my $cv = $cf{$c};

        my $rem = ($enc - $pow * $cv) / $fv;

        #~ say "$enc / $base^$i = $div ($c)";
        #~ say "($enc - $base^$i * $cv) / $fv = $rem\n";

        $enc = $rem;
        $decoded .= $c;
    }

    # Return the decoded output
    return $decoded;
}

#
## Run some tests
#
foreach my $str (
    qw(DABDDB DABDDBBDDBA ABBDDD ABRACADABRA CoMpReSSeD Sidef Trizen google TOBEORNOTTOBEORTOBEORNOT),
    'In a positional numeral system the radix, or base, is numerically equal to a number of different symbols '
    . 'used to express the number. For example, in the decimal system the number of symbols is 10, namely 0, 1, 2, '
    . '3, 4, 5, 6, 7, 8, and 9. The radix is used to express any finite integer in a presumed multiplier in polynomial '
    . 'form. For example, the number 457 is actually 4×102 + 5×101 + 7×100, where base 10 is presumed but not shown explicitly.'
  ) {
    my ($enc, $pow, $freq) = arithmethic_coding($str);
    my $dec = arithmethic_decoding($enc, $pow, $freq);

    say "Encoded:  $enc";
    say "Decoded:  $dec";

    if ($str ne $dec) {
        die "\tHowever that is incorrect!";
    }

    say "-" x 80;
}
