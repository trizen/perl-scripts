#!/usr/bin/perl

# Author: Trizen
# Date: 03 March 2022
# https://github.com/trizen

# A simple encryption cihpher, using XOR with SHA-512 of the key and substring shuffling.

# WARNING: should NOT be used for encrypting real-world data.

# See also:
#   https://en.wikipedia.org/wiki/Block_cipher
#   https://en.wikipedia.org/wiki/XOR_cipher

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);
use ntheory qw(random_bytes);
use Digest::SHA qw(sha512);

use constant {
              ROUNDS => 13,    # how many encryption rounds to perform
             };

sub encrypt ($str, $key) {

    if (length($str) > 64) {
        die "Input string is too long. Max size: 64\n";
    }

    if (length($str) != 64) {
        $str .= random_bytes(64 - length($str));
    }

    $key = sha512($key);
    $str ^= $key;

    my $i = my $l = length($str);

    for (1 .. ROUNDS) {
        $str =~ s/(.{$i})(.)/$2$1/sg while (--$i > 0);
        $str ^= $key;
        $str =~ s/(.{$i})(.)/$2$1/sg while (++$i < $l);
        $str ^= $key;
    }

    return $str;
}

sub decrypt ($str, $key, $len = 64) {

    $key = sha512($key);
    $str ^= $key;

    my $i = my $l = length($str);

    for (1 .. ROUNDS) {
        $str =~ s/(.)(.{$i})/$2$1/sg while (--$i > 0);
        $str ^= $key;
        $str =~ s/(.)(.{$i})/$2$1/sg while (++$i < $l);
        $str ^= $key;
    }

    $str = substr($str, 0, $len);
    return $str;
}

my $text = "Hello, world!";
my $key  = "foo";

say decrypt(encrypt($text, $key), $key, length($text));    #=> "Hello, world!"
