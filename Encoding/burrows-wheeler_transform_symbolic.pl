#!/usr/bin/perl

# Author: Trizen
# Date: 14 June 2023
# Edit: 18 March 2024
# https://github.com/trizen

# Implementation of the Burrows–Wheeler transform, generalized to work over any array of numerical symbol.

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
        if ($cyclic[$i] != $cyclic[$i - 1]) {
            $rle = 0;
            last;
        }
    }

    $rle && return [0 .. $len - 1];

    [
     sort {
         my ($i, $j) = ($a, $b);

         while ($cyclic[$i] == $cyclic[$j]) {
             $i %= $len if (++$i >= $len);
             $j %= $len if (++$j >= $len);
         }

         $cyclic[$i] <=> $cyclic[$j];
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
    my @head = sort { $a <=> $b } @tail;

    my %indices;
    foreach my $i (0 .. $#tail) {
        push @{$indices{$tail[$i]}}, $i;
    }

    my @table;
    foreach my $v (@head) {
        push @table, shift(@{$indices{$v}});
    }

    my @dec;
    my $i = $idx;

    for (1 .. scalar(@head)) {
        push @dec, $head[$i];
        $i = $table[$i];
    }

    return \@dec;
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

    my ($enc, $idx) = bwt_encode([unpack('C*', $str)]);
    my $dec = bwt_decode($enc, $idx);

    if (length($str) < 1024) {
        printf("BWT(%s) = (%s, %d)\n", pack('C*', @$dec), pack('C*', @$enc), $idx);
    }
    pack('C*', @$dec) eq $str or die sprintf("error: <<%s>> != <<%s>>", pack('C*', @$dec), $str);
}

__END__
BWT(banana) = (nnbaaa, 3)
BWT(appellee) = (eelplepa, 0)
BWT(dogwood) = (odoodwg, 1)
BWT(TOBEORNOTTOBEORTOBEORNOT) = (OOOBBBRRTTTEEENNOOORTTOO, 20)
BWT(SIX.MIXED.PIXIES.SIFT.SIXTY.PIXIE.DUST.BOXES) = (TEXYDST.E.IXIXIXXSSMPPS.B..E.S.EUSFXDIIOIIIT, 29)
BWT(PINEAPPLE) = (ENLPPIEPA, 6)
BWT() = (, 0)
BWT(a) = (a, 0)
BWT(aa) = (aa, 0)
BWT(aabb) = (baba, 0)
BWT(aaaaaaaaaaaa) = (aaaaaaaaaaaa, 0)
BWT(aaaaaaaaaaaab) = (baaaaaaaaaaaa, 0)
BWT(baaaaaaaaaaaa) = (baaaaaaaaaaaa, 12)
BWT(aaaaaabaaaaaa) = (baaaaaaaaaaaa, 6)
BWT(aaaaaaabaaaaa) = (baaaaaaaaaaaa, 5)
