#!/usr/bin/perl

# Author: Trizen
# Date: 13 January 2024
# Edit: 11 April 2024
# https://github.com/trizen

# Decompress GZIP files (.gz).

# Work in progress: only block type 0 is supported for now.

# Reference:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;
use Digest::CRC       qw();
use Compression::Util qw(:all);

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

sub extract_block_type_1 ($in_fh, $buffer) {

    state $rev_dict;

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

        (undef, $rev_dict) = huffman_from_code_lengths(\@code_lengths);
    }

    my $data = '';
    my $code = '';

    while (1) {
        $code .= read_bit_lsb($in_fh, $buffer);

        if (length($code) > 15) {
            die "[!] Something went wrong: size($code) > 15!\n";
        }

        if (exists($rev_dict->{$code})) {
            my $symbol = $rev_dict->{$code};
            if ($symbol <= 255) {
                $data .= chr($symbol);
            }
            elsif ($symbol == 256) {    # end-of-block marker
                last;
            }
            else {  # LZSS decoding
                say $data;
                ...;                    # TODO
            }
            $code = '';
        }
    }

    return $data;
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

    while (1) {

        my $is_last    = read_bit_lsb($in_fh, \$buffer);
        my $block_type = read_bit_lsb($in_fh, \$buffer) . read_bit_lsb($in_fh, \$buffer);

        my $chunk = '';

        if ($block_type eq '00') {
            print STDERR ":: Extracting block of type 0\n";
            read_bit_lsb($in_fh, \$buffer) for (1 .. 5);    # padding
            $chunk = extract_block_type_0($in_fh, \$buffer);
        }
        elsif ($block_type eq '10') {
            print STDERR ":: Extracting block of type 1\n";
            $chunk = extract_block_type_1($in_fh, \$buffer);
        }
        elsif ($block_type eq '01') {
            print STDERR ":: Extracting block of type 2\n";
            ...;                                            # TODO
        }
        else {
            die "[!] Unknown block of type: $block_type";
        }

        print $out_fh $chunk;
        $crc32->add($chunk);
        $actual_length += length($chunk);

        last if $is_last;
    }

    $buffer = '';    # discard any padding bits

    my $stored_crc32 = bits2int_lsb($in_fh, 32, \$buffer);
    my $actual_crc32 = $crc32->digest;

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
        print STDERR "\n:: This is the end of the file!\n";
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
