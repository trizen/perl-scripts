#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 03 February 2025
# Edit: 04 February 2025
# https://github.com/trizen

# Basic implementation of a ZIP archiver. (WIP)

# Reference:
#   https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT

use 5.036;
use Compression::Util     qw(:all);
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile catdir);
use File::Basename        qw(dirname);
use File::Find            qw(find);

use constant {
              FORMAT     => 'zip',
              CHUNK_SIZE => (1 << 15) - 1,
             };

local $Compression::Util::LZ_MIN_LEN  = 4;        # minimum match length in LZ parsing
local $Compression::Util::LZ_MAX_LEN  = 258;      # maximum match length in LZ parsing
local $Compression::Util::LZ_MAX_DIST = 32768;    # maximum allowed back-reference distance in LZ parsing

binmode(STDOUT, ':raw');
binmode(STDIN,  ':raw');

my $OFFSET = 0;

sub zip_directory ($dir) {

    if (substr($dir, 0, -1) ne '/') {
        $dir .= '/';
    }

    print STDOUT int2bytes_lsb(0x04034b50,   4);    # header signature
    print STDOUT int2bytes_lsb(20,           2);    # version needed
    print STDOUT int2bytes_lsb(0,            2);    # general purpose bit
    print STDOUT int2bytes_lsb(0,            2);    # compression method (8 = DEFLATE)
    print STDOUT int2bytes_lsb(0,            2);    # last mod file time
    print STDOUT int2bytes_lsb(0,            2);    # last mod file date
    print STDOUT int2bytes_lsb(0,            4);    # CRC32
    print STDOUT int2bytes_lsb(0,            4);    # compressed size
    print STDOUT int2bytes_lsb(0,            4);    # uncompressed size
    print STDOUT int2bytes_lsb(length($dir), 2);    # filename length
    print STDOUT int2bytes_lsb(0,            2);    # extra field length

    print STDOUT $dir;

    my $info = {
                crc32              => 0,
                name               => $dir,
                compressed_size    => 0,
                uncompressed_size  => 0,
                compression_method => 0,
                offset             => $OFFSET,
               };

    $OFFSET += 4 * 4 + 2 * 7 + length($dir);

    return $info;
}

sub zip_file ($file) {

    if (-d $file) {
        return zip_directory($file);
    }

    print STDOUT int2bytes_lsb(0x04034b50,    4);    # header signature
    print STDOUT int2bytes_lsb(20,            2);    # version needed
    print STDOUT int2bytes_lsb(0b1000,        2);    # general purpose bit
    print STDOUT int2bytes_lsb(8,             2);    # compression method (8 = DEFLATE)
    print STDOUT int2bytes_lsb(0,             2);    # last mod file time
    print STDOUT int2bytes_lsb(0,             2);    # last mod file date
    print STDOUT int2bytes_lsb(0,             4);    # CRC32
    print STDOUT int2bytes_lsb(0,             4);    # compressed size
    print STDOUT int2bytes_lsb(0,             4);    # uncompressed size
    print STDOUT int2bytes_lsb(length($file), 2);    # filename length
    print STDOUT int2bytes_lsb(0,             2);    # extra field length

    print STDOUT $file;                              # filename

    my $crc32             = 0;
    my $uncompressed_size = 0;
    my $compressed_size   = 0;

    my $bitstring = '';

    open my $in_fh, '<:raw', $file;

    if (eof($in_fh)) {                               # empty file
        $bitstring = '1' . '10' . '0000000';
    }

    while (read($in_fh, (my $chunk), CHUNK_SIZE)) {

        $crc32 = crc32($chunk, $crc32);
        $uncompressed_size += length($chunk);

        my ($literals, $distances, $lengths) = lzss_encode($chunk);

        $bitstring .= eof($in_fh) ? '1' : '0';

        my $bt1_bitstring = deflate_create_block_type_1($literals, $distances, $lengths);

        # When block type 1 is larger than the input, then we have random uncompressible data: use block type 0
        if ((length($bt1_bitstring) >> 3) > length($chunk) + 5) {

            say STDERR ":: Using block type: 0";

            $bitstring .= '00';

            my $comp = pack('b*', $bitstring);    # pads to a byte
            $comp            .= pack('b*', deflate_create_block_type_0_header($chunk));
            $comp            .= $chunk;
            $compressed_size .= length($comp);
            print STDOUT $comp;

            $bitstring = '';
            next;
        }

        my $bt2_bitstring = deflate_create_block_type_2($literals, $distances, $lengths);

        # When block type 2 is larger than block type 1, then we may have very small data
        if (length($bt2_bitstring) > length($bt1_bitstring)) {
            say STDERR ":: Using block type: 1";
            $bitstring .= $bt1_bitstring;
        }
        else {
            say STDERR ":: Using block type: 2";
            $bitstring .= $bt2_bitstring;
        }

        my $comp = pack('b*', substr($bitstring, 0, length($bitstring) - (length($bitstring) % 8), ''));
        $compressed_size += length($comp);
        print STDOUT $comp;
    }

    if ($bitstring ne '') {
        my $comp = pack('b*', $bitstring);
        $compressed_size += length($comp);
        print STDOUT $comp;
    }

    print STDOUT int2bytes_lsb(0x8074b50,          4);
    print STDOUT int2bytes_lsb($crc32,             4);
    print STDOUT int2bytes_lsb($compressed_size,   4);
    print STDOUT int2bytes_lsb($uncompressed_size, 4);

    my $info = {
                compression_method => 8,
                crc32              => $crc32,
                name               => $file,
                compressed_size    => $compressed_size,
                uncompressed_size  => $uncompressed_size,
                offset             => $OFFSET,
               };

    $OFFSET += 4 * 8 + 2 * 7 + length($file) + $compressed_size;

    return $info;
}

sub central_directory($entry) {

    # FIXME: the offset of the local header is incorrect

    print STDOUT int2bytes_lsb(0x02014b50,                   4);    # header signature
    print STDOUT int2bytes_lsb(831,                          2);    # version made by
    print STDOUT int2bytes_lsb(20,                           2);    # version needed to extract
    print STDOUT int2bytes_lsb(0,                            2);    # general purpose bit
    print STDOUT int2bytes_lsb($entry->{compression_method}, 2);    # compression method
    print STDOUT int2bytes_lsb(0,                            2);    # last mod file time
    print STDOUT int2bytes_lsb(0,                            2);    # last mod file date
    print STDOUT int2bytes_lsb($entry->{crc32},              4);    # crc32
    print STDOUT int2bytes_lsb($entry->{compressed_size},    4);    # compressed size
    print STDOUT int2bytes_lsb($entry->{uncompressed_size},  4);    # uncompressed size
    print STDOUT int2bytes_lsb(length($entry->{name}),       2);    # file name length
    print STDOUT int2bytes_lsb(0,                            2);    # extra field length
    print STDOUT int2bytes_lsb(0,                            2);    # file comment length
    print STDOUT int2bytes_lsb(0,                            2);    # disk number start
    print STDOUT int2bytes_lsb(0,                            2);    # internal file attributes
    print STDOUT int2bytes_lsb(0,                            4);    # external file attributes
    print STDOUT int2bytes_lsb($entry->{offset},             4);    # relative offset of local header (TODO)

    print STDOUT $entry->{name};
}

sub end_of_zip_file (@entries) {

    print STDOUT int2bytes_lsb(0x06054b50,       4);                # header signature
    print STDOUT int2bytes_lsb(0,                2);                # number of this disk
    print STDOUT int2bytes_lsb(0,                2);                # number of the disk central dir
    print STDOUT int2bytes_lsb(0,                2);                # start of central dir
    print STDOUT int2bytes_lsb(scalar(@entries), 2);                # total number of entries
    print STDOUT int2bytes_lsb(0,                4);                # size of the central directory
    print STDOUT int2bytes_lsb(0,                4);                # offset
    print STDOUT int2bytes_lsb(0,                2);                # zip file comment length
}

my @entries;

sub zip ($file) {
    find(
        {
         no_chdir => 1,
         wanted   => sub {
             push @entries, zip_file($_);
         }
        },
        $file
    );
}

zip($ARGV[0]);

#~ foreach my $entry(@entries) {
#~ central_directory($entry);
#~ }

#~ end_of_zip_file(@entries);
