#!/usr/bin/perl

use 5.020;
use strict;
use warnings;

use constant DICT_SIZE => 256;
use experimental qw(signatures);

binmode(STDOUT, ':utf8');

sub create_dictionary() {
    my %dictionary;

    foreach my $i (0 .. DICT_SIZE - 1) {
        $dictionary{chr $i} = chr $i;
    }

    return %dictionary;
}

sub compress($uncompressed) {

    my $dict_size  = DICT_SIZE;
    my %dictionary = create_dictionary();

    my $w = '';
    my @compressed;

    foreach my $c (split(//, $uncompressed)) {
        my $wc = $w . $c;
        if (exists $dictionary{$wc}) {
            $w = $wc;
        }
        else {
            push @compressed, $dictionary{$w};
            $dictionary{$wc} = chr($dict_size++);
            $w = $c;
        }
    }

    if ($w ne '') {
        push @compressed, $dictionary{$w};
    }

    return @compressed;
}

sub decompress(@compressed) {

    my $dict_size  = DICT_SIZE;
    my %dictionary = create_dictionary();

    my $w      = shift(@compressed);
    my $result = $w;

    foreach my $k (@compressed) {

        my $entry = do {
            if (exists $dictionary{$k}) {
                $dictionary{$k};
            }
            elsif ($k eq chr($dict_size)) {
                $w . substr($w, 0, 1);
            }
            else {
                die "Invalid compression: $k";
            }
        };

        $result .= $entry;
        $dictionary{chr($dict_size++)} = $w . substr($entry, 0, 1);
        $w = $entry;
    }

    return $result;
}

my $orig = 'TOBEORNOTTOBEORTOBEORNOT';

my @compressed = compress($orig);
my $enc        = join('', @compressed);
my $dec        = decompress(@compressed);

say "Encoded: $enc";
say "Decoded: $dec";

say '-' x 33;

if ($dec ne $orig) {
    die "Decompression failed!";
}

printf("Original    size  : %s\n", length($orig));
printf("Compressed  size  : %s\n", length($enc));
printf("Compression ratio : %.2f%%\n", (length($orig) - length($enc)) / length($orig) * 100);
