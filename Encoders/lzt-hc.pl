#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Created on: 21 May 2014
# Latest edit on: 26 April 2015
# Website: http://github.com/trizen

# A new type of LZ compression + Huffman coding, featuring a very short decompression time.

use 5.010;
use strict;
use autodie;
use warnings;

use Getopt::Std qw(getopts);
use File::Basename qw(basename);

use constant {
              PKGNAME => 'lzt-simple',
              VERSION => '0.02',
              FORMAT  => 'lzt',
             };

use constant {
              MIN       => 4,
              BUFFER    => 256,
              SIGNATURE => uc(FORMAT) . chr(2),
             };

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

sub main {
    my %opt;
    getopts('ei:o:vhr', \%opt);

    $opt{h} && usage(0);
    $opt{v} && version();

    my ($input, $output) = @ARGV;
    $input //= $opt{i} // usage(2);
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

        decompress($input, $output)
          || die "$0: error: decompression failed!\n";
    }
    elsif ($input !~ $ext || (defined($output) && $output =~ $ext)) {
        $output //= basename($input) . '.' . FORMAT;
        compress($input, $output)
          || die "$0: error: compression failed!\n";
    }
    else {
        warn "$0: don't know what to do...\n";
        usage(1);
    }
}

sub walk {
    my ($n, $s, $h) = @_;
    if (exists($n->{a})) {
        $h->{$n->{a}} = $s;
        return 1;
    }
    walk($n->{'0'}, $s . '0', $h);
    walk($n->{'1'}, $s . '1', $h);
}

sub mktree {
    my ($text) = @_;

    my %letters;
    ++$letters{$_} for (split(//, $text));

    my @nodes;
    if ((@nodes = map { {a => $_, freq => $letters{$_}} } keys %letters) == 1) {
        return {$nodes[0]{a} => '0'};
    }

    my %n;
    while ((@nodes = sort { $a->{freq} <=> $b->{freq} } @nodes) > 1) {
        %n = ('0' => {%{shift(@nodes)}}, '1' => {%{shift(@nodes)}});
        $n{freq} = $n{'0'}{freq} + $n{'1'}{freq};
        push @nodes, {%n};

    }

    walk(\%n, '', $n{tree} = {});
    return $n{tree};
}

sub huffman_encode {
    my ($str, $dict) = @_;
    join('', map { $dict->{$_} // die("bad char $_") } split(//, $str));
}

sub huffman_decode {
    my ($hash, $bytes) = @_;
    local $" = '|';
    unpack('B*', $bytes) =~ s/(@{[sort {length($a) <=> length($b)} keys %{$hash}]})/$hash->{$1}/gr;
}

sub valid_archive {
    my ($fh) = @_;

    if (read($fh, (my $sig), length(SIGNATURE), 0) == length(SIGNATURE)) {
        $sig eq SIGNATURE || return;
    }

    return 1;
}

sub compress {
    my ($input, $output) = @_;

    # Open the input file
    open my $fh, '<:raw', $input;

    # Open the output file and write the archive signature
    open my $out_fh, '>:raw', $output;
    print {$out_fh} SIGNATURE;

    while ((my $len = read($fh, (my $block), BUFFER)) > 0) {

        my %dict;
        my $max = int($len / 2);

        foreach my $i (reverse(MIN .. $max)) {
            foreach my $j (0 .. $len - $i * 2) {
                if ((my $pos = index($block, substr($block, $j, $i), $j + $i)) != -1) {
                    if (not exists $dict{$pos} or $i > $dict{$pos}[1]) {
                        $dict{$pos} = [$j, $i];
                    }
                }
            }
        }

        my @pairs;
        my $uncompressed = '';
        for (my $i = 0 ; $i < $len ; $i++) {
            if (exists $dict{$i}) {
                my ($key, $vlen) = @{$dict{$i}};
                push @pairs, [$i, $key, $vlen];
                $i += $vlen - 1;
            }
            else {
                $uncompressed .= substr($block, $i, 1);
            }
        }

        my $huffman_hash = mktree($uncompressed);
        my $huffman_enc = huffman_encode($uncompressed, $huffman_hash);

        my %huffman_dict;
        foreach my $k (keys %{$huffman_hash}) {
            push @{$huffman_dict{length($huffman_hash->{$k})}}, [$k, $huffman_hash->{$k}];
        }

        {
            use bytes;

            my $binary_enc = pack('B*', $huffman_enc);
            my $encoding_len = length($binary_enc);

            printf("%3d -> %3d (%.2f%%)\n", $len, $encoding_len, ($len - $encoding_len) / $len * 100);
            print {$out_fh}

              # Length of the uncompressed text
              chr(length($uncompressed) - 1),

              # LZT pairs num
              chr($#pairs + 1),

              # LZT pairs encoded into bytes
              (
                map {
                    map { chr }
                      @{$_}
                  } @pairs
              ),

              # Huffman dictionary size
              chr(scalar(keys(%huffman_dict)) > 0 ? scalar(keys(%huffman_dict)) - 1 : 0),

              # Huffman dictionary into bytes
              (
                join(
                    '',
                    map {
                            chr($_)
                          . chr($#{$huffman_dict{$_}} + 1)
                          . join('', map { $_->[0] } @{$huffman_dict{$_}})
                          . pack('B*', join('', map { $_->[1] } @{$huffman_dict{$_}}))
                      } sort { $a <=> $b } keys %huffman_dict
                    )
              ),

              # Huffman encoded bytes length
              chr($encoding_len - 1),

              # Huffman encoded bytes
              $binary_enc
        }

        #   exit;
    }

    close $fh;
    close $out_fh;
}

sub decompress {
    my ($input, $output) = @_;

    # Open and validate the input file
    open my $fh, '<:raw', $input;
    valid_archive($fh) || die "$0: file `$input' is not a \U${\FORMAT}\E archive!\n";

    # Open the output file
    open my $out_fh, '>:raw', $output;

    while (read($fh, (my $len_byte), 1) > 0) {
        read($fh, (my $lzt_pairs), 1);

        # Create the LZT dictionary
        my %dict;
        for my $i (1 .. ord($lzt_pairs)) {
            read($fh, (my $at_byte),   1);
            read($fh, (my $from_byte), 1);
            read($fh, (my $size_byte), 1);
            $dict{ord($at_byte)} = [ord($from_byte), ord($size_byte)];
        }

        read($fh, (my $huffman_pairs), 1);

        # Create the Huffman dictionary
        my %huffman_dict;
        for my $i (1 .. ord($huffman_pairs) + 1) {
            read($fh, (my $pattern_len), 1);
            read($fh, (my $pattern_num), 1);

            my $bits_num = ord($pattern_len) * ord($pattern_num);

            if ($bits_num % 8 != 0) {
                $bits_num += 8 - ($bits_num % 8);
            }

            read($fh, (my $chars),    ord($pattern_num));
            read($fh, (my $patterns), $bits_num / 8);

            my $bits = unpack('B*', $patterns);
            foreach my $char (split(//, $chars)) {
                $huffman_dict{substr($bits, 0, ord($pattern_len), '')} = $char;
            }
        }

        read($fh, (my $bytes_len), 1);
        read($fh, (my $bytes),     ord($bytes_len) + 1);

        # Huffman decoding
        my $len = ord($len_byte) + 1;
        my $block = substr(huffman_decode(\%huffman_dict, $bytes), 0, $len);

        my $acc          = 0;
        my $decompressed = '';

        # LZT decoding
        for (my $i = 0 ; $i <= $len ; $i++) {
            if (exists($dict{$i + $acc})) {
                my $pos = $dict{$i + $acc};
                $decompressed .= substr($decompressed, $pos->[0], $pos->[1]);
                $acc += $pos->[1];
                $i--;
            }
            else {
                $decompressed .= substr($block, $i, 1);
            }
        }

        print {$out_fh} $decompressed;
    }

    close $fh;
    close $out_fh;
}

main();
exit(0);
