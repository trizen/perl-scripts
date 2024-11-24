#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 20 November 2024
# https://github.com/trizen

# Basic implementation of a ZIP file extractor.

# Reference:
#   https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT

use 5.036;
use Compression::Util     qw(:all);
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile catdir);
use File::Basename        qw(dirname);

local $Compression::Util::LZ_MIN_LEN  = 4;        # minimum match length in LZ parsing
local $Compression::Util::LZ_MAX_LEN  = 258;      # maximum match length in LZ parsing
local $Compression::Util::LZ_MAX_DIST = 32768;    # maximum allowed back-reference distance in LZ parsing

my $output_directory = 'OUTPUT';

if (not -d $output_directory) {
    make_path($output_directory);
}

sub extract_file($fh) {

    my $version_needed           = bytes2int_lsb($fh, 2);
    my $general_purpose_bit_flag = bytes2int_lsb($fh, 2);
    my $compression_method       = bytes2int_lsb($fh, 2);

    my $last_mod_file_time = bytes2int_lsb($fh, 2);
    my $last_mod_file_date = bytes2int_lsb($fh, 2);
    my $crc32              = bytes2int_lsb($fh, 4);
    my $compressed_size    = bytes2int_lsb($fh, 4);
    my $uncompressed_size  = bytes2int_lsb($fh, 4);
    my $file_name_length   = bytes2int_lsb($fh, 2);
    my $extra_field_length = bytes2int_lsb($fh, 2);

    my $skip_crc32 = 0;

    if ($general_purpose_bit_flag & 0b1000) {
        $skip_crc32 = 1;
        $crc32 == 0             or warn "[WARNING] Bit 3 is set, therefore CRC-32 must be set to zero (got: $crc32)\n";
        $compressed_size == 0   or warn "[WARNING] Bit 3 is set, thefore compressed size must be set to zero (got: $compressed_size)\n";
        $uncompressed_size == 0 or warn "[WARNING] Bit 3 is set, therefore uncompressed size must be set to zero (got: $uncompressed_size)\n";
    }

    read($fh, (my $file_name),   $file_name_length);
    read($fh, (my $extra_field), $extra_field_length);

    if ($general_purpose_bit_flag & 0x01) {
        die "Encrypted file are currently not supported!\n";
    }

    say STDERR ":: Extracting: $file_name ($uncompressed_size bytes)";

    # It's a directory
    if ($uncompressed_size == 0 and substr($file_name, -1) eq '/') {
        my $dir = catdir($output_directory, $file_name);
        make_path($dir) if not -d $dir;
        return 1;
    }

    my $out_filename = catfile($output_directory, $file_name);

    my $out_dir = dirname($out_filename);
    make_path($out_dir) if not -d $out_dir;

    open my $out_fh, '>:raw', $out_filename
      or die "Can't create file <<$out_filename>>: $!\n";

    my $actual_crc32             = 0;
    my $buffer                   = '';
    my $search_window            = '';
    my $actual_uncompressed_size = 0;

    if ($compression_method == 8) {    # DEFLATE method
        while (1) {
            my $is_last = read_bit_lsb($fh, \$buffer);
            my $chunk   = deflate_extract_next_block($fh, \$buffer, \$search_window);
            $actual_crc32 = crc32($chunk, $actual_crc32);
            $actual_uncompressed_size += length($chunk);
            print $out_fh $chunk;
            last if $is_last;
        }
    }
    elsif ($compression_method == 0) {    # uncompressed (stored)

        # TODO: do not read the entire content at once (read in small chunks)
        read($fh, (my $chunk), $uncompressed_size);
        $actual_crc32 = crc32($chunk);
        $actual_uncompressed_size += length($chunk);
        print $out_fh $chunk;
    }
    else {
        die "Unsupported compression method: $compression_method\n";
    }

    if (not $skip_crc32 and $crc32 != $actual_crc32) {
        die "CRC32 error: $crc32 (stored) != $actual_crc32 (actual)\n";
    }

    if ($general_purpose_bit_flag & 0b100) {    # TODO
        die "Data descriptor is currently not supported!\n";
    }

    if ($skip_crc32) {
        my $header_signature = bytes2int_lsb($fh, 4);
        if ($header_signature == 0x8074b50) {

            my $stored_crc32      = bytes2int_lsb($fh, 4);
            my $compressed_size   = bytes2int_lsb($fh, 4);
            my $uncompressed_size = bytes2int_lsb($fh, 4);

            if ($stored_crc32 != $actual_crc32) {
                die "CRC32 error: $stored_crc32 (stored) != $actual_crc32 (actual)\n";
            }

            if ($uncompressed_size != $actual_uncompressed_size) {
                die "Uncompressed size error: $uncompressed_size (stored) != $actual_uncompressed_size (actual)\n";
            }
        }
        else {
            die "Unknown signature: $header_signature\n";
        }
    }

    close $out_fh;
    return $actual_crc32;
}

sub extract_central_directory($fh) {    # TODO

    my $version_made_by                 = bytes2int_lsb($fh, 2);
    my $version_needed_to_extract       = bytes2int_lsb($fh, 2);
    my $general_purpose_bit_flag        = bytes2int_lsb($fh, 2);
    my $compression_method              = bytes2int_lsb($fh, 2);
    my $last_mod_file_time              = bytes2int_lsb($fh, 2);
    my $last_mod_file_date              = bytes2int_lsb($fh, 2);
    my $crc_32                          = bytes2int_lsb($fh, 4);
    my $compressed_size                 = bytes2int_lsb($fh, 4);
    my $uncompressed_size               = bytes2int_lsb($fh, 4);
    my $file_name_length                = bytes2int_lsb($fh, 2);
    my $extra_field_length              = bytes2int_lsb($fh, 2);
    my $file_comment_length             = bytes2int_lsb($fh, 2);
    my $disk_number_start               = bytes2int_lsb($fh, 2);
    my $internal_file_attributes        = bytes2int_lsb($fh, 2);
    my $external_file_attributes        = bytes2int_lsb($fh, 4);
    my $relative_offset_of_local_header = bytes2int_lsb($fh, 4);

    read($fh, (my $file_name),    $file_name_length);
    read($fh, (my $extra_field),  $extra_field_length);
    read($fh, (my $file_comment), $file_comment_length);
}

sub extract_end_of_file ($fh) {    # TODO

    my $number_of_this_disk            = bytes2int_lsb($fh, 2);
    my $number_of_the_disk_central_dir = bytes2int_lsb($fh, 2);
    my $start_of_central_dir           = bytes2int_lsb($fh, 2);
    my $total_number_of_entries        = bytes2int_lsb($fh, 2);
    my $size_of_the_central_directory  = bytes2int_lsb($fh, 4);
    my $offset                         = bytes2int_lsb($fh, 4);
    my $ZIP_file_comment_length        = bytes2int_lsb($fh, 2);

    read($fh, (my $ZIP_file_comment), $ZIP_file_comment_length);
}

sub unzip($file) {

    open my $fh, '<:raw', $file
      or die "Can't open file <<$file>> for reading: $!";

    while (!eof($fh)) {
        my $header_signature = bytes2int_lsb($fh, 4);

        if ($header_signature == 0x04034b50) {
            extract_file($fh);
        }
        elsif ($header_signature == 0x02014b50) {
            extract_central_directory($fh);
        }
        elsif ($header_signature == 0x05054b50) {    # TODO
            die "Digital signature is currently not supported!\n";
        }
        elsif ($header_signature == 0x06064b50) {    # TODO
            die "ZIP64 is currently not supported!\n";
        }
        elsif ($header_signature == 0x08064b50) {    # TODO
            die "Extra data record is currently not supported!\n";
        }
        elsif ($header_signature == 0x06054b50) {
            extract_end_of_file($fh);
        }
        else {
            die "Unknown header signature: $header_signature\n";
        }
    }
}

my $input_file = $ARGV[0];
unzip($input_file);
