#!/usr/bin/perl

# Author: Trizen
# Date: 08 December 2022
# Edit: 13 June 2023
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
              PKGNAME => 'LZW',
              VERSION => '0.03',
              FORMAT  => 'lzw',
             };

use constant {SIGNATURE => "LZW" . chr(3)};

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
    my $dict_size  = 256;
    my @dictionary = map { chr($_) } 0 .. $dict_size - 1;

    my $w      = $dictionary[$compressed->[0]];
    my $result = $w;

    foreach my $j (1 .. $#{$compressed}) {
        my $k = $compressed->[$j];

        my $entry =
            ($k < $dict_size)  ? $dictionary[$k]
          : ($k == $dict_size) ? ($w . substr($w, 0, 1))
          :                      die "Bad compressed k: $k";

        $result .= $entry;

        # Add w+entry[0] to the dictionary
        push @dictionary, $w . substr($entry, 0, 1);
        ++$dict_size;
        $w = $entry;
    }

    return \$result;
}

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }

    chop($$bitstring);
}

sub read_bits ($fh, $bits_len) {

    my $data = '';
    read($fh, $data, $bits_len >> 3);
    $data = unpack('B*', $data);

    while (length($data) < $bits_len) {
        $data .= unpack('B*', getc($fh) // return undef);
    }

    if (length($data) > $bits_len) {
        $data = substr($data, 0, $bits_len);
    }

    return $data;
}

sub elias_encoding ($integers) {

    my $bitstring = '';
    foreach my $k (scalar(@$integers), @$integers) {
        if ($k == 0) {
            $bitstring .= '0';
        }
        else {
            my $t = sprintf('%b', $k);
            my $l = length($t) + 1;
            my $L = sprintf('%b', $l);
            $bitstring .= ('1' x (length($L) - 1)) . '0' . substr($L, 1) . substr($t, 1);
        }
    }

    pack('B*', $bitstring);
}

sub elias_decoding ($fh) {

    my @ints;
    my $len    = 0;
    my $buffer = '';

    for (my $k = 0 ; $k <= $len ; ++$k) {

        my $bl = 0;
        ++$bl while (read_bit($fh, \$buffer) eq '1');

        if ($bl > 0) {

            my $bl2 = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. $bl)) - 1;
            my $int = oct('0b1' . join('', map { read_bit($fh, \$buffer) } 1 .. ($bl2 - 1)));

            push @ints, $int;
        }
        else {
            push @ints, 0;
        }

        if ($k == 0) {
            $len = pop(@ints);
        }
    }

    return \@ints;
}

sub encode_integers ($integers) {

    my @counts;
    my $count           = 0;
    my $bits_width      = 1;
    my $bits_max_symbol = 1 << $bits_width;
    my $processed_len   = 0;

    foreach my $k (@$integers) {
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

    push @counts, grep { $_->[1] > 0 } [$bits_width, scalar(@$integers) - $processed_len];

    my $compressed = elias_encoding([(map { $_->[0] } @counts), (map { $_->[1] } @counts)]);

    my $bits = '';
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        foreach my $symbol (splice(@$integers, 0, $len)) {
            $bits .= sprintf("%0*b", $blen, $symbol);
        }
    }

    $compressed .= pack('B*', $bits);
    return $compressed;
}

sub decode_integers ($fh) {

    my $ints = elias_decoding($fh);
    my $half = scalar(@$ints) >> 1;

    my @counts;
    foreach my $i (0 .. ($half - 1)) {
        push @counts, [$ints->[$i], $ints->[$half + $i]];
    }

    my $bits_len = 0;

    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        $bits_len += $blen * $len;
    }

    my $bits = read_bits($fh, $bits_len);

    my @integers;
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        foreach my $chunk (unpack(sprintf('(a%d)*', $blen), substr($bits, 0, $blen * $len, ''))) {
            push @integers, oct('0b' . $chunk);
        }
    }

    return \@integers;
}

# Compress file
sub lzw_compress_file ($input, $output) {

    my $compressed = do {
        open my $fh, '<:raw', $input
          or die "Can't open file <<$input>> for reading: $!";
        local $/;
        compress(<$fh>);
    };

    # Open the output file for writing
    open my $out_fh, '>:raw', $output
      or die "Can't open file <<$output>> for write: $!";

    print $out_fh SIGNATURE;
    print $out_fh encode_integers($compressed);
    close $out_fh;
}

# Decompress file
sub lzw_decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input;
    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    my $chunks = decode_integers($fh);

    # Open the output file
    open my $out_fh, '>:raw', $output;

    print $out_fh ${decompress($chunks)};
    close $out_fh;
}

main();
exit(0);
