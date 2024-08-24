#!/usr/bin/perl

# Author: Trizen
# Date: 05 May 2024
# https://github.com/trizen

# A valid Gzip file compressor/decompressor, generating DEFLATE blocks of type 0, 1 or 2, whichever is smaller.

# Reference:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;
use File::Basename    qw(basename);
use Compression::Util qw(:all);
use List::Util        qw(all min max);
use Getopt::Std       qw(getopts);

use constant {
              FORMAT     => 'gz',
              CHUNK_SIZE => (1 << 15) - 1,
             };

local $Compression::Util::LZ_MIN_LEN       = 4;                # minimum match length in LZ parsing
local $Compression::Util::LZ_MAX_LEN       = 258;              # maximum match length in LZ parsing
local $Compression::Util::LZ_MAX_DIST      = (1 << 15) - 1;    # maximum allowed back-reference distance in LZ parsing
local $Compression::Util::LZ_MAX_CHAIN_LEN = 64;               # how many recent positions to remember in LZ parsing

my $MAGIC  = pack('C*', 0x1f, 0x8b);                           # magic MIME type
my $CM     = chr(0x08);                                        # 0x08 = DEFLATE
my $FLAGS  = chr(0x00);                                        # flags
my $MTIME  = pack('C*', (0x00) x 4);                           # modification time
my $XFLAGS = chr(0x00);                                        # extra flags
my $OS     = chr(0x03);                                        # 0x03 = Unix

my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables();

sub usage ($code) {
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

#################
# GZIP COMPRESSOR
#################

sub code_length_encoding ($dict) {

    my @lengths;

    foreach my $symbol (0 .. max(keys %$dict) // 0) {
        if (exists($dict->{$symbol})) {
            push @lengths, length($dict->{$symbol});
        }
        else {
            push @lengths, 0;
        }
    }

    my $size        = scalar(@lengths);
    my $rl          = run_length(\@lengths);
    my $offset_bits = '';

    my @CL_symbols;

    foreach my $pair (@$rl) {
        my ($v, $run) = @$pair;

        while ($v == 0 and $run >= 3) {

            if ($run >= 11) {
                push @CL_symbols, 18;
                $run -= 11;
                $offset_bits .= int2bits_lsb(min($run, 127), 7);
                $run -= 127;
            }

            if ($run >= 3 and $run < 11) {
                push @CL_symbols, 17;
                $run -= 3;
                $offset_bits .= int2bits_lsb(min($run, 7), 3);
                $run -= 7;
            }
        }

        if ($v == 0) {
            push(@CL_symbols, (0) x $run) if ($run > 0);
            next;
        }

        push @CL_symbols, $v;
        $run -= 1;

        while ($run >= 3) {
            push @CL_symbols, 16;
            $run -= 3;
            $offset_bits .= int2bits_lsb(min($run, 3), 2);
            $run -= 3;
        }

        push(@CL_symbols, ($v) x $run) if ($run > 0);
    }

    return (\@CL_symbols, $size, $offset_bits);
}

sub cl_encoded_bitstring ($cl_dict, $cl_symbols, $offset_bits) {

    my $bitstring = '';
    foreach my $cl_symbol (@$cl_symbols) {
        $bitstring .= $cl_dict->{$cl_symbol};
        if ($cl_symbol == 16) {
            $bitstring .= substr($offset_bits, 0, 2, '');
        }
        elsif ($cl_symbol == 17) {
            $bitstring .= substr($offset_bits, 0, 3, '');
        }
        elsif ($cl_symbol == 18) {
            $bitstring .= substr($offset_bits, 0, 7, '');
        }
    }

    return $bitstring;
}

sub create_cl_dictionary (@cl_symbols) {

    my @keys;
    my $freq = frequencies(\@cl_symbols);

    while (1) {
        my ($cl_dict) = huffman_from_freq($freq);

        # The CL codes must have at most 7 bits
        return $cl_dict if all { length($_) <= 7 } values %$cl_dict;

        if (scalar(@keys) == 0) {
            @keys = sort { $freq->{$b} <=> $freq->{$a} } keys %$freq;
        }

        # Scale down the frequencies and try again
        foreach my $k (@keys) {
            if ($freq->{$k} > 1) {
                $freq->{$k} >>= 1;
            }
            else {
                last;
            }
        }
    }
}

sub block_type_2 ($literals, $distances, $lengths) {

    my @CL_order = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

    my $bitstring = '01';

    my @len_symbols;
    my @dist_symbols;
    my $offset_bits = '';

    foreach my $k (0 .. $#$literals) {

        if ($lengths->[$k] == 0) {
            push @len_symbols, $literals->[$k];
            next;
        }

        my $len  = $lengths->[$k];
        my $dist = $distances->[$k];

        {
            my $len_idx = $LENGTH_INDICES->[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};

            push @len_symbols, [$len_idx + 256 - 1, $bits];
            $offset_bits .= int2bits_lsb($len - $min, $bits) if ($bits > 0);
        }

        {
            my $dist_idx = find_deflate_index($dist, $DISTANCE_SYMBOLS);
            my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};

            push @dist_symbols, [$dist_idx - 1, $bits];
            $offset_bits .= int2bits_lsb($dist - $min, $bits) if ($bits > 0);
        }
    }

    push @len_symbols, 256;    # end-of-block marker

    my ($dict)      = huffman_from_symbols([map { ref($_) eq 'ARRAY' ? $_->[0] : $_ } @len_symbols]);
    my ($dist_dict) = huffman_from_symbols([map { $_->[0] } @dist_symbols]);

    my ($LL_code_lengths,       $LL_cl_len,       $LL_offset_bits)       = code_length_encoding($dict);
    my ($distance_code_lengths, $distance_cl_len, $distance_offset_bits) = code_length_encoding($dist_dict);

    my $cl_dict = create_cl_dictionary(@$LL_code_lengths, @$distance_code_lengths);

    my @CL_code_lenghts;
    foreach my $symbol (0 .. 18) {
        if (exists($cl_dict->{$symbol})) {
            push @CL_code_lenghts, length($cl_dict->{$symbol});
        }
        else {
            push @CL_code_lenghts, 0;
        }
    }

    # Put the CL codes in the required order
    @CL_code_lenghts = @CL_code_lenghts[@CL_order];

    while (scalar(@CL_code_lenghts) > 4 and $CL_code_lenghts[-1] == 0) {
        pop @CL_code_lenghts;
    }

    my $CL_code_lengths_bitstring = join('', map { int2bits_lsb($_, 3) } @CL_code_lenghts);

    my $LL_code_lengths_bitstring       = cl_encoded_bitstring($cl_dict, $LL_code_lengths,       $LL_offset_bits);
    my $distance_code_lengths_bitstring = cl_encoded_bitstring($cl_dict, $distance_code_lengths, $distance_offset_bits);

    # (5 bits) HLIT = (number of LL code entries present) - 257
    my $HLIT = $LL_cl_len - 257;

    # (5 bits) HDIST = (number of distance code entries present) - 1
    my $HDIST = $distance_cl_len - 1;

    # (4 bits) HCLEN = (number of CL code entries present) - 4
    my $HCLEN = scalar(@CL_code_lenghts) - 4;

    $bitstring .= int2bits_lsb($HLIT,  5);
    $bitstring .= int2bits_lsb($HDIST, 5);
    $bitstring .= int2bits_lsb($HCLEN, 4);

    $bitstring .= $CL_code_lengths_bitstring;
    $bitstring .= $LL_code_lengths_bitstring;
    $bitstring .= $distance_code_lengths_bitstring;

    foreach my $symbol (@len_symbols) {
        if (ref($symbol) eq 'ARRAY') {

            my ($len, $len_offset) = @$symbol;
            $bitstring .= $dict->{$len};
            $bitstring .= substr($offset_bits, 0, $len_offset, '') if ($len_offset > 0);

            my ($dist, $dist_offset) = @{shift(@dist_symbols)};
            $bitstring .= $dist_dict->{$dist};
            $bitstring .= substr($offset_bits, 0, $dist_offset, '') if ($dist_offset > 0);
        }
        else {
            $bitstring .= $dict->{$symbol};
        }
    }

    return $bitstring;
}

sub block_type_1 ($literals, $distances, $lengths) {

    state $dict;
    state $dist_dict;

    if (!defined($dict)) {

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

        ($dict)      = huffman_from_code_lengths(\@code_lengths);
        ($dist_dict) = huffman_from_code_lengths([(5) x 32]);
    }

    my $bitstring = '10';

    foreach my $k (0 .. $#$literals) {

        if ($lengths->[$k] == 0) {
            $bitstring .= $dict->{$literals->[$k]};
            next;
        }

        my $len  = $lengths->[$k];
        my $dist = $distances->[$k];

        {
            my $len_idx = $LENGTH_INDICES->[$len];
            my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};

            $bitstring .= $dict->{$len_idx + 256 - 1};
            $bitstring .= int2bits_lsb($len - $min, $bits) if ($bits > 0);
        }

        {
            my $dist_idx = find_deflate_index($dist, $DISTANCE_SYMBOLS);
            my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};

            $bitstring .= $dist_dict->{$dist_idx - 1};
            $bitstring .= int2bits_lsb($dist - $min, $bits) if ($bits > 0);
        }
    }

    $bitstring .= $dict->{256};    # end-of-block symbol

    return $bitstring;
}

sub block_type_0($chunk) {

    my $chunk_len = length($chunk);
    my $len       = int2bits_lsb($chunk_len,             16);
    my $nlen      = int2bits_lsb((~$chunk_len) & 0xffff, 16);

    $len . $nlen;
}

sub my_gzip_compress ($in_fh, $out_fh) {

    print $out_fh $MAGIC, $CM, $FLAGS, $MTIME, $XFLAGS, $OS;

    my $total_length = 0;
    my $crc32        = 0;

    my $bitstring = '';

    if (eof($in_fh)) {    # empty file
        $bitstring = '1' . '10' . '0000000';
    }

    while (read($in_fh, (my $chunk), CHUNK_SIZE)) {

        $crc32 = crc32($chunk, $crc32);
        $total_length += length($chunk);

        my ($literals, $distances, $lengths) = lzss_encode($chunk);

        $bitstring .= eof($in_fh) ? '1' : '0';

        my $bt1_bitstring = block_type_1($literals, $distances, $lengths);

        # When block type 1 is larger than the input, then we have random uncompressible data: use block type 0
        if ((length($bt1_bitstring) >> 3) > length($chunk) + 5) {

            say STDERR ":: Using block type: 0";

            $bitstring .= '00';

            print $out_fh pack('b*', $bitstring);             # pads to a byte
            print $out_fh pack('b*', block_type_0($chunk));
            print $out_fh $chunk;

            $bitstring = '';
            next;
        }

        my $bt2_bitstring = block_type_2($literals, $distances, $lengths);

        # When block type 2 is larger than block type 1, then we may have very small data
        if (length($bt2_bitstring) > length($bt1_bitstring)) {
            say STDERR ":: Using block type: 1";
            $bitstring .= $bt1_bitstring;
        }
        else {
            say STDERR ":: Using block type: 2";
            $bitstring .= $bt2_bitstring;
        }

        print $out_fh pack('b*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));
    }

    if ($bitstring ne '') {
        print $out_fh pack('b*', $bitstring);
    }

    print $out_fh pack('b*', int2bits_lsb($crc32,        32));
    print $out_fh pack('b*', int2bits_lsb($total_length, 32));

    return 1;
}

###################
# GZIP DECOMPRESSOR
###################

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

                if ($dist == 1) {
                    $$search_window .= substr($$search_window, -1) x $length;
                }
                elsif ($dist >= $length) {    # non-overlapping matches
                    $$search_window .= substr($$search_window, length($$search_window) - $dist, $length);
                }
                else {                        # overlapping matches
                    foreach my $i (1 .. $length) {
                        $$search_window .= substr($$search_window, length($$search_window) - $dist, 1);
                    }
                }

                $data .= substr($$search_window, -$length);
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

sub my_gzip_decompress ($in_fh, $out_fh) {

    my $MAGIC = (getc($in_fh) // die "error") . (getc($in_fh) // die "error");

    if ($MAGIC ne pack('C*', 0x1f, 0x8b)) {
        die "Not a valid Gzip container!\n";
    }

    my $CM     = getc($in_fh) // die "error";                             # 0x08 = DEFLATE
    my $FLAGS  = ord(getc($in_fh) // die "error");                        # flags
    my $MTIME  = join('', map { getc($in_fh) // die "error" } 1 .. 4);    # modification time
    my $XFLAGS = getc($in_fh) // die "error";                             # extra flags
    my $OS     = getc($in_fh) // die "error";                             # 0x03 = Unix

    if ($CM ne chr(0x08)) {
        die "Only DEFLATE compression method is supported (0x08)! Got: 0x", sprintf('%02x', ord($CM));
    }

    # Reference:
    #   https://web.archive.org/web/20240221024029/https://forensics.wiki/gzip/

    my $has_filename        = 0;
    my $has_comment         = 0;
    my $has_header_checksum = 0;
    my $has_extra_fields    = 0;

    if ($FLAGS & 0x08) {
        $has_filename = 1;
    }

    if ($FLAGS & 0x10) {
        $has_comment = 1;
    }

    if ($FLAGS & 0x02) {
        $has_header_checksum = 1;
    }

    if ($FLAGS & 0x04) {
        $has_extra_fields = 1;
    }

    if ($has_extra_fields) {
        my $size = bytes2int_lsb($in_fh, 2);
        read($in_fh, (my $extra_field_data), $size) // die "can't read extra field data: $!";
        say STDERR ":: Extra field data: $extra_field_data";
    }

    if ($has_filename) {
        my $filename = read_null_terminated($in_fh);    # filename
        say STDERR ":: Filename: $filename";
    }

    if ($has_comment) {
        my $comment = read_null_terminated($in_fh);     # comment
        say STDERR ":: Comment: $comment";
    }

    if ($has_header_checksum) {
        my $header_checksum = bytes2int_lsb($in_fh, 2);
        say STDERR ":: Header checksum: $header_checksum";
    }

    my $crc32         = 0;
    my $actual_length = 0;
    my $buffer        = '';
    my $search_window = '';
    my $window_size   = $Compression::Util::LZ_MAX_DIST;

    while (1) {

        my $is_last    = read_bit_lsb($in_fh, \$buffer);
        my $block_type = bits2int_lsb($in_fh, 2, \$buffer);

        my $chunk = '';

        if ($block_type == 0) {
            say STDERR "\n:: Extracting block of type 0";
            $buffer = '';                                       # pad to a byte
            $chunk  = extract_block_type_0($in_fh, \$buffer);
            $search_window .= $chunk;
        }
        elsif ($block_type == 1) {
            say STDERR "\n:: Extracting block of type 1";
            $chunk = extract_block_type_1($in_fh, \$buffer, \$search_window);
        }
        elsif ($block_type == 2) {
            say STDERR "\n:: Extracting block of type 2";
            $chunk = extract_block_type_2($in_fh, \$buffer, \$search_window);
        }
        else {
            die "[!] Unknown block of type: $block_type";
        }

        print $out_fh $chunk;
        $crc32 = crc32($chunk, $crc32);
        $actual_length += length($chunk);
        $search_window = substr($search_window, -$window_size) if (length($search_window) > 2 * $window_size);

        last if $is_last;
    }

    $buffer = '';    # discard any padding bits

    my $stored_crc32 = bits2int_lsb($in_fh, 32, \$buffer);
    my $actual_crc32 = $crc32;

    say STDERR '';

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
        __SUB__->($in_fh, $out_fh);
    }
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

        my_gzip_decompress($in_fh, $out_fh)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;

        open my $in_fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";

        open my $out_fh, '>:raw', $output
          or die "Can't open file <<$output>> for writing: $!";

        my_gzip_compress($in_fh, $out_fh)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

main();
exit(0);
