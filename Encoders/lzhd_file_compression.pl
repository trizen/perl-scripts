#!/usr/bin/perl

# Author: Trizen
# Date: 15 December 2022
# Edit: 08 June 2023
# https://github.com/trizen

# Compress/decompress files using LZ77 compression + Huffman coding.

# Encoding the distances/indices using a DEFLATE-like approach.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);
use List::Util     qw(max);

use constant {
    PKGNAME => 'LZHD',
    VERSION => '0.01',
    FORMAT  => 'lzhd',

    COMPRESSED_BYTE   => chr(1),
    UNCOMPRESSED_BYTE => chr(0),
    CHUNK_SIZE        => 1 << 16,    # higher value = better compression
};

use constant {SIGNATURE => "LZHD" . chr(1)};

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

        lz77h_decompress_file($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        lz77h_compress_file($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

sub lz77_compression ($str, $uncompressed, $indices, $lengths) {

    my $la = 0;

    my $prefix = '';
    my @chars  = split(//, $str);
    my $end    = $#chars;

    while ($la <= $end) {

        my $n = 1;
        my $p = 0;
        my $tmp;

        my $token = $chars[$la];

        while (    $n < 255
               and $la + $n <= $end
               and ($tmp = index($prefix, $token, $p)) >= 0) {
            $p = $tmp;
            $token .= $chars[$la + $n];
            ++$n;
        }

        --$n;
        push @$indices,      $p;
        push @$lengths,      $n;
        push @$uncompressed, ord($chars[$la + $n]);
        $la += $n + 1;
        $prefix .= $token;
    }

    return;
}

sub lz77_decompression ($uncompressed, $indices, $lengths) {

    my $ret   = '';
    my $chunk = '';

    foreach my $i (0 .. $#{$uncompressed}) {
        $chunk .= substr($chunk, $indices->[$i], $lengths->[$i]) . $uncompressed->[$i];
        if (length($chunk) >= CHUNK_SIZE) {
            $ret .= $chunk;
            $chunk = '';
        }
    }

    if ($chunk ne '') {
        $ret .= $chunk;
    }

    $ret;
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

    my $compressed = chr(scalar @counts);

    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        $compressed .= chr($blen);
        $compressed .= pack('N', $len);
    }

    my $bits = '';
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;

        foreach my $symbol (splice(@$integers, 0, $len)) {
            $bits .= sprintf("%0*b", $blen, $symbol);
        }

        if (length($bits) % 8 == 0) {
            $compressed .= pack('B*', $bits);
            $bits = '';
        }
    }

    if ($bits ne '') {
        $compressed .= pack('B*', $bits);
    }

    return \$compressed;
}

sub decode_integers ($fh) {

    my $count_len = ord(getc($fh));

    my @counts;
    my $bits_len = 0;

    for (1 .. $count_len) {
        my $blen = ord(getc($fh));
        my $len  = unpack('N', join('', map { getc($fh) } 1 .. 4));
        push @counts, [$blen + 0, $len + 0];
        $bits_len += $blen * $len;
    }

    my $bits = read_bits($fh, $bits_len);

    my @chunks;
    foreach my $pair (@counts) {
        my ($blen, $len) = @$pair;
        $len > 0 or next;
        foreach my $chunk (unpack(sprintf('(a%d)*', $blen), substr($bits, 0, $blen * $len, ''))) {
            push @chunks, oct('0b' . $chunk);
        }
    }

    return \@chunks;
}

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for ('0', '1') }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

# make a tree, and return resulting dictionaries
sub mktree ($bytes) {
    my (%freq, @nodes);

    ++$freq{$_} for @$bytes;
    @nodes = map { [$_, $freq{$_}] } sort { $a <=> $b } keys %freq;

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice(@nodes, 0, 2);
        if (defined($x)) {
            if (defined($y)) {
                push @nodes, [[$x, $y], $x->[1] + $y->[1]];
            }
            else {
                push @nodes, [[$x], $x->[1]];
            }
        }
    } while (@nodes > 1);

    walk($nodes[0], '', {}, {});
}

sub huffman_encode ($bytes, $dict) {
    my $enc = '';
    for (@$bytes) {
        $enc .= $dict->{$_} // die "bad char: $_";
    }
    return $enc;
}

sub huffman_decode ($bits, $hash) {
    local $" = '|';
    $bits =~ s/(@{[sort { length($a) <=> length($b) } keys %{$hash}]})/$hash->{$1}/gr;    # very fast
}

sub create_huffman_entry ($bytes, $out_fh) {

    my ($h, $rev_h) = mktree($bytes);
    my $enc = huffman_encode($bytes, $h);

    my $max_symbol = max(@$bytes);

    my @lengths;
    my $codes = '';

    foreach my $i (0 .. $max_symbol) {
        my $c = $h->{$i} // '';
        $codes .= $c;
        push @lengths, length($c);
    }

    print $out_fh ${encode_integers(\@lengths)};
    print $out_fh pack("B*", $codes);
    print $out_fh pack("N",  length($enc));
    print $out_fh pack("B*", $enc);
}

sub read_bits ($fh, $bits_len) {

    my $data = '';
    read($fh, $data, $bits_len >> 3);
    $data = unpack('B*', $data);

    while (length($data) < $bits_len) {
        $data .= unpack('B*', getc($fh));
    }

    if (length($data) > $bits_len) {
        $data = substr($data, 0, $bits_len);
    }

    return $data;
}

sub decode_huffman_entry ($fh) {

    my @codes;
    my $codes_len = 0;

    my @lengths = @{decode_integers($fh)};

    foreach my $i (0 .. $#lengths) {
        my $l = $lengths[$i];
        if ($l > 0) {
            $codes_len += $l;
            push @codes, [$i, $l];
        }
    }

    my $codes_bin = read_bits($fh, $codes_len);

    my %rev_dict;
    foreach my $pair (@codes) {
        my $code = substr($codes_bin, 0, $pair->[1], '');
        $rev_dict{$code} = chr($pair->[0]);
    }

    my $enc_len = unpack('N', join('', map { getc($fh) } 1 .. 4));

    if ($enc_len > 0) {
        return huffman_decode(read_bits($fh, $enc_len), \%rev_dict);
    }

    return '';
}

my @distance_symbols = (

    # [distance value, offset bits]
    [0,  0],
    [1,  0],
    [2,  0],
    [3,  0],
    [4,  0],
    [5,  1],
    [7,  1],
    [9,  2],
    [13, 2],
    [17, 3],
    [25, 3],
    [33, 4],
    [49, 4],
    [65, 5],
    [97, 5],
                       );

until ($distance_symbols[-1][0] > CHUNK_SIZE) {
    push @distance_symbols, [int($distance_symbols[-1][0] * (4 / 3)), $distance_symbols[-1][1] + 1,];

    push @distance_symbols, [int($distance_symbols[-1][0] * (3 / 2)), $distance_symbols[-1][1],];
}

sub encode_distances ($distances, $out_fh) {

    my @symbols;
    my $offset_bits = '';

    foreach my $dist (@$distances) {
        foreach my $i (0 .. $#distance_symbols) {
            if ($distance_symbols[$i][0] > $dist) {
                push @symbols, $i - 1;

                if ($distance_symbols[$i - 1][1] > 0) {
                    $offset_bits .= sprintf('%0*b', $distance_symbols[$i - 1][1], $dist - $distance_symbols[$i - 1][0]);
                }
                last;
            }
        }
    }

    create_huffman_entry(\@symbols, $out_fh);
    print $out_fh pack('B*', $offset_bits);
}

sub decode_distances ($fh) {

    my @symbols  = unpack('C*', decode_huffman_entry($fh));
    my $bits_len = 0;

    foreach my $i (@symbols) {
        $bits_len += $distance_symbols[$i][1];
    }

    my $bits = read_bits($fh, $bits_len);

    my @distances;
    foreach my $i (@symbols) {
        push @distances, $distance_symbols[$i][0] + oct('0b' . substr($bits, 0, $distance_symbols[$i][1], ''));
    }

    return \@distances;
}

# Compress file
sub lz77h_compress_file ($input, $output) {

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

        my (@uncompressed, @indices, @lengths);
        lz77_compression($chunk, \@uncompressed, \@indices, \@lengths);

        my $est_ratio = length($chunk) / (4 * scalar(@uncompressed));

        say(scalar(@uncompressed), ' -> ', $est_ratio);

        if ($est_ratio > 1) {
            print $out_fh COMPRESSED_BYTE;
            create_huffman_entry(\@uncompressed, $out_fh);
            create_huffman_entry(\@lengths,      $out_fh);
            encode_distances(\@indices, $out_fh);
        }
        else {
            print $out_fh UNCOMPRESSED_BYTE;
            create_huffman_entry([unpack('C*', $chunk)], $out_fh);
        }
    }

    # Close the file
    close $out_fh;
}

# Decompress file
sub lz77h_decompress_file ($input, $output) {

    # Open and validate the input file
    open my $fh, '<:raw', $input;
    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E v${\VERSION} archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output;

    while (!eof($fh)) {

        my $compression_byte = getc($fh);

        if ($compression_byte eq COMPRESSED_BYTE) {

            my @uncompressed = split(//, decode_huffman_entry($fh));
            my @lengths      = unpack('C*', decode_huffman_entry($fh));
            my $indices      = decode_distances($fh);

            print $out_fh lz77_decompression(\@uncompressed, $indices, \@lengths);
        }
        elsif ($compression_byte eq UNCOMPRESSED_BYTE) {
            print $out_fh decode_huffman_entry($fh);
        }
        else {
            die "Invalid compression...";
        }
    }

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);
