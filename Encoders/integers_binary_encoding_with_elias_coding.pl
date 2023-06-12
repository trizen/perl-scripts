#!/usr/bin/perl

# Author: Trizen
# Date: 23 March 2023
# Edit: 12 June 2023
# https://github.com/trizen

# Encode and decode a random list of integers into a binary string + Elias encoding.

use 5.036;

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }

    chop($$bitstring);
}

sub read_bits ($fh, $bits_len) {

    my $data = '';
    read($fh, $data, $bits_len >> 3);
    $data = unpack('B*', $data);

    while (length($data) < $bits_len) {
        $data .= unpack('B*', getc($fh) // return undef);
    }

    if (length($data) > $bits_len) {
        $data = substr($data, 0, $bits_len);
    }

    return $data;
}

sub elias_encoding ($integers) {    # all ints >= 1

    my $bitstring = '';
    foreach my $k (scalar(@$integers), @$integers) {
        if ($k == 1) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', $k - 1);
            $bitstring .= ('1' x length($t)) . '0' . substr($t, 1);
        }
    }

    pack('B*', $bitstring);
}

sub elias_decoding ($fh) {

    my @ints;
    my $len = 0;
    my $buffer;

    for (my $k = 0 ; $k <= $len ; ++$k) {

        my $bit_len = 0;
        while (read_bit($fh, \$buffer) eq '1') {
            ++$bit_len;
        }

        if ($bit_len > 0) {
            push @ints, 1 + oct('0b' . '1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bit_len - 1)));
        }
        else {
            push @ints, 1;
        }

        if ($k == 0) {
            $len = pop(@ints);
        }
    }

    return \@ints;
}

sub encode_integers ($integers) {

    my @counts;
    my $count           = 0;
    my $bits_width      = 1;
    my $bits_max_symbol = 1 << $bits_width;
    my $processed_len   = 0;

    foreach my $k (@$integers) {
        while ($k >= $bits_max_symbol) {

            if ($count > 0) {
                push @counts, [$bits_width, $count];
                $processed_len += $count;
            }

            $count = 0;
            $bits_max_symbol *= 2;
            $bits_width      += 1;
        }
        ++$count;
    }

    push @counts, grep { $_->[1] > 0 } [$bits_width, scalar(@$integers) - $processed_len];

    my $compressed = elias_encoding([map { @$_ } @counts]);

    my $bits = '';
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        foreach my $symbol (splice(@$integers, 0, $len)) {
            $bits .= sprintf("%0*b", $blen, $symbol);
        }
    }

    $compressed .= pack('B*', $bits);
    return $compressed;
}

sub decode_integers ($str) {

    open my $fh, '<:raw', \$str;

    my $ints = elias_decoding($fh);

    my @counts;
    my $bits_len = 0;

    while (@$ints) {
        my ($blen, $len) = splice(@$ints, 0, 2);
        push @counts, [$blen, $len];
        $bits_len += $blen * $len;
    }

    my $bits = read_bits($fh, $bits_len);

    my @chunks;
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        foreach my $chunk (unpack(sprintf('(a%d)*', $blen), substr($bits, 0, $blen * $len, ''))) {
            push @chunks, oct('0b' . $chunk);
        }
    }

    return \@chunks;
}

my @integers = map { int(rand($_)) } 1 .. 1000;
my $str      = encode_integers([@integers]);

say "Encoded length: ", length($str);
say "Rawdata length: ", length(join(' ', @integers));

my $decoded = decode_integers($str);

join(' ', @integers) eq join(' ', @$decoded) or die "Decoding error";

__END__
Encoded length: 1123
Rawdata length: 3606
