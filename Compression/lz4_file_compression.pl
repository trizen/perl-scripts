#!/usr/bin/perl

# Author: Trizen
# Date: 25 August 2024
# https://github.com/trizen

# A valid LZ4 file compressor/decompressor.

# References:
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md

use 5.036;
use File::Basename    qw(basename);
use Compression::Util qw(:all);
use Getopt::Std       qw(getopts);

binmode(STDIN,  ":raw");
binmode(STDOUT, ":raw");

use constant {
              FORMAT     => 'lz4',
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

sub my_lz4_compress($fh, $out_fh) {

    my $compressed = '';

    $compressed .= int2bytes_lsb(0x184D2204, 4);    # LZ4 magic number

    my $fd = '';                                    # frame description
    $fd .= chr(0b01_10_00_00);                      # flags (FLG)
    $fd .= chr(0b0_111_0000);                       # block description (BD)

    $compressed .= $fd;

    # Header Checksum
    if (eval { require Digest::xxHash; 1 }) {
        $compressed .= chr((Digest::xxHash::xxhash32($fd, 0) >> 8) & 0xFF);
    }
    else {
        $compressed .= chr(115);
    }

    while (!eof($fh)) {

        read($fh, (my $chunk), CHUNK_SIZE);

        my ($literals, $distances, $lengths) = do {
            local $Compression::Util::LZ_MIN_LEN       = 4;                # minimum match length
            local $Compression::Util::LZ_MAX_LEN       = ~0;               # maximum match length
            local $Compression::Util::LZ_MAX_DIST      = (1 << 16) - 1;    # maximum match distance
            local $Compression::Util::LZ_MAX_CHAIN_LEN = 32;               # higher value = better compression
            lzss_encode(substr($chunk, 0, -5));
        };

        # The last 5 bytes of each block must be literals
        # https://github.com/lz4/lz4/issues/1495
        push @$literals, unpack('C*', substr($chunk, -5));

        my $literals_end = $#{$literals};

        my $block = '';

        for (my $i = 0 ; $i <= $literals_end ; ++$i) {

            my @uncompressed;
            while ($i <= $literals_end and defined($literals->[$i])) {
                push @uncompressed, $literals->[$i];
                ++$i;
            }

            my $literals_string = pack('C*', @uncompressed);
            my $literals_length = scalar(@uncompressed);

            my $match_len = $lengths->[$i] ? ($lengths->[$i] - 4) : 0;

            my $len_byte = 0;

            $len_byte |= ($literals_length >= 15 ? 15 : $literals_length) << 4;
            $len_byte |= ($match_len >= 15       ? 15 : $match_len);

            $literals_length -= 15;
            $match_len       -= 15;

            $block .= chr($len_byte);

            while ($literals_length >= 0) {
                $block .= ($literals_length >= 255 ? "\xff" : chr($literals_length));
                $literals_length -= 255;
            }

            $block .= $literals_string;

            my $dist = $distances->[$i] // last;
            $block .= pack('b*', scalar reverse sprintf('%016b', $dist));

            while ($match_len >= 0) {
                $block .= ($match_len >= 255 ? "\xff" : chr($match_len));
                $match_len -= 255;
            }
        }

        if ($block ne '') {
            $compressed .= int2bytes_lsb(length($block), 4);
            $compressed .= $block;
        }

        print $out_fh $compressed;
        $compressed = '';
    }

    print $out_fh int2bytes_lsb(0x00000000, 4);    # EndMark
    return 1;
}

sub my_lz4_decompress($fh, $out_fh) {
    while (!eof($fh)) {

        bytes2int_lsb($fh, 4) == 0x184D2204 or die "Not an LZ4 file\n";

        my $FLG = ord(getc($fh));
        my $BD  = ord(getc($fh));

        my $version    = $FLG & 0b11_00_00_00;
        my $B_indep    = $FLG & 0b00_10_00_00;
        my $B_checksum = $FLG & 0b00_01_00_00;
        my $C_size     = $FLG & 0b00_00_10_00;
        my $C_checksum = $FLG & 0b00_00_01_00;
        my $DictID     = $FLG & 0b00_00_00_01;

        my $Block_MaxSize = $BD & 0b0_111_0000;

        say STDERR "Maximum block size: $Block_MaxSize";

        if ($version != 0b01_00_00_00) {
            die "Error: Invalid version number";
        }

        if ($C_size) {
            my $content_size = bytes2int_lsb($fh, 8);
            say STDERR "Content size: ", $content_size;
        }

        if ($DictID) {
            my $dict_id = bytes2int_lsb($fh, 4);
            say STDERR "Dictionary ID: ", $dict_id;
        }

        my $header_checksum = ord(getc($fh));

        my $decoded = '';

        while (!eof($fh)) {

            my $block_size = bytes2int_lsb($fh, 4);

            if ($block_size == 0x00000000) {    # signifies an EndMark
                say STDERR "Block size == 0";
                last;
            }

            say STDERR "Block size: $block_size";

            if ($block_size >> 31) {
                say STDERR "Highest bit set: ", $block_size;
                $block_size &= ((1 << 31) - 1);
                say STDERR "Block size: ", $block_size;
                my $uncompressed = '';
                read($fh, $uncompressed, $block_size);
                $decoded .= $uncompressed;
            }
            else {

                my $compressed = '';
                read($fh, $compressed, $block_size);

                while ($compressed ne '') {
                    my $len_byte = ord(substr($compressed, 0, 1, ''));

                    my $literals_length = $len_byte >> 4;
                    my $match_len       = $len_byte & 0b1111;

                    #say STDERR "Literal: ",   $literals_length;
                    #say STDERR "Match len: ", $match_len;

                    if ($literals_length == 15) {
                        while (1) {
                            my $byte_len = ord(substr($compressed, 0, 1, ''));
                            $literals_length += $byte_len;
                            last if $byte_len != 255;
                        }
                    }

                    #say STDERR "Total literals length: ", $literals_length;

                    my $literals = '';

                    if ($literals_length > 0) {
                        $literals = substr($compressed, 0, $literals_length, '');
                    }

                    if ($compressed eq '') {    # end of block
                        $decoded .= $literals;
                        last;
                    }

                    my $offset = oct('0b' . reverse unpack('b16', substr($compressed, 0, 2, '')));

                    if ($offset == 0) {
                        die "Corrupted block";
                    }

                    # say STDERR "Offset: $offset";

                    if ($match_len == 15) {
                        while (1) {
                            my $byte_len = ord(substr($compressed, 0, 1, ''));
                            $match_len += $byte_len;
                            last if $byte_len != 255;
                        }
                    }

                    $decoded .= $literals;
                    $match_len += 4;

                    # say STDERR "Total match len: $match_len\n";

                    if ($offset >= $match_len) {    # non-overlapping matches
                        $decoded .= substr($decoded, length($decoded) - $offset, $match_len);
                    }
                    elsif ($offset == 1) {
                        $decoded .= substr($decoded, -1) x $match_len;
                    }
                    else {                          # overlapping matches
                        foreach my $i (1 .. $match_len) {
                            $decoded .= substr($decoded, length($decoded) - $offset, 1);
                        }
                    }
                }
            }

            if ($B_checksum) {
                my $content_checksum = bytes2int_lsb($fh, 4);
                say STDERR "Block checksum: $content_checksum";
            }

            if ($B_indep) {    # blocks are independent of each other
                print $out_fh $decoded;
                $decoded = '';
            }
            elsif (length($decoded) > 2**16) {    # blocks are dependent
                print $out_fh substr($decoded, 0, -(2**16), '');
            }
        }

        if ($C_checksum) {
            my $content_checksum = bytes2int_lsb($fh, 4);
            say STDERR "Content checksum: $content_checksum";
        }

        print $out_fh $decoded;
    }
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

        my_lz4_decompress($in_fh, $out_fh)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;

        open my $in_fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";

        open my $out_fh, '>:raw', $output
          or die "Can't open file <<$output>> for writing: $!";

        my_lz4_compress($in_fh, $out_fh)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

main();
exit(0);
