#!/usr/bin/perl

# Generate the next palindrome in a given base, where the input number may not be a palindrome.
# Algorithm by David A. Corneth (Jun 06 2014), with extensions by Daniel Suteu (Jun 06 2020).

# See also:
#   https://oeis.org/A002113
#   https://en.wikipedia.org/wiki/Palindromic_number

use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);
use Test::More tests => 41;

sub next_palindrome ($n, $base = 10) {

    my @d = todigits($n, $base);
    my $l = $#d;
    my $i = ((scalar(@d) + 1) >> 1) - 1;

    my $is_palindrome = 1;

    foreach my $j (0 .. $i) {
        if ($d[$j] != $d[$l - $j]) {
            $is_palindrome = 0;
            last;
        }
    }

    if (!$is_palindrome) {
        my @copy = @d;

        foreach my $i (0 .. $i) {
            $d[$l - $i] = $d[$i];
        }

        my $is_greater = 1;

        foreach my $j (0 .. $i) {
            my $cmp = $d[$i + $j + 1] <=> $copy[$i + $j + 1];

            if ($cmp > 0) {
                last;
            }
            if ($cmp < 0) {
                $is_greater = 0;
                last;
            }
        }

        if ($is_greater) {
            return fromdigits(\@d, $base);
        }
    }

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

#
## Run some tests
#

my @palindromes = do {
    my $x = 0;
    my @list;
    for (1 .. 61) {
        push @list, $x;
        $x = next_palindrome($x);
    }
    @list;
};

is_deeply(
          \@palindromes,
          [0,   1,   2,   3,   4,   5,   6,   7,   8,   9,   11,  22,  33,  44,  55,  66,  77,  88,  99,  101, 111, 121,
           131, 141, 151, 161, 171, 181, 191, 202, 212, 222, 232, 242, 252, 262, 272, 282, 292, 303, 313, 323, 333, 343,
           353, 363, 373, 383, 393, 404, 414, 424, 434, 444, 454, 464, 474, 484, 494, 505, 515
          ]
         );

is(next_palindrome(10),    11);
is(next_palindrome(11),    22);
is(next_palindrome(12),    22);
is(next_palindrome(110),   111);
is(next_palindrome(111),   121);
is(next_palindrome(112),   121);
is(next_palindrome(120),   121);
is(next_palindrome(121),   131);
is(next_palindrome(1234),  1331);
is(next_palindrome(12345), 12421);

is(next_palindrome(8887),  8888);
is(next_palindrome(8888),  8998);
is(next_palindrome(8889),  8998);
is(next_palindrome(88887), 88888);
is(next_palindrome(88888), 88988);
is(next_palindrome(88889), 88988);
is(next_palindrome(9998),  9999);
is(next_palindrome(99998), 99999);
is(next_palindrome(9999),  10001);
is(next_palindrome(99999), 100001);

is(next_palindrome(12311), 12321);
is(next_palindrome(1321),  1331);
is(next_palindrome(1331),  1441);
is(next_palindrome(13530), 13531);
is(next_palindrome(13520), 13531);
is(next_palindrome(13521), 13531);
is(next_palindrome(13530), 13531);
is(next_palindrome(13531), 13631);
is(next_palindrome(13540), 13631);
is(next_palindrome(13532), 13631);

is(next_palindrome(1234, 2), 1241);
is(next_palindrome(1234, 3), 1249);
is(next_palindrome(1234, 4), 1265);
is(next_palindrome(1234, 5), 1246);
is(next_palindrome(1234, 6), 1253);

is(next_palindrome(12345, 2), 12483);
is(next_palindrome(12345, 3), 12382);
is(next_palindrome(12345, 4), 12355);
is(next_palindrome(12345, 5), 12348);
is(next_palindrome(12345, 6), 12439);
