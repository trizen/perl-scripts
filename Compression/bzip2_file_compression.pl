#!/usr/bin/perl

# Author: Trizen
# Date: 25 August 2024
# https://github.com/trizen

# A valid Bzip2 file compressor/decompressor.

# References:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A
#
#   BZIP2: Format Specification, by Joe Tsai
#   https://github.com/dsnet/compress/blob/master/doc/bzip2-format.pdf
#
#   Pyflate, by Paul Sladen
#   http://www.paul.sladen.org/projects/pyflate/

use 5.036;
use File::Basename    qw(basename);
use Compression::Util qw(:all);
use List::Util        qw(max);
use Getopt::Std       qw(getopts);

binmode(STDIN,  ":raw");
binmode(STDOUT, ":raw");

use constant {
              FORMAT     => 'bz2',
              CHUNK_SIZE => 1 << 17,
             };

sub usage ($code = 0) {
    print <<"EOH";
usage: $0 [options] [input file] [output file]

options:
        -e            : extract
        -i <filename> : input filename
        -o <filename> : output filename
        -r            : rewrite output
        -h            : this message

examples:
         $0 document.txt
         $0 document.txt archive.${\FORMAT}
         $0 archive.${\FORMAT} document.txt
         $0 -e -i archive.${\FORMAT} -o document.txt

EOH

    exit($code // 0);
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

sub my_bzip2_compress($fh, $out_fh) {

    print $out_fh "BZh";

    my $level = 9;

    if ($level <= 0 or $level > 9) {
        die "Invalid level value: $level";
    }

    print $out_fh $level;

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

        $stream_crc32 = ($crc32 ^ (0xffffffff & ((0xffffffff & ($stream_crc32 << 1)) | (($stream_crc32 >> 31) & 0x1)))) & 0xffffffff;
        $bitstring .= int2bits($crc32, 32);
        $bitstring .= '0';                    # not randomized

        my $rle4 = rle4_encode($chunk);
        ##say STDERR "RLE4: (@$rle4)";
        my ($bwt, $bwt_idx) = bwt_encode(symbols2string($rle4));

        $bitstring .= int2bits($bwt_idx, 24);

        my ($mtf, $alphabet) = mtf_encode($bwt);
        ##say STDERR "MTF: (@$mtf)";
        say STDERR "MTF Alphabet: (@$alphabet)";

        $bitstring .= unpack('B*', encode_alphabet_256($alphabet));

        my @zrle = reverse @{zrle_encode([reverse @$mtf])};
        ##say STDERR "ZRLE: @zrle";

        my $eob = scalar(@$alphabet) + 1;    # end-of-block symbol
        say STDERR "EOB symbol: $eob";
        push @zrle, $eob;

        my ($dict) = huffman_from_symbols([@zrle, 0 .. $eob - 1]);
        my $num_sels = sprintf('%.0f', 0.5 + (scalar(@zrle) / 50));
        say STDERR "Number of selectors: $num_sels";

        $bitstring .= int2bits(2,         3);
        $bitstring .= int2bits($num_sels, 15);
        $bitstring .= '0' x $num_sels;

        $bitstring .= encode_code_lengths($dict) x 2;
        $bitstring .= join('', @{$dict}{@zrle});

        print $out_fh pack('B*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));
    }

    $bitstring .= $block_footer_bitstring;
    $bitstring .= int2bits($stream_crc32, 32);

    print $out_fh pack("B*", $bitstring);
    return 1;
}

sub my_bzip2_decompress($fh, $out_fh) {

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

                print $out_fh $dec;
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
    return 1;
}

sub main {
    my %opt;
    getopts('ei:o:vhr', \%opt);

    $opt{h} && usage(0);
    $opt{v} && version();

    my ($input, $output) = @ARGV;
    $input  //= $opt{i} // usage(2);
    $output //= $opt{o};

    my $ext = qr{\.${\FORMAT}\z}io;
    if ($opt{e} || $input =~ $ext) {

        if (not defined $output) {
            ($output = basename($input)) =~ s{$ext}{}
              || die "$0: no output file specified!\n";
        }

        if (not $opt{r} and -e $output) {
            print "'$output' already exists! -- Replace? [y/N] ";
            <STDIN> =~ /^y/i || exit 17;
        }

        open my $in_fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";

        open my $out_fh, '>:raw', $output
          or die "Can't open file <<$output>> for writing: $!";

        my_bzip2_decompress($in_fh, $out_fh)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;

        open my $in_fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";

        open my $out_fh, '>:raw', $output
          or die "Can't open file <<$output>> for writing: $!";

        my_bzip2_compress($in_fh, $out_fh)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

main();
exit(0);
