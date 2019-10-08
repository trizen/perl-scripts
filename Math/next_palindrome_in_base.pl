#!/usr/bin/perl

# A nice algorithm, due to David A. Corneth (Jun 06 2014), for generating the next palindrome from a given palindrome.

# Generalized to other bases by Daniel Suteu (Sep 16 2019).

# See also:
#   https://oeis.org/A002113
#   https://en.wikipedia.org/wiki/Palindromic_number

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub next_palindrome ($n, $base = 10) {

    my @d = todigits($n, $base);
    my $l = $#d;
    my $i = ((scalar(@d) + 1) >> 1) - 1;

    while ($i >= 0 and $d[$i] == $base - 1) {
        $d[$i] = 0;
        $d[$l - $i] = 0;
        $i--;
    }

    if ($i >= 0) {
        $d[$i]++;
        $d[$l - $i] = $d[$i];
    }
    else {
        @d     = (0) x (scalar(@d) + 1);
        $d[0]  = 1;
        $d[-1] = 1;
    }

    fromdigits(\@d, $base);
}

foreach my $base (2 .. 12) {
    my @a = do {
        my $n = 1;
        map { $n = next_palindrome($n, $base) } 1 .. 20;
    };
    say "base = $base -> [@a]";
}

__END__
base = 2 -> [3 5 7 9 15 17 21 27 31 33 45 51 63 65 73 85 93 99 107 119]
base = 3 -> [2 4 8 10 13 16 20 23 26 28 40 52 56 68 80 82 91 100 112 121]
base = 4 -> [2 3 5 10 15 17 21 25 29 34 38 42 46 51 55 59 63 65 85 105]
base = 5 -> [2 3 4 6 12 18 24 26 31 36 41 46 52 57 62 67 72 78 83 88]
base = 6 -> [2 3 4 5 7 14 21 28 35 37 43 49 55 61 67 74 80 86 92 98]
base = 7 -> [2 3 4 5 6 8 16 24 32 40 48 50 57 64 71 78 85 92 100 107]
base = 8 -> [2 3 4 5 6 7 9 18 27 36 45 54 63 65 73 81 89 97 105 113]
base = 9 -> [2 3 4 5 6 7 8 10 20 30 40 50 60 70 80 82 91 100 109 118]
base = 10 -> [2 3 4 5 6 7 8 9 11 22 33 44 55 66 77 88 99 101 111 121]
base = 11 -> [2 3 4 5 6 7 8 9 10 12 24 36 48 60 72 84 96 108 120 122]
base = 12 -> [2 3 4 5 6 7 8 9 10 11 13 26 39 52 65 78 91 104 117 130]
