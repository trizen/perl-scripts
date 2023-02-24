#!/usr/bin/perl

# Author: Trizen
# Date: 15 December 2022
# https://github.com/trizen

# Compress/decompress files using LZ77 compression + Huffman coding.

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Getopt::Std    qw(getopts);
use File::Basename qw(basename);

use constant {
              PKGNAME    => 'LZ77H',
              VERSION    => '0.01',
              FORMAT     => 'lz77h',
              CHUNK_SIZE => 1 << 16,
             };

use constant {SIGNATURE => "LZ77H" . chr(1)};

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

sub lz77_compression ($str) {

    my @rep;
    my $la = 0;

    my $prefix = '';
    my @bytes  = split(//, $str);
    my $end    = $#bytes;

    while ($la <= $end) {

        my $n = 1;
        my $p = 0;
        my $tmp;

        my $token = $bytes[$la];

        while (    $n < 255
               and $la + $n <= $end
               and ($tmp = index($prefix, $token, $p)) >= 0) {
            $p = $tmp;
            $token .= $bytes[$la + $n];
            ++$n;
        }

        --$n;
        my $c = $bytes[$la + $n];
        push @rep, [$p, $n, $c];
        $la += $n + 1;
        $prefix .= $token;
    }

    return \@rep;
}

sub lz77_decompression ($uncompressed, $indices, $lengths) {

    my $ret   = '';
    my $chunk = '';

    my $end = $#{$uncompressed};

    for (my $i = 0 ; $i <= $end ; ++$i) {
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
        if (defined($x) and defined($y)) {
            push @nodes, [[$x, $y], $x->[1] + $y->[1]];
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

    my $dict  = '';
    my $codes = '';

    foreach my $i (0 .. 255) {
        my $c = $h->{$i} // '';
        $codes .= $c;
        $dict  .= chr(length($c));
    }

    print $out_fh $dict;
    print $out_fh pack("B*", $codes);
    print $out_fh pack("N",  length($enc));
    print $out_fh pack("B*", $enc);
}

sub decode_huffman_entry ($fh) {

    my @codes;
    my $codes_len = 0;

    foreach my $c (0 .. 255) {
        my $l = ord(getc($fh));
        if ($l > 0) {
            $codes_len += $l;
            push @codes, [$c, $l];
        }
    }

    my $codes_bin = '';
    while (length($codes_bin) < $codes_len) {
        $codes_bin .= unpack('B*', getc($fh) // last);
    }

    my %rev_dict;
    foreach my $pair (@codes) {
        my $code = substr($codes_bin, 0, $pair->[1], '');
        $rev_dict{$code} = chr($pair->[0]);
    }

    my $enc_len = unpack('N', join('', map { getc($fh) } 1 .. 4));

    if ($enc_len > 0) {

        my $enc_data = '';
        while (length($enc_data) < $enc_len) {
            $enc_data .= unpack('B*', getc($fh));
        }

        if (length($enc_data) > $enc_len) {
            $enc_data = substr($enc_data, 0, $enc_len);
        }

        return huffman_decode($enc_data, \%rev_dict);
    }

    return '';
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

    my @uncompressed;
    my @lengths;
    my $indices = '';

    # Compress data
    while (read($fh, (my $chunk), CHUNK_SIZE)) {
        my $compressed_data = lz77_compression($chunk);
        foreach my $entry (@$compressed_data) {
            $indices .= pack('S', $entry->[0]);
            push @lengths,      $entry->[1];
            push @uncompressed, ord($entry->[2]);
        }
    }

    create_huffman_entry(\@uncompressed,           $out_fh);
    create_huffman_entry([unpack('C*', $indices)], $out_fh);
    create_huffman_entry(\@lengths,                $out_fh);

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

    my @uncompressed = split(//, decode_huffman_entry($fh));
    my @indices      = unpack('S*', decode_huffman_entry($fh));
    my @lengths      = unpack('C*', decode_huffman_entry($fh));

    print $out_fh lz77_decompression(\@uncompressed, \@indices, \@lengths);

    # Close the file
    close $fh;
    close $out_fh;
}

main();
exit(0);