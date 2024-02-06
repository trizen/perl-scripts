#!/usr/bin/perl

# Author: Trizen
# Date: 12 July 2023
# Edit: 06 February 2024
# https://github.com/trizen

# The Arithmetic Coding algorithm (adaptive version), implemented using native integers.

# References:
#   Data Compression (Summer 2023) - Lecture 15 - Infinite Precision in Finite Bits
#   https://youtube.com/watch?v=EqKbT3QdtOI
#
#   Data Compression (Summer 2023) - Lecture 16 - Adaptive Methods
#   https://youtube.com/watch?v=YKv-w8bXi9c

use 5.036;

use constant {
              ESCAPE => 256,
              EOF    => 257,
             };

use constant BITS => 32;
use constant MAX  => oct('0b' . ('1' x BITS));

sub create_cfreq ($table) {

    my %cf_low;
    my %cf_high;
    my $T = 0;

    my %freq;

    foreach my $pair (@$table) {
        my ($i, $v) = @$pair;
        $v ||= 1;    # FIXME: make it work with v = 0
        $freq{$i}   = $v;
        $cf_low{$i} = $T;
        $T += $v;
        $cf_high{$i} = $T;
    }

    return (\%freq, \%cf_low, \%cf_high, $T);
}

sub create_contexts {

    my @C;

    foreach my $i (0 .. 1) {

        my ($freq, $cf_low, $cf_high, $T) =
          create_cfreq(
                       [(map { [$_, 1 - $i] } 0 .. 255),
                        (
                           ($i == 0)
                         ? ([ESCAPE, 0], [EOF, 1])
                         : ([ESCAPE, 1], [EOF, 1])
                        ),
                       ]
                      );

        push @C,
          {
            low      => 0,
            high     => MAX,
            freq     => $freq,
            cf_low   => $cf_low,
            cf_high  => $cf_high,
            T        => $T,
            uf_count => 0,
          };
    }

    return @C;
}

sub increment_freq ($c, $freq, $cf_low, $cf_high) {

    if ($c <= 255) {
        ++$freq->{$c};
    }

    my $T = $cf_low->{$c};

    foreach my $i ($c .. 257) {
        $cf_low->{$i} = $T;
        $T += $freq->{$i};
        $cf_high->{$i} = $T;
    }

    return $T;
}

sub encode ($string) {

    my $enc   = '';
    my $bytes = [unpack('C*', $string), EOF];

    my @C = create_contexts();

    if ($C[0]{T} > MAX) {
        die "Too few bits:  $C[0]{T} > ", MAX;
    }

    my sub encode_symbol ($c, $context) {

        my $w = $C[$context]{high} - $C[$context]{low} + 1;
        $C[$context]{high} = ($C[$context]{low} + int(($w * $C[$context]{cf_high}->{$c}) / $C[$context]{T}) - 1) & MAX;
        $C[$context]{low}  = ($C[$context]{low} + int(($w * $C[$context]{cf_low}->{$c}) / $C[$context]{T})) & MAX;

        foreach my $context (1) {
            $C[$context]{T} = increment_freq($c, $C[$context]{freq}, $C[$context]{cf_low}, $C[$context]{cf_high});
        }

        if ($C[$context]{high} > MAX) {
            die "high > MAX: $C[$context]{high} > ${\MAX}";
        }

        if ($C[$context]{low} >= $C[$context]{high}) {
            die "$C[$context]{low} >= $C[$context]{high}";
        }

        while (1) {

            if (($C[$context]{high} >> (BITS - 1)) == ($C[$context]{low} >> (BITS - 1))) {

                my $bit = $C[$context]{high} >> (BITS - 1);
                $enc .= $bit;

                if ($C[$context]{uf_count} > 0) {
                    $enc .= join('', 1 - $bit) x $C[$context]{uf_count};
                    $C[$context]{uf_count} = 0;
                }

                $C[$context]{low} <<= 1;
                ($C[$context]{high} <<= 1) |= 1;
            }
            elsif (((($C[$context]{low} >> (BITS - 2)) & 0x1) == 1) && ((($C[$context]{high} >> (BITS - 2)) & 0x1) == 0)) {
                ($C[$context]{high} <<= 1) |= (1 << (BITS - 1));
                $C[$context]{high} |= 1;
                ($C[$context]{low} <<= 1) &= ((1 << (BITS - 1)) - 1);
                ++$C[$context]{uf_count};
            }
            else {
                last;
            }

            $C[$context]{low}  &= MAX;
            $C[$context]{high} &= MAX;
        }
    }

    foreach my $c (@$bytes) {
        if ($C[1]{freq}{$c} == 0) {
            encode_symbol(ESCAPE, 1);
            encode_symbol($c,     0);
        }
        else {
            encode_symbol($c, 1);
        }
    }

    $enc .= '0';
    $enc .= '1';

    while (length($enc) % 8 != 0) {
        $enc .= '1';
    }

    return $enc;
}

sub decode ($bits) {
    open my $fh, '<:raw', \$bits;

    my @C = create_contexts();

    my $dec = '';
    my $enc = oct('0b' . join '', map { getc($fh) // 1 } 1 .. BITS);

    my $context = 1;

    while (1) {

        my $w  = $C[$context]{high} - $C[$context]{low} + 1;
        my $ss = int((($C[$context]{T} * ($enc - $C[$context]{low} + 1)) - 1) / $w);

        my $i = undef;
        foreach my $j (0 .. 257) {
            $C[$context]{freq}{$j} > 0 or next;
            if ($C[$context]{cf_low}->{$j} <= $ss and $ss < $C[$context]{cf_high}->{$j}) {
                $i = $j;
                last;
            }
        }

        $i // die "decoding error";

        last if ($i == EOF);

        if ($i <= 255) {
            $dec .= chr($i);
        }

        $C[$context]{high} = ($C[$context]{low} + int(($w * $C[$context]{cf_high}->{$i}) / $C[$context]{T}) - 1) & MAX;
        $C[$context]{low}  = ($C[$context]{low} + int(($w * $C[$context]{cf_low}->{$i}) / $C[$context]{T})) & MAX;

        foreach my $context (1) {
            $C[$context]{T} = increment_freq($i, $C[$context]{freq}, $C[$context]{cf_low}, $C[$context]{cf_high});
        }

        if ($C[$context]{high} > MAX) {
            die "high > MAX: ($C[$context]{high} > ${\MAX})";
        }

        if ($C[$context]{low} >= $C[$context]{high}) {
            die "$C[$context]{low} >= $C[$context]{high}";
        }

        while (1) {

            if (($C[$context]{high} >> (BITS - 1)) == ($C[$context]{low} >> (BITS - 1))) {
                ($C[$context]{high} <<= 1) |= 1;
                $C[$context]{low} <<= 1;
                ($enc <<= 1) |= (getc($fh) // 1);
            }
            elsif (((($C[$context]{low} >> (BITS - 2)) & 0x1) == 1) && ((($C[$context]{high} >> (BITS - 2)) & 0x1) == 0)) {
                ($C[$context]{high} <<= 1) |= (1 << (BITS - 1));
                $C[$context]{high} |= 1;
                ($C[$context]{low} <<= 1) &= ((1 << (BITS - 1)) - 1);
                $enc = (($enc >> (BITS - 1)) << (BITS - 1)) | (($enc & ((1 << (BITS - 2)) - 1)) << 1) | (getc($fh) // 1);
            }
            else {
                last;
            }

            $C[$context]{low}  &= MAX;
            $C[$context]{high} &= MAX;
            $enc               &= MAX;
        }

        if ($i == ESCAPE) {
            $context == 1 or die "error";
            $context = 0;
        }
        elsif ($context == 0) {
            $context = 1;
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
0100000011000001000010010011111111110001001000010100100101000010110101110111001000110110110010011001000111010101100010111110010111111101011110010010110000110100100101110011110101110111101000110000011100010111111100001010011011001011
Encoded bytes length: 29
ABRACADABRA AND A VERY SAD SALAD
