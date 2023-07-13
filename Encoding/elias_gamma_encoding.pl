#!/usr/bin/perl

# Author: Trizen
# Date: 13 June 2023
# https://github.com/trizen

# Implementation of the Elias gamma encoding scheme.

# Reference:
#   COMP526 7-5 SS7.4 Run length encoding
#   https://youtube.com/watch?v=3jKLjmV1bL8

use 5.036;

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }

    chop($$bitstring);
}

sub elias_encoding ($integers) {

    my $bitstring = '';
    foreach my $k (scalar(@$integers), @$integers) {
        my $t = sprintf('%b', $k + 1);
        $bitstring .= ('1' x (length($t) - 1)) . '0' . substr($t, 1);
    }

    pack('B*', $bitstring);
}

sub elias_decoding ($str) {

    open my $fh, '<:raw', \$str;

    my @ints;
    my $len    = 0;
    my $buffer = '';

    for (my $k = 0 ; $k <= $len ; ++$k) {

        my $bl = 0;
        ++$bl while (read_bit($fh, \$buffer) eq '1');

        push @ints, oct('0b' . '1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl)) - 1;

        if ($k == 0) {
            $len = pop(@ints);
        }
    }

    return \@ints;
}

my @integers = map { int(rand($_)) } 1 .. 1000;
my $str      = elias_encoding([@integers]);

say "Encoded length: ", length($str);
say "Rawdata length: ", length(join(' ', @integers));

my $decoded = elias_decoding($str);

join(' ', @integers) eq join(' ', @$decoded) or die "Decoding error";

__END__
Encoded length: 1777
Rawdata length: 3594
