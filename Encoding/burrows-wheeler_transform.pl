#!/usr/bin/perl

# Author: Trizen
# Date: 14 June 2023
# https://github.com/trizen

# Implementation of the Burrows–Wheeler transform, with fast inversion.
# https://rosettacode.org/wiki/Burrows–Wheeler_transform

# References:
#   Data Compression (Summer 2023) - Lecture 12 - The Burrows-Wheeler Transform (BWT)
#   https://youtube.com/watch?v=rQ7wwh4HRZM
#
#   Data Compression (Summer 2023) - Lecture 13 - BZip2
#   https://youtube.com/watch?v=cvoZbBZ3M2A

use 5.036;

use constant {
              LOOKAHEAD_LEN => 512,    # lower values are faster (on average)
             };

sub bwt_quadratic ($s) {    # O(n^2) space (impractical)
    [map { $_->[1] } sort { $a->[0] cmp $b->[0] } map { [substr($s, $_) . substr($s, 0, $_), $_] } 0 .. length($s) - 1];
}

sub bwt_simple ($s) {    # O(n) space (very slow)
    [sort { (substr($s, $a) . substr($s, 0, $a)) cmp(substr($s, $b) . substr($s, 0, $b)) } 0 .. length($s) - 1];
}

sub bwt_cyclic ($s) {    # O(n) space (slow)

    my @cyclic = split(//, $s);
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

sub bwt_lookahead ($s) {    # O(n) space (moderately fast)
    [
     sort {
         my $t = substr($s, $a, LOOKAHEAD_LEN);
         my $u = substr($s, $b, LOOKAHEAD_LEN);

         if (length($t) < LOOKAHEAD_LEN) {
             $t .= substr($s, 0, ($a < LOOKAHEAD_LEN) ? $a : (LOOKAHEAD_LEN - length($t)));
         }

         if (length($u) < LOOKAHEAD_LEN) {
             $u .= substr($s, 0, ($b < LOOKAHEAD_LEN) ? $b : (LOOKAHEAD_LEN - length($u)));
         }

         ($t cmp $u) || ((substr($s, $a) . substr($s, 0, $a)) cmp(substr($s, $b) . substr($s, 0, $b)))
       } 0 .. length($s) - 1
    ];
}

sub bwt_balanced ($s) {    # O(n * LOOKAHEAD_LEN) space (fast)
#<<<
    [
     map { $_->[1] } sort {
              ($a->[0] cmp $b->[0])
           || ((substr($s, $a->[1]) . substr($s, 0, $a->[1])) cmp(substr($s, $b->[1]) . substr($s, 0, $b->[1])))
     }
     map {
         my $t = substr($s, $_, LOOKAHEAD_LEN);

         if (length($t) < LOOKAHEAD_LEN) {
             $t .= substr($s, 0, ($_ < LOOKAHEAD_LEN) ? $_ : (LOOKAHEAD_LEN - length($t)));
         }

         [$t, $_]
       } 0 .. length($s) - 1
    ];
#>>>
}

sub bwt_encode ($s) {

    #my $bwt = bwt_simple($s);
    #my $bwt = bwt_quadratic($s);
    #my $bwt = bwt_cyclic($s);
    #my $bwt = bwt_lookahead($s);
    my $bwt = bwt_balanced($s);

    my $ret = join('', map { substr($s, $_ - 1, 1) } @$bwt);

    my $idx = 0;
    foreach my $i (@$bwt) {
        $i || last;
        ++$idx;
    }

    return ($ret, $idx);
}

sub bwt_decode ($bwt, $idx) {    # fast inversion

    my @tail = split(//, $bwt);
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
    my ($enc, $idx) = bwt_encode($str);
    my $dec = bwt_decode($enc, $idx);
    if (length($str) < 1024) {
        say "BWT($dec) = ($enc, $idx)";
    }
    $dec eq $str or die "error: <<$dec>> != <<$str>>";
}

__END__
BWT(banana) = (nnbaaa, 3)
BWT(appellee) = (eelplepa, 0)
BWT(dogwood) = (odoodwg, 1)
BWT(TOBEORNOTTOBEORTOBEORNOT) = (OOOBBBRRTTTEEENNOOORTTOO, 20)
BWT(SIX.MIXED.PIXIES.SIFT.SIXTY.PIXIE.DUST.BOXES) = (TEXYDST.E.IXIXIXXSSMPPS.B..E.S.EUSFXDIIOIIIT, 29)
BWT(PINEAPPLE) = (ENLPPIEPA, 6)
