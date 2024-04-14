#!/usr/bin/perl

# Author: Trizen
# Date: 13 January 2024
# Edit: 14 April 2024
# https://github.com/trizen

# Decompress GZIP files (.gz).

# DEFLATE's block type 0, 1 and 2 are all supported.

# Reference:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;
use Digest::CRC       qw();
use List::Util        qw(max);
use Compression::Util qw(:all);

use constant {
              WINDOW_SIZE => 1 << 15,    # maximum window size in DEFLATE: 2^15
             };

sub extract_block_type_0 ($in_fh, $buffer) {

    my $len           = bits2int_lsb($in_fh, 16, $buffer);
    my $nlen          = bits2int_lsb($in_fh, 16, $buffer);
    my $expected_nlen = (~$len) & 0xffff;

    if ($expected_nlen != $nlen) {
        die "[!] The ~length value is not correct: $nlen (actual) != $expected_nlen (expected)\n";
    }
    else {
        print STDERR ":: Chunk length: $len\n";
    }

    read($in_fh, (my $chunk), $len);
    return $chunk;
}

my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS) = make_deflate_tables(WINDOW_SIZE);

sub decode_huffman($in_fh, $buffer, $rev_dict, $dist_rev_dict, $search_window) {

    my $data = '';
    my $code = '';

    my $max_ll_code_len   = max(map { length($_) } keys %$rev_dict);
    my $max_dist_code_len = max(map { length($_) } keys %$dist_rev_dict);

    while (1) {
        $code .= read_bit_lsb($in_fh, $buffer);

        if (length($code) > $max_ll_code_len) {
            die "[!] Something went wrong: length of LL code `$code` is > $max_ll_code_len.\n";
        }

        if (exists($rev_dict->{$code})) {

            my $symbol = $rev_dict->{$code};

            if ($symbol <= 255) {
                $data           .= chr($symbol);
                $$search_window .= chr($symbol);
            }
            elsif ($symbol == 256) {    # end-of-block marker
                $code = '';
                last;
            }
            else {                      # LZSS decoding
                my ($length, $LL_bits) = @{$LENGTH_SYMBOLS->[$symbol - 256 + 1]};
                $length += bits2int_lsb($in_fh, $LL_bits, $buffer) if ($LL_bits > 0);

                my $dist_code = '';

                while (1) {
                    $dist_code .= read_bit_lsb($in_fh, $buffer);

                    if (length($dist_code) > $max_dist_code_len) {
                        die "[!] Something went wrong: length of distance code `$dist_code` is > $max_dist_code_len.\n";
                    }

                    if (exists($dist_rev_dict->{$dist_code})) {
                        last;
                    }
                }

                my ($dist, $dist_bits) = @{$DISTANCE_SYMBOLS->[$dist_rev_dict->{$dist_code} + 1]};
                $dist += bits2int_lsb($in_fh, $dist_bits, $buffer) if ($dist_bits > 0);

                foreach my $i (1 .. $length) {
                    my $str = substr($$search_window, length($$search_window) - $dist, 1);
                    $$search_window .= $str;
                    $data           .= $str;
                }
            }

            $code = '';
        }
    }

    if ($code ne '') {
        die "[!] Something went wrong: code `$code` is not empty!\n";
    }

    return $data;
}

sub extract_block_type_1 ($in_fh, $buffer, $search_window) {

    state $rev_dict;
    state $dist_rev_dict;

    if (!defined($rev_dict)) {

        my @code_lengths = (0) x 288;
        foreach my $i (0 .. 143) {
            $code_lengths[$i] = 8;
        }
        foreach my $i (144 .. 255) {
            $code_lengths[$i] = 9;
        }
        foreach my $i (256 .. 279) {
            $code_lengths[$i] = 7;
        }
        foreach my $i (280 .. 287) {
            $code_lengths[$i] = 8;
        }

        (undef, $rev_dict)      = huffman_from_code_lengths(\@code_lengths);
        (undef, $dist_rev_dict) = huffman_from_code_lengths([(5) x 32]);
    }

    decode_huffman($in_fh, $buffer, $rev_dict, $dist_rev_dict, $search_window);
}

sub decode_CL_lengths($in_fh, $buffer, $CL_rev_dict, $size) {

    my @lengths;
    my $code = '';

    while (1) {
        $code .= read_bit_lsb($in_fh, $buffer);

        if (length($code) > 7) {
            die "[!] Something went wrong: length of CL code `$code` is > 7.\n";
        }

        if (exists($CL_rev_dict->{$code})) {
            my $CL_symbol = $CL_rev_dict->{$code};

            if ($CL_symbol <= 15) {
                push @lengths, $CL_symbol;
            }
            elsif ($CL_symbol == 16) {
                push @lengths, ($lengths[-1]) x (3 + bits2int_lsb($in_fh, 2, $buffer));
            }
            elsif ($CL_symbol == 17) {
                push @lengths, (0) x (3 + bits2int_lsb($in_fh, 3, $buffer));
            }
            elsif ($CL_symbol == 18) {
                push @lengths, (0) x (11 + bits2int_lsb($in_fh, 7, $buffer));
            }
            else {
                die "Unknown CL symbol: $CL_symbol\n";
            }

            $code = '';
            last if (scalar(@lengths) >= $size);
        }
    }

    if (scalar(@lengths) != $size) {
        die "Something went wrong: size $size (expected) != ", scalar(@lengths);
    }

    if ($code ne '') {
        die "Something went wrong: code `$code` is not empty!";
    }

    return @lengths;
}

sub extract_block_type_2 ($in_fh, $buffer, $search_window) {

    # (5 bits) HLIT = (number of LL code entries present) - 257
    my $HLIT = bits2int_lsb($in_fh, 5, $buffer) + 257;

    # (5 bits) HDIST = (number of distance code entries present) - 1
    my $HDIST = bits2int_lsb($in_fh, 5, $buffer) + 1;

    # (4 bits) HCLEN = (number of CL code entries present) - 4
    my $HCLEN = bits2int_lsb($in_fh, 4, $buffer) + 4;

    say STDERR ":: Number of LL codes: $HLIT";
    say STDERR ":: Number of dist codes: $HDIST";
    say STDERR ":: Number of CL codes: $HCLEN";

    my @CL_code_lenghts = (0) x 19;
    my @CL_order        = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

    foreach my $i (0 .. $HCLEN - 1) {
        $CL_code_lenghts[$CL_order[$i]] = bits2int_lsb($in_fh, 3, $buffer);
    }

    say STDERR ":: CL code lengths: @CL_code_lenghts";

    my (undef, $CL_rev_dict) = huffman_from_code_lengths(\@CL_code_lenghts);

    my @LL_CL_lengths   = decode_CL_lengths($in_fh, $buffer, $CL_rev_dict, $HLIT);
    my @dist_CL_lengths = decode_CL_lengths($in_fh, $buffer, $CL_rev_dict, $HDIST);

    my (undef, $LL_rev_dict)   = huffman_from_code_lengths(\@LL_CL_lengths);
    my (undef, $dist_rev_dict) = huffman_from_code_lengths(\@dist_CL_lengths);

    decode_huffman($in_fh, $buffer, $LL_rev_dict, $dist_rev_dict, $search_window);
}

sub extract ($in_fh, $output_file, $defined_output_file) {

    my $MAGIC = (getc($in_fh) // die "error") . (getc($in_fh) // die "error");

    if ($MAGIC ne pack('C*', 0x1f, 0x8b)) {
        die "Not a valid Gzip container!\n";
    }

    my $CM     = getc($in_fh) // die "error";                             # 0x08 = DEFLATE
    my $FLAGS  = getc($in_fh) // die "error";                             # flags
    my $MTIME  = join('', map { getc($in_fh) // die "error" } 1 .. 4);    # modification time
    my $XFLAGS = getc($in_fh) // die "error";                             # extra flags
    my $OS     = getc($in_fh) // die "error";                             # 0x03 = Unix

    if ($CM ne chr(0x08)) {
        die "Only DEFLATE compression method is supported (0x08)! Got: 0x", sprintf('%02x', ord($CM));
    }

    # TODO: add support for more attributes
    my $has_filename = 0;
    my $has_comment  = 0;

    if ((ord($FLAGS) & 0b0000_1000) != 0) {
        $has_filename = 1;
    }

    if ((ord($FLAGS) & 0b0001_0000) != 0) {
        $has_comment = 1;
    }

    if ($has_filename) {
        my $filename = read_null_terminated($in_fh);    # filename
        say STDERR ":: Filename: ", $filename;
        if (not $defined_output_file) {
            $output_file = $filename;
        }
    }

    if ($has_comment) {
        say STDERR ":: Comment: ", read_null_terminated($in_fh);
    }

    my $out_fh = ref($output_file) eq 'GLOB' ? $output_file : undef;
    if (!defined($out_fh)) {
        open $out_fh, '>:raw', $output_file or die "Can't create file <<$output_file>>: $!";
    }

    my $crc32         = Digest::CRC->new(type => "crc32");
    my $actual_length = 0;
    my $buffer        = '';
    my $search_window = '';

    while (1) {

        my $is_last    = read_bit_lsb($in_fh, \$buffer);
        my $block_type = read_bit_lsb($in_fh, \$buffer) . read_bit_lsb($in_fh, \$buffer);

        my $chunk = '';

        if ($block_type eq '00') {
            say STDERR "\n:: Extracting block of type 0";
            read_bit_lsb($in_fh, \$buffer) for (1 .. (length($buffer) % 8));    # pad to a byte
            $chunk = extract_block_type_0($in_fh, \$buffer);
            $search_window .= $chunk;
        }
        elsif ($block_type eq '10') {
            say STDERR "\n:: Extracting block of type 1";
            $chunk = extract_block_type_1($in_fh, \$buffer, \$search_window);
        }
        elsif ($block_type eq '01') {
            say STDERR "\n:: Extracting block of type 2";
            $chunk = extract_block_type_2($in_fh, \$buffer, \$search_window);
        }
        else {
            die "[!] Unknown block of type: $block_type";
        }

        print $out_fh $chunk;
        $crc32->add($chunk);
        $actual_length += length($chunk);
        $search_window = substr($search_window, -WINDOW_SIZE) if (length($search_window) > WINDOW_SIZE);

        last if $is_last;
    }

    $buffer = '';    # discard any padding bits

    my $stored_crc32 = bits2int_lsb($in_fh, 32, \$buffer);
    my $actual_crc32 = $crc32->digest;

    say '';

    if ($stored_crc32 != $actual_crc32) {
        print STDERR "[!] The CRC32 does not match: $actual_crc32 (actual) != $stored_crc32 (stored)\n";
    }
    else {
        print STDERR ":: CRC32 value: $actual_crc32\n";
    }

    my $stored_length = bits2int_lsb($in_fh, 32, \$buffer);

    if ($stored_length != $actual_length) {
        print STDERR "[!] The length does not match: $actual_length (actual) != $stored_length (stored)\n";
    }
    else {
        print STDERR ":: Total length: $actual_length\n";
    }

    if (eof($in_fh)) {
        print STDERR "\n:: Reached the end of the file.\n";
    }
    else {
        print STDERR "\n:: There is something else in the container! Trying to recurse!\n\n";
        extract($in_fh, $out_fh, 1);
    }
}

if (-t STDIN) {
    my $input  = $ARGV[0] // die "usage: $0 [input] [output.gz]\n";
    my $output = $ARGV[1] // ($input =~ s/\.gz\z//ir);
    open my $fh, '<:raw', $input or die "Can't open file <<$input>> for reading: $!";
    extract($fh, $output, defined($ARGV[1]));
}
else {
    extract(\*STDIN, \*STDOUT, 1);
}
