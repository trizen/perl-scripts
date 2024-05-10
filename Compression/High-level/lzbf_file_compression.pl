#!/usr/bin/perl

# Author: Trizen
# Date: 10 May 2024
# https://github.com/trizen

# Compress/decompress files using LZ77 compression (LZSS variant with hash tables -- fast variant), using a byte-aligned encoding, similar to LZ4.

# References:
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md
#   https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);
use List::Util        qw(min);

use constant {
    PKGNAME => 'LZBF',
    VERSION => '0.01',
    FORMAT  => 'lzbf',

    CHUNK_SIZE => 1 << 16,    # higher value = better compression
};

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
    my ($literals, $distances, $lengths) = lzss_encode_fast($chunk);

    my $literals_end = $#{$literals};

    for (my $i = 0 ; $i <= $literals_end ; ++$i) {

        my @uncompressed;
        while ($i <= $literals_end and defined($literals->[$i])) {
            push @uncompressed, $literals->[$i];
            ++$i;
        }

        my $literals_string = pack('C*', @uncompressed);
        my $literals_length = scalar(@uncompressed);

        my $dist      = $distances->[$i] // 0;
        my $match_len = $lengths->[$i]   // 0;

        my $len_byte = '';

        if ($literals_length >= 15) {
            $len_byte .= '1111';
            $literals_length -= 15;
        }
        else {
            $len_byte .= sprintf('%04b', $literals_length);
            $literals_length -= 15;
        }

        if ($match_len >= 15) {
            $len_byte .= '1111';
            $match_len -= 15;
        }
        else {
            $len_byte .= sprintf('%04b', $match_len);
            $match_len -= 15;
        }

        print $out_fh chr(oct('0b' . $len_byte));

        while ($literals_length >= 0) {
            print $out_fh chr(min($literals_length, 255));
            $literals_length -= 255;
        }

        print $out_fh $literals_string;

        while ($match_len >= 0) {
            print $out_fh chr(min($match_len, 255));
            $match_len -= 255;
        }

        if ($dist >= 1 << 16) {
            die "Too large distance: $dist";
        }

        print $out_fh pack('B*', int2bits($dist, 16));
    }

}

sub decompression($fh, $out_fh) {

    my $buffer        = '';
    my $search_window = '';

    while (!eof($fh)) {

        my $len_byte = ord(getc($fh));

        my $literals_length = $len_byte >> 4;
        my $match_len       = $len_byte & 0b1111;

        if ($literals_length == 15) {
            while (1) {
                my $byte_len = ord(getc($fh));
                $literals_length += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $literals = '';
        if ($literals_length > 0) {
            read($fh, $literals, $literals_length);
        }

        if ($match_len == 15) {
            while (1) {
                my $byte_len = ord(getc($fh));
                $match_len += $byte_len;
                last if $byte_len != 255;
            }
        }

        my $offset = bits2int($fh, 16, \$buffer);

        print $out_fh $literals;
        $search_window .= $literals;

        my $data = '';
        foreach my $i (1 .. $match_len) {
            my $str = substr($search_window, length($search_window) - $offset, 1);
            $search_window .= $str;
            $data          .= $str;
        }

        print $out_fh $data;
        $search_window = substr($search_window, -CHUNK_SIZE) if (length($search_window) > CHUNK_SIZE);
    }
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
