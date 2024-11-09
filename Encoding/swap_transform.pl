#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 09 November 2024
# https://github.com/trizen

# A reversible transform, based on swapping of elements.

use 5.036;

sub swap_transform ($text, $extra = 1) {

    my @bits;
    my @arr = unpack('C*', $text);
    my $k   = 0;

    foreach my $i (1 .. $#arr) {
        if ($arr[$i] < $arr[$i - 1 - $k]) {
            push @bits, 1;
            unshift @arr, splice(@arr, $i, 1);
            ++$k if $extra;
        }
        else {
            push @bits, 0;
        }
    }

    return (pack('C*', @arr), \@bits);
}

sub reverse_swap_transform ($text, $bits) {
    my @arr = unpack('C*', $text);

    for (my $i = $#arr ; $i >= 0 ; --$i) {
        if ($bits->[$i - 1] == 1) {
            splice(@arr, $i, 0, shift(@arr));
        }
    }

    pack('C*', @arr);
}

foreach my $text (
    "TOBEORNOTTOBEORTOBEORNOT",
    "abracadabra",
    "DABDDBBDDBA",
    "CoMpReSSeD",
    "AM SAM. I AM SAM. SAM I AM. THAT SAM-I-AM",
    do {
        open my $fh, '<:raw', __FILE__;
        local $/;
        <$fh>;
    }
  ) {

    my ($t, $bits) = swap_transform($text);
    my $rev = reverse_swap_transform($t, $bits);

    if (length($t) < 100) {
        say $t;
        say join('', @$bits);
        say $rev;
        say '-' x 80;
    }

    if ($rev ne $text) {
        die "Failed for: $text";
    }
}

__END__
NEBOBNRBOTEOOTTOEORTOROT
11001100001000011100100
TOBEORNOTTOBEORTOBEORNOT
--------------------------------------------------------------------------------
aaaaabrcdbr
0010101001
abracadabra
--------------------------------------------------------------------------------
ABADBDDBDDB
1000100001
DABDDBBDDBA
--------------------------------------------------------------------------------
eSRMCopeSD
010101010
CoMpReSSeD
--------------------------------------------------------------------------------
--A A . I  .A   .A AMSMIAMSMSAMAMTHTSMIAM
0101011010010101100011100110010101010100
AM SAM. I AM SAM. SAM I AM. THAT SAM-I-AM
--------------------------------------------------------------------------------
