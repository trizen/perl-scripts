#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 09 November 2024
# https://github.com/trizen

# Compress/decompress files using SWAP transform + LZB + Burrows-Wheeler Transform (BWT) + Move-to-Front Transform + Run-length encoding + Huffman coding.

# Reference:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);
use POSIX             qw(ceil);

use constant {
    PKGNAME => 'SBWT',
    VERSION => '0.01',
    FORMAT  => 'sbwt',

    CHUNK_SIZE => 1 << 17,
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

sub swap_transform ($text, $extra = 1) {

    my @bits;
    my @arr = unpack('C*', $text);
    my $k   = 0;

    foreach my $i (1 .. $#arr) {
        if ($arr[$i] < $arr[$i - 1 - $k]) {
            push @bits, 1;
            unshift @arr, splice(@arr, $i, 1);
            ++$k if $extra;
        }
        else {
            push @bits, 0;
        }
    }

    return (pack('C*', @arr), \@bits);
}

sub reverse_swap_transform ($text, $bits) {
    my @arr = unpack('C*', $text);

    for (my $i = $#arr ; $i >= 0 ; --$i) {
        if ($bits->[$i - 1] == 1) {
            splice(@arr, $i, 0, shift(@arr));
        }
    }

    pack('C*', @arr);
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

        local $Compression::Util::LZ_MIN_LEN = 512;
        my ($t, $bits) = swap_transform(lzb_compress($chunk, \&lzss_encode_fast), 0);
        my $vrle_bits = binary_vrl_encode(join('', @$bits));

        if (length($vrle_bits) < scalar @$bits) {
            say STDERR "With VLRE: ", length($vrle_bits), " < ", scalar(@$bits);
            print $out_fh chr(1);
        }
        else {
            say STDERR "Without VRLE: ", length($vrle_bits), " > ", scalar(@$bits);
            $vrle_bits = join('', @$bits);
            print $out_fh chr(0);
        }

        print $out_fh pack('N', length $vrle_bits);

        my ($bwt, $idx) = bwt_encode($t);
        print $out_fh pack('B*', $vrle_bits);

        my ($mtf, $alphabet) = mtf_encode(string2symbols($bwt));
        my $rle = zrle_encode($mtf);
        print $out_fh (pack('N', $idx) . encode_alphabet($alphabet) . create_huffman_entry($rle));
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

        my $with_vrle = ord(getc($fh));
        my $bits_len  = bytes2int($fh, 4);
        my $bits      = read_bits($fh, $bits_len);

        $bits = binary_vrl_decode($bits) if $with_vrle;

        my $idx      = bytes2int($fh, 4);
        my $alphabet = decode_alphabet($fh);

        my $rle  = decode_huffman_entry($fh);
        my $mtf  = zrle_decode($rle);
        my $bwt  = mtf_decode($mtf, $alphabet);
        my $data = bwt_decode(pack('C*', @$bwt), $idx);

        print $out_fh lzb_decompress(reverse_swap_transform($data, [split(//, $bits)]));
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
