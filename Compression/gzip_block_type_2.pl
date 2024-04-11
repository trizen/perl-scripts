#!/usr/bin/perl

# Author: Trizen
# Date: 13 January 2024
# Edit: 11 April 2024
# https://github.com/trizen

# Create a valid Gzip container, using DEFLATE's Block Type 2: LZSS + dynamic prefix codes.

# Reference:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;
use Digest::CRC       qw();
use File::Basename    qw(basename);
use Compression::Util qw(:all);
use List::Util        qw(all min max);

use constant {
              WINDOW_SIZE => 32_768,    # 2^15
             };

my $MAGIC  = pack('C*', 0x1f, 0x8b);    # magic MIME type
my $CM     = chr(0x08);                 # 0x08 = DEFLATE
my $FLAGS  = chr(0x00);                 # flags
my $MTIME  = pack('C*', (0x00) x 4);    # modification time
my $XFLAGS = chr(0x00);                 # extra flags
my $OS     = chr(0x03);                 # 0x03 = Unix

my $input  = $ARGV[0] // die "usage: $0 [input] [output.gz]\n";
my $output = $ARGV[1] // (basename($input) . '.gz');

sub int2bits ($value, $size = 32) {
    scalar reverse sprintf("%0*b", $size, $value);
}

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
                $offset_bits .= int2bits(min($run, 127), 7);
                $run -= 127;
            }

            if ($run >= 3 and $run < 11) {
                push @CL_symbols, 17;
                $run -= 3;
                $offset_bits .= int2bits(min($run, 7), 3);
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
            $offset_bits .= int2bits(min($run, 3), 2);
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

open my $in_fh, '<:raw', $input
  or die "Can't open file <<$input>> for reading: $!";

open my $out_fh, '>:raw', $output
  or die "Can't open file <<$output>> for writing: $!";

print $out_fh $MAGIC, $CM, $FLAGS, $MTIME, $XFLAGS, $OS;

my $total_length = 0;
my $crc32        = Digest::CRC->new(type => "crc32");

my $bitstring  = '';
my $block_type = '01';                                                                 # 00 = store; 10 = LZSS + Fixed codes; 01 = LZSS + Dynamic codes
my @CL_order   = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

my ($DISTANCE_SYMBOLS, $LENGTH_SYMBOLS, $LENGTH_INDICES) = make_deflate_tables(WINDOW_SIZE);

if (eof($in_fh)) {    # empty file
    $bitstring = '1' . '10' . '0000000';
}

while (read($in_fh, (my $chunk), WINDOW_SIZE)) {

    my $chunk_len    = length($chunk);
    my $is_last      = eof($in_fh) ? '1' : '0';
    my $block_header = join('', $is_last, $block_type);

    my ($literals, $distances, $lengths) = lzss_encode($chunk);

    my @len_symbols;
    my @dist_symbols;
    my $offset_bits = '';

    foreach my $k (0 .. $#$literals) {

        if ($lengths->[$k]) {
            my $len  = $lengths->[$k];
            my $dist = $distances->[$k];

            {
                my $len_idx = $LENGTH_INDICES->[$len];
                my ($min, $bits) = @{$LENGTH_SYMBOLS->[$len_idx]};

                push @len_symbols, [$len_idx + 256 - 1, $bits];
                $offset_bits .= int2bits($len - $min, $bits) if ($bits > 0);
            }

            {
                my $dist_idx = find_deflate_index($dist, $DISTANCE_SYMBOLS);
                my ($min, $bits) = @{$DISTANCE_SYMBOLS->[$dist_idx]};

                push @dist_symbols, [$dist_idx - 1, $bits];
                $offset_bits .= int2bits($dist - $min, $bits) if ($bits > 0);
            }
        }

        push @len_symbols, $literals->[$k];
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

    my $CL_code_lengths_bitstring = join('', map { int2bits($_, 3) } @CL_code_lenghts);

    my $LL_code_lengths_bitstring       = cl_encoded_bitstring($cl_dict, $LL_code_lengths,       $LL_offset_bits);
    my $distance_code_lengths_bitstring = cl_encoded_bitstring($cl_dict, $distance_code_lengths, $distance_offset_bits);

    # (5 bits) HLIT = (number of LL code entries present) - 257
    my $HLIT = $LL_cl_len - 257;

    # (5 bits) HDIST = (number of distance code entries present) - 1
    my $HDIST = $distance_cl_len - 1;

    # (4 bits) HCLEN = (number of CL code entries present) - 4
    my $HCLEN = scalar(@CL_code_lenghts) - 4;

    $block_header .= int2bits($HLIT,  5);
    $block_header .= int2bits($HDIST, 5);
    $block_header .= int2bits($HCLEN, 4);

    $block_header .= $CL_code_lengths_bitstring;
    $block_header .= $LL_code_lengths_bitstring;
    $block_header .= $distance_code_lengths_bitstring;

    $bitstring .= $block_header;

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

    print $out_fh pack('b*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));

    $crc32->add($chunk);
    $total_length += $chunk_len;
}

if ($bitstring ne '') {
    print $out_fh pack('b*', $bitstring);
}

print $out_fh pack('b*', int2bits($crc32->digest, 32));
print $out_fh pack('b*', int2bits($total_length,  32));

close $in_fh;
close $out_fh;
