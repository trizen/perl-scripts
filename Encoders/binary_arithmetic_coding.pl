#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 May 2015
# Website: http://github.com/trizen

#
## The binary arithmetic coding algorithm.
#

# See: http://en.wikipedia.org/wiki/Arithmetic_coding

use 5.010;
use strict;
use warnings;

use Math::BigInt (try => 'GMP');
use Math::BigRat (try => 'GMP');

sub asciibet {
    map { chr } 0 .. 255;
}

sub cumulative_freq {
    my ($freq, $sum) = @_;

    my %cf;
    my $total = 0;
    foreach my $c (asciibet()) {
        if (exists $freq->{$c}) {
            $cf{$c} = $total;
            $total += $freq->{$c};
        }
    }

    return %cf;
}

sub mass_function {
    my ($freq, $sum) = @_;

    my %p;
    $p{$_} = Math::BigRat->new($freq->{$_}) / $sum for keys %{$freq};

    return %p;
}

sub arithmethic_coding {
    my ($str) = @_;
    my @chars = split(//, $str);

    my %freq;
    $freq{$_}++ for @chars;

    my $len = @chars;
    my %p   = mass_function(\%freq, $len);
    my %cf  = cumulative_freq(\%p, $len);

    my $pf = Math::BigRat->new(1);
    my $L  = Math::BigRat->new(0);
    foreach my $c (@chars) {
        $L->badd($pf * $cf{$c});
        $pf->bmul($p{$c});
    }

    my $U = $L + $pf;

    my $big_two = Math::BigInt->new(2);
    my $two_pow = Math::BigInt->new(1);
    my $n       = Math::BigRat->new(0);

    my $bin = '';
    for (my $i = Math::BigInt->new(1) ; ($n < $L || $n >= $U) ; $i->binc) {
        my $m = Math::BigRat->new(1)->bdiv($two_pow->bmul($big_two));

        if ($n + $m < $U) {
            $n += $m;
            $bin .= '1';
        }
        else {
            $bin .= '0';
        }
    }

    return ($bin, $len, \%freq);
}

sub arithmethic_decoding {
    my ($enc, $len, $freq) = @_;

    my $two_pow = Math::BigInt->new(1);
    my $big_two = Math::BigInt->new(2);

    my $line = Math::BigRat->new(0);

    my @bin = split(//, $enc);
    foreach my $i (0 .. $#bin) {
        $line->badd(scalar Math::BigRat->new($bin[$i])->bdiv($two_pow->bmul($big_two)));
    }

    my %p = mass_function($freq, $len);
    my %cf = cumulative_freq(\%p, $len);

    my %df;
    foreach my $k (keys %p) {
        $df{$k} = $cf{$k} + $p{$k};
    }

    my $L = 0;
    my $U = 1;

    my $decoded = '';
    my @chars = sort { $p{$a} <=> $p{$b} or $a cmp $b } keys %p;

    my $i = 0;
    while (1) {
        foreach my $c (@chars) {

            my $w    = $U - $L;
            my $low  = $L + $w * $cf{$c};
            my $high = $L + $w * $df{$c};

            if ($low <= $line and $line < $high) {
                ($L, $U) = ($low, $high);
                $decoded .= $c;
                if (++$i == $len) {
                    return $decoded;
                }
            }
        }
    }
}

#
## Run some tests
#
foreach my $str (
        'this is a message for you to encode and to decode correctly!',
        join('', 'a' .. 'z', 0 .. 9, 'A' .. 'Z', 0 .. 9),
        qw(DABDDB DABDDBBDDBA ABBDDD ABRACADABRA CoMpReSSeD Sidef Trizen google TOBEORNOTTOBEORTOBEORNOT),
        'In a positional numeral system the radix, or base, is numerically equal to a number of different symbols '
        . 'used to express the number. For example, in the decimal system the number of symbols is 10, namely 0, 1, 2, '
        . '3, 4, 5, 6, 7, 8, and 9. The radix is used to express any finite integer in a presumed multiplier in polynomial '
        . 'form. For example, the number 457 is actually 4×102 + 5×101 + 7×100, where base 10 is presumed but not shown explicitly.'
  ) {
    my ($enc, $len, $freq) = arithmethic_coding($str);
    my $dec = arithmethic_decoding($enc, $len, $freq);

    say "Encoded:  $enc";
    say "Decoded:  $dec";

    if ($str ne $dec) {
        die "\tHowever that is incorrect!";
    }

    say "-" x 80;
}
