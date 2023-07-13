#!/usr/bin/perl

# Author: Trizen
# Date: 14 June 2023
# https://github.com/trizen

# Implementation of the Delta encoding scheme, combined with Elias gamma encoding, optimized for moderately large deltas.

# Reference:
#   Data Compression (Summer 2023) - Lecture 6 - Delta Compression and Prediction
#   https://youtube.com/watch?v=-3H_eDbWNEU

use 5.036;

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }

    chop($$bitstring);
}

sub delta_encode ($integers) {

    my @deltas;
    my $prev = 0;

    unshift(@$integers, scalar(@$integers));

    while (@$integers) {
        my $curr = shift(@$integers);
        push @deltas, $curr - $prev;
        $prev = $curr;
    }

    my $bitstring = '';

    foreach my $d (@deltas) {
        if ($d == 0) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', abs($d));
            $bitstring .= '1' . (($d < 0) ? '0' : '1') . ('1' x (length($t) - 1)) . '0' . substr($t, 1);
        }
    }

    pack('B*', $bitstring);
}

sub delta_decode ($str) {

    open my $fh, '<:raw', \$str;

    my @deltas;
    my $buffer = '';
    my $len    = 0;

    for (my $k = 0 ; $k <= $len ; ++$k) {
        my $bit = read_bit($fh, \$buffer);

        if ($bit eq '0') {
            push @deltas, 0;
        }
        else {
            my $bit = read_bit($fh, \$buffer);
            my $n   = 0;
            ++$n while (read_bit($fh, \$buffer) eq '1');
            my $d = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $n));
            push @deltas, ($bit eq '1' ? $d : -$d);
        }

        if ($k == 0) {
            $len = pop(@deltas);
        }
    }

    my @acc;
    my $prev = $len;

    foreach my $d (@deltas) {
        $prev += $d;
        push @acc, $prev;
    }

    return \@acc;
}

my @integers = map { int(rand($_)) } 1 .. 1000;
my $str      = delta_encode([@integers]);

say "Encoded length: ", length($str);
say "Rawdata length: ", length(join(' ', @integers));

my $decoded = delta_decode($str);

join(' ', @integers) eq join(' ', @$decoded) or die "Decoding error";

{
    open my $fh, '<:raw', __FILE__;
    my $str     = do { local $/; <$fh> };
    my $encoded = delta_encode([unpack('C*', $str)]);
    my $decoded = delta_decode($encoded);
    $str eq pack('C*', @$decoded) or die "error";
}

__END__
Encoded length: 1882
Rawdata length: 3626
