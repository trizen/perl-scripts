#!/usr/bin/perl

# A proof of concept compression method, combining LZW with Huffman coding.

# Idea:
#   1. Apply Huffman coding on the input bytes and return an array of symbols.
#   2. Do LZW compression on the symbols returned by (1) and return an array of symbols.
#   3. Apply Huffman coding on the symbols returned by (2).

# See also:
#   https://rosettacode.org/wiki/huffman_coding
#   https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Welch

use 5.020;
use strict;
use warnings;

use List::Util   qw(uniq);
use experimental qw(signatures);

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for ('0', '1') }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

# make a tree, and return resulting dictionaries
sub make_tree ($bytes) {
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
    my @enc;
    for (@$bytes) {
        push @enc, $dict->{$_} // die "bad char: $_";
    }
    return \@enc;
}

sub huffman_decode ($bits, $hash) {
    local $" = '|';
    $bits =~ s/(@{[sort { length($a) <=> length($b) } keys %{$hash}]})/$hash->{$1} /gr;    # very fast
}

# Compress a string to a list of output symbols
sub lzw_compress ($uncompressed, $symbols) {

    # Build the dictionary
    my %dictionary;

    my $i = 0;
    foreach my $k (uniq(sort @$symbols)) {
        $dictionary{$k} = $i++;
    }

    my $dict_size = $i;

    my $w = '';
    my @result;

    foreach my $c (@$uncompressed) {

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
sub lzw_uncompress ($compressed, $symbols) {

    # Build the dictionary
    my %dictionary;

    my $i = 0;
    foreach my $k (uniq(sort @$symbols)) {
        $dictionary{$i++} = ["$k"];
    }

    my $dict_size = $i;

    my $w      = $dictionary{$compressed->[0]};
    my @result = ($w->[0]);

    foreach my $j (1 .. $#{$compressed}) {
        my $k = $compressed->[$j];

        my $entry =
            exists($dictionary{$k}) ? $dictionary{$k}
          : ($k == $dict_size)      ? [@$w, $w->[0]]
          :                           die "Bad compressed k: $k";

        push @result, @$entry;

        # Add w+entry[0] to the dictionary
        $dictionary{$dict_size++} = [@$w, $entry->[0]];
        $w = $entry;
    }

    return \@result;
}

my $text = do {
    open my $fh, '<:raw', __FILE__;
    local $/;
    <$fh>;
};

#my $text = "TOBEORNOTTOBEORTOBEORNOT";

my @bytes = unpack('C*', $text);
my ($h, $rev_h) = make_tree(\@bytes);
my $enc     = huffman_encode(\@bytes, $h);
my @symbols = keys %$rev_h;

my $lzw = lzw_compress($enc, \@symbols);

my $unlzw = join('', @{lzw_uncompress($lzw, \@symbols)});
my $dec   = pack('C*', split(' ', huffman_decode($unlzw, $rev_h)));

$dec eq $text or die "error: ($dec != $text)";

# Doing Huffman encoding on the LZW data does not
# seem beneficial, because the rev_h2 is very large
my ($tree2, $rev_h2) = make_tree($lzw);
my $enc2 = huffman_encode($lzw, $tree2);

#<<<
# The entire process backwards
my $dec2 = pack(
                'C*',
                split(
                      ' ',
                      huffman_decode(
                                     join('', @{lzw_uncompress([split(' ', huffman_decode(join('', @$enc2), $rev_h2))], \@symbols)}),
                                     $rev_h
                                    )
                     )
               );
#>>>

$dec2 eq $text or die "error: ($dec2 != $text)";

my $dic1_size = length(join('', keys %$rev_h)) / 8;
my $dic2_size = length(join('', keys %$rev_h2)) / 8;

say("Uncompressed: ", length($text));
say("Huffman:      ", length(join('', @$enc)) / 8,  ' + ', $dic1_size);
say("LZW+Huffman:  ", length(join('', @$enc2)) / 8, ' + ', $dic1_size, ' + ', $dic2_size);
