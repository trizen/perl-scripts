#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 01 May 2015
# https://github.com/trizen

# The arithmetic coding algorithm, as_a_generalized_change_of_radix.

# See also:
#   https://en.wikipedia.org/wiki/Arithmetic_coding#Arithmetic_coding_as_a_generalized_change_of_radix

use 5.010;
use strict;
use warnings;

use Math::AnyNum qw(ipow ilog idiv);

sub asciibet {
    map { chr } 0 .. 255;
}

sub cumulative_freq {
    my ($freq) = @_;

    my %cf;
    my $total = Math::AnyNum->new(0);
    foreach my $c (asciibet()) {
        if (exists $freq->{$c}) {
            $cf{$c} = $total;
            $total += $freq->{$c};
        }
    }

    return %cf;
}

sub arithmethic_coding {
    my ($str, $radix) = @_;
    my @chars = split(//, $str);

    # The frequency characters
    my %freq;
    $freq{$_}++ for @chars;

    # The cumulative frequency table
    my %cf = cumulative_freq(\%freq);

    # Base
    my $base = Math::AnyNum->new(scalar @chars);

    # Lower bound
    my $L = Math::AnyNum->new(0);

    # Product of all frequencies
    my $pf = Math::AnyNum->new(1);

    # Each term is multiplied by the product of the
    # frequencies of all previously occurring symbols
    foreach my $c (@chars) {
        $L  *= $base;
        $L  += $cf{$c} * $pf;
        $pf *= $freq{$c};
    }

    # Upper bound
    my $U = $L + $pf;

    #~ say $L;
    #~ say $U;

    my $pow = ilog($pf, $radix);
    my $enc = idiv($U - 1, ipow($radix, $pow));

    return ($enc, $pow, \%freq);
}

sub arithmethic_decoding {
    my ($enc, $radix, $pow, $freq) = @_;

    # Multiply enc by 10^pow
    $enc *= ipow($radix, $pow);

    my $base = Math::AnyNum->new(0);
    $base += $_ for values %{$freq};

    # Create the cumulative frequency table
    my %cf = cumulative_freq($freq);

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
    for (my $pow = ipow($base, $base - 1) ; $pow > 0 ; $pow = idiv($pow, $base)) {
        my $div = idiv($enc, $pow);

        my $c  = $dict{$div};
        my $fv = $freq->{$c};
        my $cv = $cf{$c};

        my $rem = idiv($enc - $pow * $cv, $fv);

        #~ say "$enc / $base^$pow = $div ($c)";
        #~ say "($enc - $base^$pow * $cv) / $fv = $rem\n";

        $enc = $rem;
        $decoded .= $c;
    }

    # Return the decoded output
    return $decoded;
}

#
## Run some tests
#

my $radix = 10;    # can be any integer >= 2

foreach my $str (
                 qw(DABDDB DABDDBBDDBA ABBDDD ABRACADABRA CoMpReSSeD Sidef Trizen google TOBEORNOTTOBEORTOBEORNOT 吹吹打打),
                 'In a positional numeral system the radix, or base, is numerically equal to a number of different symbols '
                 . 'used to express the number. For example, in the decimal system the number of symbols is 10, namely 0, 1, 2, '
                 . '3, 4, 5, 6, 7, 8, and 9. The radix is used to express any finite integer in a presumed multiplier in polynomial '
                 . 'form. For example, the number 457 is actually 4×102 + 5×101 + 7×100, where base 10 is presumed but not shown explicitly.'
  ) {
    my ($enc, $pow, $freq) = arithmethic_coding($str, $radix);
    my $dec = arithmethic_decoding($enc, $radix, $pow, $freq);

    say "Encoded:  $enc";
    say "Decoded:  $dec";

    if ($str ne $dec) {
        die "\tHowever that is incorrect!";
    }

    say "-" x 80;
}

open my $fh, '<', __FILE__;
my $content = do { local $/; <$fh> };

my ($enc, $pow, $freq) = arithmethic_coding($content, $radix);
my $dec = arithmethic_decoding($enc, $radix, $pow, $freq);

if ($dec ne $content) {
    die "Failed to encode and decode the __FILE__ correctly.";
}
