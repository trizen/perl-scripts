#!/usr/bin/perl

# Author: Trizen
# Date: 14 June 2023
# Edit: 23 February 2024
# https://github.com/trizen

# Implementation of the Burrows–Wheeler transform, with fast inversion (n-character generalization).
# https://rosettacode.org/wiki/Burrows–Wheeler_transform

# References:
#   Data Compression (Summer 2023) - Lecture 12 - The Burrows-Wheeler Transform (BWT)
#   https://youtube.com/watch?v=rQ7wwh4HRZM
#
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;

sub bwt_cyclic ($s) {    # O(n) space (slowish)

    my @cyclic = @$s;
    my $len    = scalar(@cyclic);

    my $rle = 1;
    foreach my $i (1 .. $len - 1) {
        if ($cyclic[$i] ne $cyclic[$i - 1]) {
            $rle = 0;
            last;
        }
    }

    $rle && return [0 .. $len - 1];

    [
     sort {
         my ($i, $j) = ($a, $b);

         while ($cyclic[$i] eq $cyclic[$j]) {
             $i %= $len if (++$i >= $len);
             $j %= $len if (++$j >= $len);
         }

         $cyclic[$i] cmp $cyclic[$j];
       } 0 .. $len - 1
    ];
}

sub bwt_encode ($s) {

    my $bwt = bwt_cyclic($s);
    my @ret = map { $s->[$_ - 1] } @$bwt;

    my $idx = 0;
    foreach my $i (@$bwt) {
        $i || last;
        ++$idx;
    }

    return (\@ret, $idx);
}

sub bwt_decode ($bwt, $idx) {    # fast inversion

    my @tail = @$bwt;
    my @head = sort @tail;

    my %indices;
    foreach my $i (0 .. $#tail) {
        push @{$indices{$tail[$i]}}, $i;
    }

    my @table;
    foreach my $v (@head) {
        push @table, shift(@{$indices{$v}});
    }

    my $dec = '';
    my $i   = $idx;

    for (1 .. scalar(@head)) {
        $dec .= $head[$i];
        $i = $table[$i];
    }

    return $dec;
}

#<<<
my @tests = (
    "banana", "appellee", "dogwood", "TOBEORNOTTOBEORTOBEORNOT",
    "SIX.MIXED.PIXIES.SIFT.SIXTY.PIXIE.DUST.BOXES", "PINEAPPLE",
    "","a","aa","aabb","aaaaaaaaaaaa","aaaaaaaaaaaab",
    "baaaaaaaaaaaa","aaaaaabaaaaaa","aaaaaaabaaaaa",
);
#>>>

foreach my $file (__FILE__, $^X) {
    push @tests, do {
        open my $fh, '<:raw', $file;
        local $/;
        <$fh>;
    };
}

foreach my $str (@tests) {

    my ($enc, $idx) = bwt_encode([unpack('(a3)*', $str)]);
    my $dec = bwt_decode($enc, $idx);

    if (length($str) < 1024) {
        say "BWT($dec) = ([@$enc], $idx)";
    }
    $dec eq $str or die "error: <<$dec>> != <<$str>>";
}

__END__
BWT(banana) = ([ban ana], 1)
BWT(appellee) = ([ee ell app], 0)
BWT(dogwood) = ([woo d dog], 1)
BWT(TOBEORNOTTOBEORTOBEORNOT) = ([TOB TOB TOB EOR EOR EOR NOT NOT], 6)
BWT(SIX.MIXED.PIXIES.SIFT.SIXTY.PIXIE.DUST.BOXES) = ([XIE SIX XTY XED IFT ST. BOX S.S XIE ES .DU .MI .PI .PI .SI], 9)
BWT(PINEAPPLE) = ([PIN PLE EAP], 1)
BWT() = ([], 0)
BWT(a) = ([a], 0)
BWT(aa) = ([aa], 0)
BWT(aabb) = ([b aab], 0)
BWT(aaaaaaaaaaaa) = ([aaa aaa aaa aaa], 0)
BWT(aaaaaaaaaaaab) = ([b aaa aaa aaa aaa], 0)
BWT(baaaaaaaaaaaa) = ([aaa aaa aaa baa a], 4)
BWT(aaaaaabaaaaaa) = ([aaa baa a aaa aaa], 2)
BWT(aaaaaaabaaaaa) = ([aaa aba a aaa aaa], 2)
