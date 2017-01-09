#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 January 2017
# https://github.com/trizen

# A general purpose implementation of the RSA encryption algorithm.

use 5.010;
use strict;
use autodie;
use warnings;

use Math::BigNum qw(:constant);
use Math::Prime::Util qw(random_strong_prime);

use Getopt::Long qw(GetOptions);

my $bits     = 1024;
my $decrypt  = 0;
my $generate = 0;

my $public  = 'public.rsa';
my $private = 'private.rsa';

my $in_fh  = \*STDIN;
my $out_fh = \*STDOUT;

sub usage {
    print <<"EOT";
usage: $0 [options] [<input] [>output]

options:
    -g --generate! : generate the private and public keys
    -b --bits=i    : n-bit prime numbers (default: $bits)

    -d --decrypt!  : decrypt mode (default: $decrypt)
       --public=s  : public key file (default: $public)
       --private=s : private key file (default: $private)

    -i --input=s   : input file (default: /dev/stdin)
    -o --outpus=s  : output file (default: /dev/stdout)

    --help      : prints this message

example:
    perl $0 --generate
    perl $0 < input.txt > enc.rsa
    perl $0 -d < enc.rsa > decoded.txt
EOT
    exit;
}

GetOptions(
           'bits=i'    => \$bits,
           'decrypt!'  => \$decrypt,
           'generate!' => \$generate,
           'public=s'  => \$public,
           'private=s' => \$private,
           'input=s'   => \$in_fh,
           'output=s'  => \$out_fh,
           'help'      => \&usage,
          )
  or die("Error in command line arguments\n");

if (!ref($in_fh)) {
    open my $fh, '<', $in_fh;
    $in_fh = $fh;
}

if (!ref($out_fh)) {
    open my $fh, '>', $out_fh;
    $out_fh = $fh;
}

if ($generate) {

    say "** Generating <<$public>> and <<$private>> files...";

    # Make sure we have enough bits
    if ($bits < 128) {
        $bits = 128;
    }

    # Make sure `bits` is a power of two
    if ($bits & ($bits - 1)) {
        $bits = 2 << int(log($bits) / log(2));
    }

    my $p = random_strong_prime($bits);
    my $q = random_strong_prime($bits);

    my $n = $p * $q;
    my $phi = ($p - 1) * ($q - 1);

    # Choosing `e` (part of the public key)
    my $e;
    do {
        $e = 1->irand($n);
    } until ($e < $phi and $e->gcd($phi) == 1);

    # Computing `d` (part of the private key)
    my $d = $e->modinv($phi);

    open my $public_fh, '>', $public;
    print $public_fh "$bits $e $n";
    close $public_fh;

    open my $private_fh, '>', $private;
    print $private_fh "$bits $d $n";
    close $private_fh;

    say "** Done!";
    exit;
}

sub decrypt {
    my ($bits, $d, $n) = map { Math::BigNum->new($_) } do {
        open my $fh, '<', $private;
        split(' ', scalar <$fh>);
    };

    $bits >>= 2;
    $bits += 2;

    while (1) {
        my $len = read($in_fh, my ($message), $bits);

        my $size = unpack('S', $message) || last;

        $message = unpack('b*', substr($message, 2));
        $message = substr($message, 0, $size);

        my $c = Math::BigNum->new($message, 2);
        my $M = $c->modpow($d, $n);

        print $out_fh pack('b*', substr($M->as_bin, 1));

        last if $len != $bits;
    }
}

sub encrypt {
    my ($bits, $e, $n) = map { Math::BigNum->new($_) } do {
        open my $fh, '<', $public;
        split(' ', scalar <$fh>);
    };

    my $mlen = $bits << 1;

    $bits >>= 2;
    $bits -= 1;

    while (1) {
        my $len = read($in_fh, my ($message), $bits);

        my $binary = '1' . join('', unpack('b*', $message));
        my $m = Math::BigNum->new($binary, 2);
        my $c = $m->modpow($e, $n);

        my $bin  = $c->as_bin;
        my $size = length($bin);
        my $mod  = $size % 8;

        $bin .= ('0' x ((($mlen - $size) >> 3) << 3));
        $bin .= ('0' x (8 - $mod)) if $mod;

        print $out_fh pack('S', $size) . pack('b*', $bin);

        last if $len != $bits;
    }
}

if ($decrypt) {
    if (not -e $private) {
        die "File <<$private>> does not exists! (run --generate)\n";
    }
    decrypt();

}
else {
    if (not -e $public) {
        die "File <<$public>> does not exists! (run --generate)\n";
    }
    encrypt();
}
