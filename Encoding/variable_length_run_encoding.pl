#!/usr/bin/perl

# Implementation of the Variable Length Run Encoding.

# Reference:
#   Data Compression (Summer 2023) - Lecture 5 - Basic Techniques
#   https://youtube.com/watch?v=TdFWb8mL5Gk

use 5.036;

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }

    chop($$bitstring);
}

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

sub VLR_encoding ($bytes) {

    my $bitstream = '';
    my $rle       = run_length($bytes);

    foreach my $cv (@$rle) {
        my ($c, $v) = @$cv;
        $bitstream .= sprintf('%08b', $c);
        if ($v == 1) {
            $bitstream .= '0';
        }
        else {
            my $t = sprintf('%b', $v);
            $bitstream .= join('', '1' x (length($t) - 1), '0', substr($t, 1));
        }
    }

    pack('B*', $bitstream);
}

sub VLR_decoding ($bitstring) {

    my $decoded = '';
    my $buffer  = '';

    open my $bits_fh, '<:raw', \$bitstring;

    while (!eof($bits_fh)) {

        my $s = join('', map { read_bit($bits_fh, \$buffer) } 1 .. 8);
        my $c = pack('B*', $s);

        my $bl = 0;
        while (read_bit($bits_fh, \$buffer) == 1) {
            ++$bl;
        }

        $decoded .= $c;

        if ($bl > 0) {
            $decoded .= $c x (oct('0b1' . join('', map { read_bit($bits_fh, \$buffer) } 1 .. $bl)) - 1);
        }
    }

    $decoded;
}

my $str   = join('', 'a' x 13, 'b' x 14, 'c' x 10, 'd' x 3, 'e' x 1, 'f' x 1, 'g' x 4);
my @bytes = unpack('C*', $str);

my $enc = VLR_encoding(\@bytes);
my $dec = VLR_decoding($enc);

say unpack('B*', $enc);
say $dec;

$dec eq $str or die "error: $dec != $str";
