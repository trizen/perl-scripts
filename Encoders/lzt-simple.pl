#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Created on: 21 May 2014
# Latest edit on: 28 May 2014
# Website: http://github.com/trizen

# A new type of LZ compression, featuring a very short decompression time.

use 5.010;
use strict;
use autodie;
use warnings;

use Getopt::Std qw(getopts);
use File::Basename qw(basename);

use constant {
              PKGNAME => 'lzt-simple',
              VERSION => '0.01',
              FORMAT  => 'lzt',
             };

use constant {
              MIN       => 4,
              BUFFER    => 255,
              SIGNATURE => uc(FORMAT) . chr(1),
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
                    $dict{$pos}{$j} //= $i;
                }
            }
        }

        my @pairs;
        my $uncompressed = '';
        for (my $i = 0 ; $i < $len ; $i++) {
            if (exists $dict{$i}) {
                my ($key) = sort { $dict{$i}{$b} <=> $dict{$i}{$a} } keys %{$dict{$i}};
                my $vlen = $dict{$i}{$key};
                push @pairs, [$i, $key, $vlen];
                $i += $vlen - 1;
            }
            else {
                $uncompressed .= substr($block, $i, 1);
            }
        }

        my $uncomp_len = length($uncompressed);
        printf("%3d -> %3d (%.2f%%)\n", $len, $uncomp_len, ($len - $uncomp_len) / $len * 100);
        print {$out_fh} chr($uncomp_len), chr(scalar @pairs), (
            map {
                map { chr }
                  @{$_}
              } @pairs
        ), $uncompressed;
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
        read($fh, (my $groups_byte), 1);

        my %dict;
        for my $i (1 .. ord($groups_byte)) {
            read($fh, (my $at_byte),   1);
            read($fh, (my $from_byte), 1);
            read($fh, (my $size_byte), 1);
            $dict{ord($at_byte)} = [ord($from_byte), ord($size_byte)];
        }

        my $len = ord($len_byte);
        read($fh, (my $block), $len);

        my $acc          = 0;
        my $decompressed = '';

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
