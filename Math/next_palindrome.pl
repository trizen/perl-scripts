#!/usr/bin/perl

# A nice algorithm, due to David A. Corneth (Jun 06 2014), for generating the next palindrome from a given palindrome.

# See also:
#   https://oeis.org/A002113
#   https://en.wikipedia.org/wiki/Palindromic_number

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

sub next_palindrome ($n) {

    my @d = split(//, $n);
    my $l = $#d;
    my $i = ((scalar(@d) + 1) >> 1) - 1;

    while ($i >= 0 and $d[$i] == 9) {
        $d[$i] = 0;
        $d[$l - $i] = 0;
        $i--;
    }

    if ($i >= 0) {
        $d[$i]++;
        $d[$l - $i] = $d[$i];
    }
    else {
        @d = (0) x (scalar(@d) + 1);
        $d[0]  = 1;
        $d[-1] = 1;
    }

    join('', @d);
}

my $n = 1;
for (1 .. 100) {    # first 100 palindromes
    print("$n, ");
    $n = next_palindrome($n);
}
say "\n";

say next_palindrome(99977999);      #=> 99988999
say next_palindrome(99988999);      #=> 99999999
say next_palindrome(99999999);      #=> 100000001

say '';

say next_palindrome("51818186768181815");    #=> 51818186868181815
say next_palindrome("51818186868181815");    #=> 51818186968181815
say next_palindrome("51818186968181815");    #=> 51818187078181815
