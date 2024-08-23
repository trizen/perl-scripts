#!/usr/bin/perl

# Author: Trizen
# Date: 19 August 2024
# https://github.com/trizen

# A very basic Bzip2 decompressor.

# References:
#   BZIP2: Format Specification, by Joe Tsai
#   https://github.com/dsnet/compress/blob/master/doc/bzip2-format.pdf
#
#   Pyflate, by Paul Sladen
#   http://www.paul.sladen.org/projects/pyflate/

use 5.036;
use List::Util        qw(max);
use Compression::Util qw(:all);

local $| = 1;

binmode(STDIN,  ":raw");
binmode(STDOUT, ":raw");

my $s = '';

$s .= "BZh91AY&SY\xEA\xE0\x8D\xEB\0\0\0\xC1\0\0\x100\0 \0!\x98\31\x84aw\$S\x85\t\16\xAE\b\xDE\xB0";                                          # "ab\n"
$s .= "BZh91AY&SY\x99\xAC\"V\0\0\2W\x80\0\20`\4\0@\0\x80\6\4\x90\0 \0\"\6\x81\x90\x80i\xA6\x89\30j\xCE\xA4\31o\x8B\xB9\"\x9C(HL\xD6\21+\0";  # "Hello, World!\n"

$s .=
    "BZh91AY&SY\xE9\xA6L\xBE\0\0\20\xC9\x80\n\20\2\xE0?\xFB\x8B0"
  . " \0\x89\fE2i\xA3&\x9A\3A)\xEA\"'\xA8h\3\xD4\xD3gxRZ\4\x8C\xDA'g,\x88\xD5\xA6"
  . "\x9C\xEA\xC4\30wWy\xE4\xD7\xC0\x95\xF9L\x89\5\x936'\xED\x95a\22o%B\x90\x93"
  . "T\xAF\xFD\xE6\xEA)\x8D\x90\x82\xB5\x9E\x89Z\xD7X\xB19\x9D0\xC9\21s\x9E\x95"
  . "\1\xB2F\xE9\x98\xFD\x8A+O\xAD\xBDi\x96s\e\0\4\xA3G\xC0\xB2\4\xA6_\x8B\xB9\"\x9C(Ht\xD3&_\0";    # some bigger string

my $fh;
if (-t STDIN) {
    open $fh, "<:raw", \$s;
}
else {
    $fh = \*STDIN;
}

while (!eof($fh)) {

    my $buffer = '';

    (bytes2int($fh, 2) == 0x425a and getc($fh) eq 'h')
      or die "Not a valid Bzip2 archive";

    my $level = getc($fh) + 0;

    if (not $level) {
        die "invalid level";
    }

    say STDERR "Compression level: $level";

    my $stream_crc32 = 0;

    while (!eof($fh)) {

        my $block_magic = pack "B48", join('', map { read_bit($fh, \$buffer) } 1 .. 48);

        if ($block_magic eq "1AY&SY") {    # BlockHeader
            say STDERR "Block header detected";

            my $crc32 = bits2int($fh, 32, \$buffer);
            say STDERR "CRC32 = $crc32";

            my $randomized = read_bit($fh, \$buffer);
            $randomized == 0 or die "randomized not supported";

            my $bwt_idx = bits2int($fh, 24, \$buffer);
            say STDERR "BWT index: $bwt_idx";

            my @alphabet;
            my $l1 = bits2int($fh, 16, \$buffer);
            for my $i (0 .. 15) {
                if ($l1 & (0x8000 >> $i)) {
                    my $l2 = bits2int($fh, 16, \$buffer);
                    for my $j (0 .. 15) {
                        if ($l2 & (0x8000 >> $j)) {
                            push @alphabet, 16 * $i + $j;
                        }
                    }
                }
            }

            say STDERR "MTF alphabet: (@alphabet)";

            my $num_trees = bits2int($fh, 3, \$buffer);
            say STDERR "Number or trees: $num_trees";

            my $num_sels = bits2int($fh, 15, \$buffer);
            say STDERR "Number of selectors: $num_sels";

            my @idxs;
            for (1 .. $num_sels) {
                my $i = 0;
                while (read_bit($fh, \$buffer)) {
                    $i += 1;
                    ($i < $num_trees) or die "error";
                }
                push @idxs, $i;
            }

            my $sels = mtf_decode(\@idxs, [0 .. $num_trees - 1]);
            say STDERR "Selectors: (@$sels)";

            my $MaxHuffmanBits = 20;
            my $num_syms       = scalar(@alphabet) + 2;

            my @trees;
            for (1 .. $num_trees) {
                my @clens;
                my $clen = bits2int($fh, 5, \$buffer);
                for (1 .. $num_syms) {
                    while (1) {

                        ($clen > 0 and $clen <= $MaxHuffmanBits)
                          or warn "Invalid code length: $clen!\n";

                        if (not read_bit($fh, \$buffer)) {
                            last;
                        }

                        $clen -= read_bit($fh, \$buffer) ? 1 : -1;
                    }

                    push @clens, $clen;
                }
                push @trees, \@clens;
                say STDERR "Code lengths: (@clens)";
            }

            foreach my $tree (@trees) {
                my $maxLen = max(@$tree);
                my $sum    = 1 << $maxLen;
                for my $clen (@$tree) {
                    $sum -= (1 << $maxLen) >> $clen;
                }

                $sum == 0 or warn "incomplete tree detected: (@$tree)\n";
            }

            my @huffman_trees = map { (huffman_from_code_lengths($_))[1] } @trees;

            my $eob = @alphabet + 1;

            my @zrle;
            my $code = '';

            my $sel_idx = 0;
            my $tree    = $huffman_trees[$sels->[$sel_idx]];
            my $decoded = 50;

            while (!eof($fh)) {
                $code .= read_bit($fh, \$buffer);

                if (length($code) > $MaxHuffmanBits) {
                    die "[!] Something went wrong: length of LL code `$code` is > $MaxHuffmanBits.\n";
                }

                if (exists($tree->{$code})) {

                    my $sym = $tree->{$code};

                    if ($sym == $eob) {    # end of block marker
                        say STDERR "EOB detected: $sym";
                        last;
                    }

                    push @zrle, $sym;
                    $code = '';

                    if (--$decoded <= 0) {
                        if (++$sel_idx <= $#$sels) {
                            $tree = $huffman_trees[$sels->[$sel_idx]];
                        }
                        else {
                            die "No more selectors";    # should not happen
                        }
                        $decoded = 50;
                    }
                }
            }

            ##say STDERR "ZRLE: (@zrle)";
            my @mtf = reverse @{zrle_decode([reverse @zrle])};
            ##say STDERR "MTF: (@mtf)";

            my $bwt = symbols2string mtf_decode(\@mtf, \@alphabet);
            ## say "BWT: ($bwt, $bwt_idx)";

            my $rle4 = string2symbols bwt_decode($bwt, $bwt_idx);
            my $data = rle4_decode($rle4);
            my $dec  = symbols2string($data);

            my $new_crc32 = oct('0b' . int2bits_lsb(crc32(pack('b*', unpack('B*', $dec))), 32));

            say STDERR "Computed CRC32: $new_crc32";

            if ($crc32 != $new_crc32) {
                warn "CRC32 error: $crc32 (stored) != $new_crc32 (actual)\n";
            }

            $stream_crc32 = ($new_crc32 ^ (0xffffffff & ((0xffffffff & ($stream_crc32 << 1)) | (($stream_crc32 >> 31) & 0x1)))) & 0xffffffff;

            print $dec;
        }
        elsif ($block_magic eq "\27rE8P\x90") {    # BlockFooter
            say STDERR "Block footer detected";
            my $stored_stream_crc32 = bits2int($fh, 32, \$buffer);
            say STDERR "Stream CRC32: $stored_stream_crc32";

            if ($stream_crc32 != $stored_stream_crc32) {
                warn "Stream CRC32 error: $stored_stream_crc32 (stored) != $stream_crc32 (actual)\n";
            }

            $buffer = '';
            last;
        }
        else {
            die "Unknown block magic: $block_magic";
        }

    }

    say STDERR "End of container";
}

say STDERR "End of input";
