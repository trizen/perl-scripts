#!/usr/bin/perl

# A general purpose lossless compressor, based on ideas from the QOI compressor. (+BWT)

# See also:
#   https://qoiformat.org/

use 5.036;
use File::Basename    qw(basename);
use Compression::Util qw(:all);
use List::Util        qw(max);
use Getopt::Std       qw(getopts);

binmode(STDIN,  ":raw");
binmode(STDOUT, ":raw");

use constant {
              PKGNAME    => 'BQOF',
              FORMAT     => 'bqof',
              VERSION    => '0.01',
              CHUNK_SIZE => 1 << 17,
             };

# Container signature
use constant SIGNATURE => uc(FORMAT) . chr(1);

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

sub qof_encoder ($string) {

    use constant {
                  QOI_OP_RGB  => 0b1111_1110,
                  QOI_OP_DIFF => 0b01_000_000,
                  QOI_OP_RUN  => 0b11_000_000,
                  QOI_OP_LUMA => 0b10_000_000,
                 };

    my $run     = 0;
    my $px      = 0;
    my $prev_px = -1;

    my $rle4 = rle4_encode(string2symbols($string));
    my ($bwt, $idx) = bwt_encode(symbols2string($rle4));

    my @bytes;
    my @table = (0) x 64;
    my @chars = unpack('C*', $bwt);

    push @bytes, unpack('C*', pack('N', $idx));

    while (@chars) {

        $px = shift(@chars);

        if ($px == $prev_px) {
            if (++$run == 62) {
                push @bytes, QOI_OP_RUN | ($run - 1);
                $run = 0;
            }
        }
        else {

            if ($run > 0) {
                push @bytes, (QOI_OP_RUN | ($run - 1));
                $run = 0;
            }

            my $hash     = $px % 64;
            my $index_px = $table[$hash];

            if ($px == $index_px) {
                push @bytes, $hash;
            }
            else {

                $table[$hash] = $px;
                my $diff = $px - $prev_px;

                if ($diff > -33 and $diff < 32) {
                    push(@bytes, QOI_OP_DIFF | ($diff + 32));
                }
                else {
                    push(@bytes, QOI_OP_RGB, $px);
                }
            }
        }

        $prev_px = $px;
    }

    if ($run > 0) {
        push(@bytes, QOI_OP_RUN | ($run - 1));
    }

    create_huffman_entry(\@bytes);
}

sub qof_decoder ($fh) {

    use constant {
                  QOI_OP_RGB   => 0b1111_1110,
                  QOI_OP_DIFF  => 0b01_000_000,
                  QOI_OP_RUN   => 0b11_000_000,
                  QOI_OP_LUMA  => 0b10_000_000,
                  QOI_OP_INDEX => 0b00_000_000,
                 };

    my $run = 0;
    my $px  = -1;

    my @bytes;
    my @table = ((0) x 64);

    my $index   = 0;
    my @symbols = @{decode_huffman_entry($fh)};

    my $idx = unpack('N', pack('C*', map { $symbols[$index++] } 1 .. 4));

    while (1) {

        if ($run > 0) {
            --$run;
        }
        else {
            my $byte = $symbols[$index++] // last;

            if ($byte == QOI_OP_RGB) {    # OP RGB
                $px = $symbols[$index++];
            }
            elsif (($byte >> 6) == (QOI_OP_INDEX >> 6)) {    # OP INDEX
                $px = $table[$byte];
            }
            elsif (($byte >> 6) == (QOI_OP_DIFF >> 6)) {     # OP DIFF
                $px += ($byte & 0b00_111_111) - 32;
            }
            elsif (($byte >> 6) == (QOI_OP_RUN >> 6)) {      # OP RUN
                $run = ($byte & 0b00_111_111);
            }

            $table[$px % 64] = $px;
        }

        push @bytes, $px;
    }

    my $bwt  = pack('C*', @bytes);
    my $rle4 = string2symbols(bwt_decode($bwt, $idx));

    return symbols2string(rle4_decode($rle4));
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
        print $out_fh qof_encoder($chunk);
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
        print $out_fh qof_decoder($fh);
    }

    # Close the file
    close $fh;
    close $out_fh;
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

main();
exit(0);
