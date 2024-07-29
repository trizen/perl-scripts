#!/usr/bin/perl

# Author: Trizen
# Date: 07 September 2023
# Edit: 11 April 2024
# https://github.com/trizen

# Compress/decompress files using LZ77 compression + DEFLATE integers encoding + Burrows-Wheeler Transform (BWT) + Huffman coding.

# References:
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A
#
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ

use 5.036;
use Getopt::Std       qw(getopts);
use File::Basename    qw(basename);
use Compression::Util qw(:all);

use constant {
    PKGNAME => 'LZBWH',
    VERSION => '0.01',
    FORMAT  => 'lzbwh',

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

    my $lengths_str      = '';
    my $matches_str      = '';
    my $uncompressed_str = '';

    my @sizes;
    my @distances_block;

    open my $uc_fh,    '>:raw', \$uncompressed_str;
    open my $len_fh,   '>:raw', \$lengths_str;
    open my $match_fh, '>:raw', \$matches_str;

    my $create_bz2_block = sub {

        scalar(@sizes) > 0 or return;

        print $out_fh delta_encode(\@sizes);
        print $out_fh bwt_compress($uncompressed_str);
        print $out_fh bwt_compress($lengths_str);
        print $out_fh bwt_compress($matches_str);
        print $out_fh bwt_compress(obh_encode(\@distances_block));

        @sizes           = ();
        @distances_block = ();

        open $uc_fh,    '>:raw', \$uncompressed_str;
        open $len_fh,   '>:raw', \$lengths_str;
        open $match_fh, '>:raw', \$matches_str;
    };

    # Compress data
    while (read($fh, (my $chunk), CHUNK_SIZE)) {

        my ($literals, $lengths, $matches, $distances) = lz77_encode($chunk);

        my $est_ratio = length($chunk) / (4 * scalar(@$literals));
        say "Est. ratio: ", $est_ratio, " (", scalar(@$literals), " uncompressed bytes)";

        push(@sizes, scalar(@$literals), scalar(@$lengths), scalar(@$matches), scalar(@$distances));
        print $uc_fh pack('C*', @$literals);
        print $len_fh pack('C*', @$lengths);
        print $match_fh pack('C*', @$matches);
        push @distances_block, @$distances;

        if (length($uncompressed_str) >= CHUNK_SIZE) {
            $create_bz2_block->();
        }
    }

    $create_bz2_block->();
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

        my @sizes = @{delta_decode($fh)};

        my @uncompressed = unpack('C*', bwt_decompress($fh));
        my @lengths      = unpack('C*', bwt_decompress($fh));
        my @matches      = unpack('C*', bwt_decompress($fh));
        my @distances    = @{obh_decode(bwt_decompress($fh))};

        while (@uncompressed) {

            my $literals_size  = shift(@sizes) // die "decompression error";
            my $lengths_size   = shift(@sizes) // die "decompression error";
            my $matches_size   = shift(@sizes) // die "decompression error";
            my $distances_size = shift(@sizes) // die "decompression error";

            my @uncompressed_chunk = splice(@uncompressed, 0, $literals_size);
            my @lengths_chunk      = splice(@lengths,      0, $lengths_size);
            my @matches_chunk      = splice(@matches,      0, $matches_size);
            my @distances_chunk    = splice(@distances,    0, $distances_size);

            scalar(@uncompressed_chunk) == $literals_size or die "decompression error";
            scalar(@lengths_chunk) == $lengths_size       or die "decompression error";
            scalar(@matches_chunk) == $matches_size       or die "decompression error";
            scalar(@distances_chunk) == $distances_size   or die "decompression error";

            print $out_fh lz77_decode(\@uncompressed_chunk, \@lengths_chunk, \@matches_chunk, \@distances_chunk,);
        }
    }

    close $fh;
    close $out_fh;
}

main();
exit(0);
