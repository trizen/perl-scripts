#!/usr/bin/perl

# Author: Trizen
# Date: 13 June 2023
# https://github.com/trizen

# Implementation of the Move-to-Front transform, combined with Delta encoding.

# References:
#   Data Compression (Summer 2023) - Lecture 6 - Delta Compression and Prediction
#   https://youtube.com/watch?v=-3H_eDbWNEU
#
#   COMP526 Unit 7-6 2020-03-24 Compression - Move-to-front transform
#   https://youtube.com/watch?v=Q2pinaj3i9Y

use 5.036;

sub mtf_encode ($bytes, $alphabet = [0 .. 255]) {

    my @C;

    my @table;
    @table[@$alphabet] = (0 .. $#{$alphabet});

    foreach my $c (@$bytes) {
        push @C, (my $index = $table[$c]);
        unshift(@$alphabet, splice(@{$alphabet}, $index, 1));
        @table[@{$alphabet}[0 .. $index]] = (0 .. $index);
    }

    return \@C;
}

sub mtf_decode ($encoded, $alphabet = [0 .. 255]) {

    my @S;

    foreach my $p (@$encoded) {
        push @S, $alphabet->[$p];
        unshift(@$alphabet, splice(@{$alphabet}, $p, 1));
    }

    return \@S;
}

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }

    chop($$bitstring);
}

sub delta_encode ($bytes) {    # all bytes in the range [0, 255]

    my @deltas;
    my $prev = 0;

    my $integers = mtf_encode($bytes);
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
            $bitstring .= ('1' . (($d < 0) ? '0' : '1') . ('1' x (length($t) - 1)) . '0' . substr($t, 1));
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

    mtf_decode(\@acc);
}

my @bytes = do {
    open my $fh, '<:raw', $^X;
    local $/;
    unpack('C*', <$fh>);
};

my $str = delta_encode([@bytes]);

say "Encoded length: ", length($str);
say "Rawdata length: ", length(pack('C*', @bytes));

my $decoded = delta_decode($str);
join(' ', @bytes) eq join(' ', @$decoded) or die "Decoding error";

__END__
Encoded length: 5270
Rawdata length: 14168
