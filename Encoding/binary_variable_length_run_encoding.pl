#!/usr/bin/perl

# Implementation of the Variable Length Run Encoding, for a binary string consisting of only 0s and 1s.

# Reference:
#   Data Compression (Summer 2023) - Lecture 5 - Basic Techniques
#   https://youtube.com/watch?v=TdFWb8mL5Gk

use 5.036;

sub run_length ($arr) {

    @$arr || return [];

    my @result     = [$arr->[0], 1];
    my $prev_value = $arr->[0];

    foreach my $i (1 .. $#{$arr}) {

        my $curr_value = $arr->[$i];

        if ($curr_value eq $prev_value) {
            ++$result[-1][1];
        }
        else {
            push(@result, [$curr_value, 1]);
        }

        $prev_value = $curr_value;
    }

    return \@result;
}

sub binary_vrl_encoding ($str) {

    my @bits      = split(//, $str);
    my $bitstring = $bits[0];

    foreach my $rle (@{run_length(\@bits)}) {
        my ($c, $v) = @$rle;

        if ($v == 1) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', $v - 1);
            $bitstring .= join('', '1' x length($t), '0', substr($t, 1));
        }
    }

    return $bitstring;
}

sub binary_vrl_decoding ($bitstring) {

    open my $fh, '<:raw', \$bitstring;

    my $decoded = '';
    my $bit     = getc($fh);

    while (!eof($fh)) {

        $decoded .= $bit;

        my $bl = 0;
        while (getc($fh) == 1) {
            ++$bl;
        }

        if ($bl > 0) {
            $decoded .= $bit x oct('0b1' . join('', map { getc($fh) } 1 .. $bl - 1));
        }

        $bit = ($bit eq '1' ? '0' : '1');
    }

    return $decoded;
}

my $bitstring = "101000010000000010000000100000000001001100010000000000000010010100000000000000001";

my $enc = binary_vrl_encoding($bitstring);
my $dec = binary_vrl_decoding($enc);

say $enc;
say $dec;

$dec eq $bitstring or die "error";

__END__
1000110101110110111010011110001010101100011110101010000111101110
101000010000000010000000100000000001001100010000000000000010010100000000000000001
