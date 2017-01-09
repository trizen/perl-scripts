#!/usr/bin/perl

# RSA Encryption example by Phil Massyn (www.massyn.net)
# July 10th 2013

# Modified by Daniel Șuteu (09 January 2017):
#  - `e` is now randomly chosen, such that gcd(e, phi(n)) = 1
#  - simplifications in the encryption/decryption of a message

use 5.010;
use strict;

use Math::BigNum qw(:constant);
use Math::Prime::Util qw(random_strong_prime);

my $message = shift(@ARGV) // "Hello, world!";

# == key generation

# We chose the number of bits such that p*q > m
my $bits = 128->max(4 * length($message) + 2);

my $p = random_strong_prime($bits);
my $q = random_strong_prime($bits);

say "p = $p";
say "q = $q";

my $n = $p * $q;
my $phi = ($p - 1) * ($q - 1);

# == choosing `e`
my $e;
do {
    $e = 1->irand($phi);
} until ($e->gcd($phi) == 1);

say "e = $e";

# == computing `d`
my $d = $e->modinv($phi);

say "d = $d";

# == encryption
my $m = Math::BigNum->new('1' . join('', unpack('b*', $message)), 2);

say "m = $m";

my $c = $m->modpow($e, $n);

say "c = $c";

# == decryption
my $M = $c->modpow($d, $n);

say "M = $M";

my $orig = pack('b*', substr($M->as_bin, 1));

if ($orig ne $message) {
    die "Decryption failed: <<$orig>> != <<$message>>\n";
}

say $orig;
