#!/usr/bin/perl

# Author: Trizen
# Date: 13 June 2023
# https://github.com/trizen

# Implementation of the Delta encoding scheme, using unary coding.

# Reference:
#   Data Compression (Summer 2023) - Lecture 6 - Delta Compression and Prediction
#   https://youtube.com/watch?v=-3H_eDbWNEU

use 5.036;

sub delta_encode ($bytes) {

    my @deltas;
    my $prev = 0;

    while (@$bytes) {
        my $curr = shift(@$bytes);
        push @deltas, $curr - $prev;
        $prev = $curr;
    }

    my $bitstring = '';

    foreach my $d (@deltas) {
        if ($d == 0) {
            $bitstring .= '0';
        }
        else {
            $bitstring .= '1' . (($d < 0) ? '0' : '1') . ('1' x (abs($d) - 1)) . '0';
        }
    }

    return $bitstring;
}

sub delta_decode ($bitstring) {

    my @bits = split(//, $bitstring);
    my @deltas;

    while (@bits) {
        my $bit = shift(@bits);
        if ($bit eq '0') {
            push @deltas, 0;
        }
        else {
            my $bit = shift(@bits);
            my $n   = 1;
            ++$n while (shift(@bits) eq '1');
            push @deltas, ($bit eq '1' ? $n : -$n);
        }
    }

    my @acc;
    my $prev = 0;

    foreach my $d (@deltas) {
        $prev += $d;
        push @acc, $prev;
    }

    return \@acc;
}

my $str = "TOBEORNOTTOBEORTOBEORNOT";

my $encoded = delta_encode([unpack('C*', $str)]);
my $decoded = delta_decode($encoded);

say "Encoded: ", "$encoded";
say "Decoded: ", pack('C*', @$decoded);

$str eq pack('C*', @$decoded) or die "error";

{
    open my $fh, '<:raw', __FILE__;
    my $str     = do { local $/; <$fh> };
    my $encoded = delta_encode([unpack('C*', $str)]);
    my $decoded = delta_decode($encoded);
    $str eq pack('C*', @$decoded) or die "error";
}

__END__
Encoded: 111111111111111111111111111111111111111111111111111111111111111111111111111111111111101011110101111111111110111101111111111101111010111011011111100101111010111111111111011110111111111110111101110101111010111111111111011110111111111110111101011101101111110
Decoded: TOBEORNOTTOBEORTOBEORNOT
