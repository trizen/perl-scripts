#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 19 March 2021
# License: GPLv3
# https://github.com/trizen

# A new text encoding scheme, encoding bytes into a large integer, based on prime numbers.

# Given a string of bytes, the str2int() function returns back an integer that can be unambiguously
# decoded by the int2str() function back into the original string of bytes, using primes and prime factorization.

# This process becomes very slow for large strings, therefore it's recommended only for small strings (up to 500-1000 bytes).

# The digits 0..9 are encoded as:
#   853048, 260151, 438257, 1149418, 760322, 517496, 1269824, 885659, 605753, 1019968

# The letters 'a'..'z' are encoded as:
#   7828810, 1980100, 2040301, 6205356, 2164339, 6558310, 2293305, 5251510, 5396709, 3849553, 10923261, 2637910, 2710731, 6162964, 8510520, 9138039, 6655789, 3094996, 6998519, 9843246, 5140920, 7534364, 7718875, 10354816, 3691599, 14221286

# The codepoints 0..32 are encoded as:
#   654, 39, 305, 205, 366, 4609, 904, 2710, 1810, 4764, 14864, 4069, 9465, 6315, 29620, 16542, 11034, 45517, 15220, 58775, 66274, 23299, 45025, 30025, 33826, 63532, 70673, 137247, 52230, 57691, 104577, 69729, 124985

use utf8;
use 5.020;
use strict;
use warnings;

use open IO => ':utf8';
use experimental qw(signatures);

use List::Util qw(max);
use Encode qw(encode_utf8 decode_utf8);

use ntheory qw(vecprod);
use Math::Prime::Util::GMP qw(:all);

use Test::More tests => 3;

# Takes a string of bytes and returns an integer
sub str2int ($str) {

    my @bytes = unpack('C*', $str);
    my $base  = 1 + max(1, max(@bytes));

    for (my $k = 1 ; $k < $base ; ++$k) {

        unshift @bytes, $k;
        push @bytes, 1;

        for (1 .. $k) {
            my $enc = fromdigits(\@bytes, ++$base);
            return vecprod($enc, $base) if is_prime($enc);
        }

        shift @bytes;
        pop @bytes;
    }

    die "Encoding failed!";    # should never happen
}

# Takes an integer, and returns a string of bytes
sub int2str ($int) {
    my (@factors) = factor($int);

    my $enc   = pop @factors;
    my $base  = vecprod(@factors);
    my @bytes = todigits($enc, $base);

    shift @bytes;
    pop @bytes;

    pack('C*', @bytes);
}

is(join(', ', map { int2str(str2int($_)) } 'a' .. 'z'),         join(', ', 'a' .. 'z'));
is(join(', ', map { int2str(str2int($_)) } 0 .. 255),           join(', ', 0 .. 255));
is(join(', ', map { ord(int2str(str2int(chr($_)))) } 0 .. 255), join(', ', 0 .. 255));

my $str = encode_utf8("Hello, world! 😃");

say str2int($str);
say int2str(str2int($str));

__END__
2020269913412456598059907107141359388654948090049817
Hello, world! 😃
