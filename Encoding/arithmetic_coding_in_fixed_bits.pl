#!/usr/bin/perl

# Author: Trizen
# Date: 12 July 2023
# https://github.com/trizen

# The Arithmetic Coding algorithm, implemented using native integers.

# Reference:
#   Data Compression (Summer 2023) - Lecture 15 - Infinite Precision in Finite Bits
#   https://youtube.com/watch?v=EqKbT3QdtOI

use 5.036;

use List::Util qw(max);
use constant {BITS => 31};

use constant {
              MAX  => (1 << BITS) - 1,
              MSB  => (1 << (BITS - 1)),
              SMSB => (1 << (BITS - 2)),
             };

sub create_cfreq ($freq) {

    my %cf_low;
    my %cf_high;
    my $T = 0;

    foreach my $i (sort { $a <=> $b } keys %$freq) {
        $freq->{$i} // next;
        $cf_low{$i} = $T;
        $T += $freq->{$i};
        $cf_high{$i} = $T;
    }

    return (\%cf_low, \%cf_high, $T);
}

sub encode ($string) {

    my $enc   = '';
    my @bytes = unpack('C*', $string);

    push @bytes, max(@bytes) + 1;

    my %freq;
    ++$freq{$_} for @bytes;

    # Workaround for low frequencies
    foreach my $k (keys %freq) {
        $freq{$k} += 256;
    }

    my ($cf_low, $cf_high, $T) = create_cfreq(\%freq);

    if ($T > MAX) {
        die "Too few bits: $T > ${\MAX}";
    }

    my $low      = 0;
    my $high     = MAX;
    my $uf_count = 0;

    foreach my $c (@bytes) {

        my $w = $high - $low + 1;

        $high = ($low + int(($w * $cf_high->{$c}) / $T));
        $low  = ($low + int(($w * $cf_low->{$c}) / $T));

        if ($high > MAX) {
            die "high > MAX: $high > ${\MAX}";
        }

        if ($low >= $high) { die "$low >= $high" }

        while (1) {

            if (($low & MSB) == ($high & MSB)) {

                my $bit = ($low & MSB) >> (BITS - 1);

                $enc .= $bit;

                if ($uf_count > 0) {
                    $enc .= join('', (1 - $bit) x $uf_count);
                    $uf_count = 0;
                }

                if ($bit == 1) {
                    $low  ^= MSB;
                    $high ^= MSB;
                }

                $low  <<= 1;
                $high <<= 1;
                $high |= 1;
            }
            elsif ((($low & SMSB) == SMSB) and (($high & SMSB) == 0)) {

                $low ^= SMSB;
                ##$low = (($low & MSB) >> 1) | ($low & (SMSB - 1));

                $high -= SMSB if ($high >= SMSB);
                ##$high = (($high & MSB) >> 1) | ($high & (SMSB - 1));

                $low  <<= 1;
                $high <<= 1;
                $high |= 1;

                $uf_count += 1;
            }
            else {
                last;
            }
        }
    }

    if ($enc eq '') {
        my $bit = ($low & MSB) >> (BITS - 1);

        $enc .= $bit;

        if ($uf_count > 0) {
            $enc .= join('', (1 - $bit) x ($uf_count));
            $uf_count = 0;
        }
    }

    $enc .= '1';

    return ($enc, \%freq);
}

sub decode ($bits, $freq) {
    open my $fh, '<:raw', \$bits;

    my ($cf_low, $cf_high, $T) = create_cfreq($freq);

    my $dec  = '';
    my $low  = 0;
    my $high = MAX;
    my $enc  = oct('0b' . join '', map { getc($fh) // 0 } 1 .. BITS);

    my @table;
    foreach my $i (sort { $a <=> $b } keys %$freq) {
        foreach my $j ($cf_low->{$i} .. $cf_high->{$i} - 1) {
            $table[$j] = $i;
        }
    }

    my $eof = max(keys %$freq);

    while (1) {

        my $w  = $high - $low + 1;
        my $ss = int((($T * ($enc - $low + 1)) - 1) / $w);    # FIXME: sometimes this value is incorrect

        my $i = $table[$ss];
        last if ($i == $eof);

        $dec .= chr($i);

        $high = $low + int(($w * $cf_high->{$i}) / $T);
        $low  = $low + int(($w * $cf_low->{$i}) / $T);

        if ($high > MAX) {
            die "error";
        }

        if ($low >= $high) { die "$low >= $high" }

        while (1) {

            if (($low & MSB) == ($high & MSB)) {

                if (($low & MSB) == MSB) {
                    $low  ^= MSB;
                    $high ^= MSB;
                }

                $low  <<= 1;
                $high <<= 1;
                $high |= 1;

                if (($enc & MSB) == MSB) {
                    $enc ^= MSB;
                }

                $enc <<= 1;
                $enc |= getc($fh) // 0;
            }
            elsif ((($low & SMSB) == SMSB) and (($high & SMSB) == 0)) {

                $low ^= SMSB;
                ##$low = (($low & MSB) >> 1) | ($low & (SMSB - 1));

                $high -= SMSB;
                ##$high = (($high & MSB) >> 1) | ($high & (SMSB - 1));

                $enc -= SMSB if ($enc >= SMSB);
                ##$enc = (($enc & MSB) >> 1) | ($enc & (SMSB - 1));

                $low  <<= 1;
                $high <<= 1;
                $enc  <<= 1;

                $high |= 1;
                $enc  |= getc($fh) // 0;
            }
            else {
                last;
            }
        }
    }

    return $dec;
}

my $str = "ABRACADABRA AND A VERY SAD SALAD";

if (@ARGV) {
    if (-f $ARGV[0]) {
        $str = do {
            open my $fh, '<:raw', $ARGV[0];
            local $/;
            <$fh>;
        };
    }
    else {
        $str = $ARGV[0];
    }
}

my ($enc, $freq) = encode($str);

say $enc;
say "Encoded bytes length: ", length($enc) / 8;

my $dec = decode($enc, $freq);
say $dec;
$str eq $dec or die "Decoding error: ", length($str), ' <=> ', length($dec);

__END__
0001100000000111000010011001111111110100110001100010000111011000000001110000111110100011110111001011010111010110110000011
Encoded bytes length: 15.125
ABRACADABRA AND A VERY SAD SALAD
