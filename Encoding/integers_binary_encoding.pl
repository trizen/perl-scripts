#!/usr/bin/perl

# Author: Trizen
# Date: 23 March 2023
# https://github.com/trizen

# Encode and decode a random list of integers into a binary string.

use 5.036;

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

    my $compressed = chr(scalar @counts);

    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        $compressed .= chr($blen);
        $compressed .= pack('N', $len);
    }

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

    my $count_len = ord(getc($fh));

    my @counts;
    my $bits_len = 0;

    for (1 .. $count_len) {
        my $blen = ord(getc($fh));
        my $len  = unpack('N', join('', map { getc($fh) } 1 .. 4));
        push @counts, [$blen + 0, $len + 0];
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
Encoded length: 1168
Rawdata length: 3625
