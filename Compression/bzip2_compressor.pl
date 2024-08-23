#!/usr/bin/perl

# Author: Trizen
# Date: 20 August 2024
# https://github.com/trizen

# A very basic Bzip2 compressor.

# References:
#   BZIP2: Format Specification, by Joe Tsai
#   https://github.com/dsnet/compress/blob/master/doc/bzip2-format.pdf

use 5.036;
use POSIX             qw(ceil);
use List::Util        qw(max);
use Compression::Util qw(:all);

use constant {CHUNK_SIZE => 1 << 16};

local $| = 1;

binmode(STDIN,  ":raw");
binmode(STDOUT, ":raw");

sub encode_mtf_alphabet($alphabet) {
    my %table;
    @table{@$alphabet} = ();

    my $populated = 0;
    my @marked;

    for (my $i = 0 ; $i <= 255 ; $i += 16) {

        my $enc = 0;
        foreach my $j (0 .. 15) {
            if (exists($table{$i + $j})) {
                $enc |= 1 << $j;
            }
        }

        $populated <<= 1;

        if ($enc > 0) {
            $populated |= 1;
            push @marked, $enc;
        }
    }

    say STDERR sprintf("Populated: %016b", $populated);
    say STDERR "Marked: (@marked)";

    return ($populated, \@marked);
}

sub encode_code_lengths($dict) {
    my @lengths;

    foreach my $symbol (0 .. max(keys %$dict) // 0) {
        if (exists($dict->{$symbol})) {
            push @lengths, length($dict->{$symbol});
        }
        else {
            die "Incomplete Huffman tree not supported";
            push @lengths, 0;
        }
    }

    say STDERR "Code lengths: (@lengths)";

    my $deltas = deltas(\@lengths);
    say STDERR "Code lengths deltas: (@$deltas)";
    my $bitstring = int2bits(shift(@$deltas), 5) . '0';

    foreach my $d (@$deltas) {
        $bitstring .= (($d > 0) ? ('10' x $d) : ('11' x abs($d))) . '0';
    }

    say STDERR "Deltas bitstring: $bitstring";

    return $bitstring;
}

my $s = "Hello, World!\n";

my $fh;
if (-t STDIN) {
    open $fh, "<:raw", \$s;
}
else {
    $fh = \*STDIN;
}

print "BZh";

my $level = 1;

if ($level <= 0 or $level > 9) {
    die "Invalid level value: $level";
}

print $level;

my $block_header_bitstring = unpack("B48", "1AY&SY");
my $block_footer_bitstring = unpack("B48", "\27rE8P\x90");

my $bitstring    = '';
my $stream_crc32 = 0;

while (!eof($fh)) {

    read($fh, (my $chunk), CHUNK_SIZE);

    $bitstring .= $block_header_bitstring;

    my $crc32 = crc32(pack 'B*', unpack 'b*', $chunk);
    say STDERR "CRC32: $crc32";

    $crc32 = oct('0b' . int2bits_lsb($crc32, 32));
    say STDERR "Bzip2-CRC32: $crc32";

    $stream_crc32 = $crc32 ^ (0xffffffff & ($stream_crc32 << 1) | ($stream_crc32 >> 31));
    $bitstring .= int2bits($crc32, 32);
    $bitstring .= '0';                    # not randomized

    my $rle4 = rle4_encode($chunk);
    ##say STDERR "RLE4: (@$rle4)";
    my ($bwt, $bwt_idx) = bwt_encode(symbols2string($rle4));

    $bitstring .= int2bits($bwt_idx, 24);

    my ($mtf, $alphabet) = mtf_encode($bwt);
    ##say STDERR "MTF: (@$mtf)";
    say STDERR "MTF Alphabet: (@$alphabet)";

    my ($populated, $marked) = encode_mtf_alphabet($alphabet);

    $bitstring .= int2bits($populated, 16);
    $bitstring .= int2bits_lsb($_, 16) for @$marked;

    my @zrle = reverse @{zrle_encode([reverse @$mtf])};
    ##say STDERR "ZRLE: @zrle";

    my $eob = scalar(@$alphabet) + 1;    # end-of-block symbol
    say STDERR "EOB symbol: $eob";
    push @zrle, $eob;

    my ($dict) = huffman_from_symbols([@zrle, 0 .. $eob - 1]);
    my $num_sels = ceil(scalar(@zrle) / 50);
    say STDERR "Number of selectors: $num_sels";

    $bitstring .= int2bits(2,         3);
    $bitstring .= int2bits($num_sels, 15);
    $bitstring .= '0' x $num_sels;

    $bitstring .= encode_code_lengths($dict) x 2;
    $bitstring .= join('', @{$dict}{@zrle});
}

$bitstring .= $block_footer_bitstring;
$bitstring .= int2bits($stream_crc32, 32);

print pack("B*", $bitstring);
