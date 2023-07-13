#!/usr/bin/perl

# Author: Trizen
# Date: 12 July 2023
# https://github.com/trizen

# The Arithmetic Coding algorithm (adaptive version), implemented using native integers.

# References:
#   Data Compression (Summer 2023) - Lecture 15 - Infinite Precision in Finite Bits
#   https://youtube.com/watch?v=EqKbT3QdtOI
#
#   Data Compression (Summer 2023) - Lecture 16 - Adaptive Methods
#   https://youtube.com/watch?v=YKv-w8bXi9c

use 5.036;

use constant {BITS => 31};

use constant {
              EOF  => 256,
              MAX  => (1 << BITS) - 1,
              MSB  => (1 << (BITS - 1)),
              SMSB => (1 << (BITS - 2)),
             };

sub create_cfreq ($freq_value) {

    my %cf_low;
    my %cf_high;
    my $T = 0;

    my %freq;

    foreach my $i (0 .. EOF) {
        $freq{$i}   = $freq_value;
        $cf_low{$i} = $T;
        $T += $freq_value;
        $cf_high{$i} = $T;
    }

    return (\%freq, \%cf_low, \%cf_high, $T);
}

sub increment_freq ($c, $freq, $cf_low, $cf_high) {

    $freq->{$c}++;
    my $T = $cf_low->{$c};

    foreach my $i ($c .. EOF) {
        $cf_low->{$i} = $T;
        $T += $freq->{$i};
        $cf_high->{$i} = $T;
    }

    return $T;
}

sub encode ($string) {

    my $enc   = '';
    my $bytes = [unpack('C*', $string), EOF];

    my ($freq, $cf_low, $cf_high, $T) = create_cfreq(1);

    if ($T > MAX) {
        die "Too few bits: $T > ", MAX;
    }

    my $low      = 0;
    my $high     = MAX;
    my $uf_count = 0;

    foreach my $c (@$bytes) {

        my $w = ($high - $low + 1);
        $high = ($low + int(($w * $cf_high->{$c}) / $T));
        $low  = ($low + int(($w * $cf_low->{$c}) / $T));

        $T = increment_freq($c, $freq, $cf_low, $cf_high);

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

    $enc .= '1';
    return $enc;
}

sub decode ($bits) {
    open my $fh, '<:raw', \$bits;

    my ($freq, $cf_low, $cf_high, $T) = create_cfreq(1);

    my $dec  = '';
    my $low  = 0;
    my $high = MAX;
    my $enc  = oct('0b' . join '', map { getc($fh) // 0 } 1 .. BITS);

    while (1) {
        my $w  = ($high + 1) - $low;
        my $ss = int((($T * ($enc - $low + 1)) - 1) / $w);

        my $i = 0;
        foreach my $j (0 .. EOF) {
            if ($cf_low->{$j} <= $ss and $ss < $cf_high->{$j}) {
                $i = $j;
                last;
            }
        }

        last if ($i == EOF);

        $dec .= chr($i);

        $high = $low + int(($w * $cf_high->{$i}) / $T);
        $low  = $low + int(($w * $cf_low->{$i}) / $T);

        $T = increment_freq($i, $freq, $cf_low, $cf_high);

        if ($high > MAX) {
            die "high > MAX: ($high > ${\MAX})";
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

my ($enc) = encode($str);

say $enc;
say "Encoded bytes length: ", length($enc) / 8;

my $dec = decode($enc);
say $dec;
$str eq $dec or die "Decoding error: ", length($str), ' <=> ', length($dec);

__END__
0100000100000001110010111101111100000011110011111100011111000001101110101100000100111000001011100001010000111001110111001110111100001100110111100010111001011010100110001101111010010011001110100100000010001011101111001010100110111
Encoded bytes length: 28.625
ABRACADABRA AND A VERY SAD SALAD
