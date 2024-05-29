#!/usr/bin/perl

# Author: Trizen
# Date: 24 May 2024
# https://github.com/trizen

# Compress/decompress files using LZ77 compression (LZSS variant with hash tables), using ideas from LZ4, combined with Huffman Coding.

# References:
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'LZBH',
    VERSION => '0.01',
    FORMAT  => 'lzbh',

    CHUNK_SIZE => 1 << 18,    # higher value = better compression
};

local $Compression::Util::LZ_MIN_LEN       = 4;     # minimum match length
local $Compression::Util::LZ_MAX_LEN       = ~0;    # maximum match length
local $Compression::Util::LZ_MAX_CHAIN_LEN = 32;    # higher value = better compression

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(1);

sub usage {
    my ($code) = @_;
    print <<"EOH";
usage: $0 [options] [input file] [output file]

options:
        -e            : extract
        -i <filename> : input filename
        -o <filename> : output filename
        -r            : rewrite output

        -v            : version number
        -h            : this message

examples:
         $0 document.txt
         $0 document.txt archive.${\FORMAT}
         $0 archive.${\FORMAT} document.txt
         $0 -e -i archive.${\FORMAT} -o document.txt

EOH

    exit($code // 0);
}

sub version {
    printf("%s %s\n", PKGNAME, VERSION);
    exit;
}

sub valid_archive {
    my ($fh) = @_;

    if (read($fh, (my $sig), length(SIGNATURE), 0) == length(SIGNATURE)) {
        $sig eq SIGNATURE || return;
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

        decompress_file($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        compress_file($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

sub compression($chunk, $out_fh) {
    my ($literals, $distances, $lengths) = lzss_encode($chunk);

    my $literals_end = $#{$literals};
    my @symbols;
    my @len_symbols;
    my @match_symbols;
    my @dist_symbols;

    for (my $i = 0 ; $i <= $literals_end ; ++$i) {

        my $j = $i;
        while ($i <= $literals_end and defined($literals->[$i])) {
            ++$i;
        }

        my $literals_length = $i - $j;

        my $dist      = $distances->[$i] // 0;
        my $match_len = $lengths->[$i]   // 0;

        my $len_byte = 0;

        $len_byte |= ($literals_length >= 7 ? 7  : $literals_length) << 5;
        $len_byte |= ($match_len >= 31      ? 31 : $match_len);

        $literals_length -= 7;
        $match_len       -= 31;

        push @match_symbols, $len_byte;

        while ($literals_length >= 0) {
            push @len_symbols, ($literals_length >= 255 ? 255 : $literals_length);
            $literals_length -= 255;
        }
        push @symbols, @{$literals}[$j .. $i - 1];

        while ($match_len >= 0) {
            push @match_symbols, ($match_len >= 255 ? 255 : $match_len);
            $match_len -= 255;
        }

        push @dist_symbols, $dist;
    }

    print $out_fh create_huffman_entry(\@symbols);
    print $out_fh delta_encode(\@len_symbols);
    print $out_fh create_huffman_entry(\@match_symbols);
    print $out_fh obh_encode(\@dist_symbols);
}

sub decompression($fh, $out_fh) {

    my $data          = '';
    my $symbols       = decode_huffman_entry($fh);
    my $len_symbols   = delta_decode($fh);
    my $match_symbols = decode_huffman_entry($fh);
    my $dist_symbols  = obh_decode($fh);

    while (@$symbols) {

        my $len_byte = shift(@$match_symbols);

        my $literals_length = $len_byte >> 5;
        my $match_len       = $len_byte & 0b11111;

        if ($literals_length == 7) {
            while (1) {
                my $byte_len = shift(@$len_symbols);
                $literals_length += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $literals = '';
        if ($literals_length > 0) {
            $literals = pack("C*", splice(@$symbols, 0, $literals_length));
        }

        if ($match_len == 31) {
            while (1) {
                my $byte_len = shift(@$match_symbols);
                $match_len += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $offset = shift(@$dist_symbols);

        $data .= $literals;

        if ($offset == 1) {
            $data .= substr($data, -1) x $match_len;
        }
        elsif ($offset >= $match_len) {
            $data .= substr($data, length($data) - $offset, $match_len);
        }
        else {
            foreach my $i (1 .. $match_len) {
                $data .= substr($data, length($data) - $offset, 1);
            }
        }
    }
    print $out_fh $data;
}

# Compress file
sub compress_file ($input, $output) {

    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    my $header = SIGNATURE;

    # Open the output file for writing
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for write: $!";

    # Print the header
    print $out_fh $header;

    # Compress data
    while (read($fh, (my $chunk), CHUNK_SIZE)) {
        compression($chunk, $out_fh);
    }

    # Close the file
    close $out_fh;
}

# Decompress file
sub decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input
      or die "Can't open file <<$input>> for reading: $!";

    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for writing: $!";

    while (!eof($fh)) {
        decompression($fh, $out_fh);
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
