#!/usr/bin/perl

# Author: Trizen
# Date: 08 December 2022
# https://github.com/trizen

# Compress/decompress files using LZW compression.

# See also:
#   https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Welch

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);

use constant {
              PKGNAME => 'LZW22',
              VERSION => '0.01',
              FORMAT  => 'lzw',
             };

use constant {SIGNATURE => "LZW22" . chr(1)};

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

        lzw_decompress_file($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        lzw_compress_file($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

# Compress a string to a list of output symbols
sub compress ($uncompressed) {

    # Build the dictionary
    my $dict_size = 256;
    my %dictionary;

    foreach my $i (0 .. $dict_size - 1) {
        $dictionary{chr($i)} = $i;
    }

    my $w = '';
    my @result;

    foreach my $c (split(//, $uncompressed)) {
        my $wc = $w . $c;
        if (exists $dictionary{$wc}) {
            $w = $wc;
        }
        else {
            push @result, $dictionary{$w};

            # Add wc to the dictionary
            $dictionary{$wc} = $dict_size++;
            $w = $c;
        }
    }

    # Output the code for w
    if ($w ne '') {
        push @result, $dictionary{$w};
    }

    return \@result;
}

# Decompress a list of output ks to a string
sub decompress ($compressed) {

    # Build the dictionary
    my $dict_size = 256;
    my %dictionary;

    foreach my $i (0 .. $dict_size - 1) {
        $dictionary{$i} = chr($i);
    }

    my $w      = $dictionary{$compressed->[0]};
    my $result = $w;

    foreach my $j (1 .. $#{$compressed}) {
        my $k = $compressed->[$j];

        my $entry =
            exists($dictionary{$k}) ? $dictionary{$k}
          : ($k == $dict_size)      ? ($w . substr($w, 0, 1))
          :                           die "Bad compressed k: $k";

        $result .= $entry;

        # Add w+entry[0] to the dictionary
        $dictionary{$dict_size++} = $w . substr($entry, 0, 1);
        $w = $entry;
    }

    return $result;
}

# Compress file
sub lzw_compress_file ($input, $output) {

    my $compressed = do {
        open my $fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";
        local $/;
        compress(<$fh>);
    };

    my @counts;
    my $count           = 0;
    my $bits_width      = 1;
    my $bits_max_symbol = 1 << $bits_width;
    my $processed_len   = 0;

    foreach my $k (@$compressed) {
        while ($k >= $bits_max_symbol) {

            if ($count > 0) {
                push @counts, [$bits_width, $count];
                $processed_len += $count;
            }

            $count = 0;
            $bits_max_symbol *= 2;
            $bits_width      += 1;
        }
        ++$count;
    }

    push @counts, [$bits_width, scalar(@$compressed) - $processed_len];

    my $header = SIGNATURE;
    my $clen   = scalar @counts;
    $header .= chr($clen);

    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        $len > 0 or next;
        $header .= chr($blen);
        $header .= pack('N', $len);
    }

    # Open the output file for writing
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for write: $!";

    # Print the header
    print $out_fh $header;

    my $bits = '';
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;

        $len > 0 or next;

        foreach my $symbol (splice(@$compressed, 0, $len)) {
            $bits .= sprintf("%0*b", $blen, $symbol);
        }

        if (length($bits) % 8 == 0) {
            print $out_fh pack('B*', $bits);
            $bits = '';
        }
    }

    if ($bits ne '') {
        print $out_fh pack('B*', $bits);
    }

    close $out_fh;
}

# Decompress file
sub lzw_decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input;
    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output;

    my $count_len = ord(getc($fh));
    my @counts;

    for (1 .. $count_len) {
        my $blen = ord(getc($fh));
        my $len  = unpack('N', join('', map { getc($fh) } 1 .. 4));
        push @counts, [$blen + 0, $len + 0];
    }

    my $bits = unpack(
        'B*',
        do {
            local $/;
            <$fh>;
        }
    );

    my @chunks;
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        $len > 0 or next;
        foreach my $chunk (unpack(sprintf('(a%d)*', $blen), substr($bits, 0, $blen * $len, ''))) {
            push @chunks, oct('0b' . $chunk);
        }
    }

    print $out_fh decompress(\@chunks);
    close $out_fh;
}

main();
exit(0);
