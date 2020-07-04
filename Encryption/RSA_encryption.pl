#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 09 January 2017
# https://github.com/trizen

# A general purpose implementation of the RSA encryption algorithm.

use utf8;
use 5.010;
use strict;
use autodie;
use warnings;

use Math::AnyNum qw(:overload gcd irand powmod invmod);
use Math::Prime::Util qw(random_strong_prime urandomm);

use Config qw(%Config);
use Getopt::Long qw(GetOptions);

use constant shortsize => $Config{shortsize};

my $bits     = 2048;
my $decrypt  = 0;
my $generate = 0;
my $sign     = 0;

my $public  = 'public.rsa';
my $private = 'private.rsa';

my $in_fh  = \*STDIN;
my $out_fh = \*STDOUT;

sub usage {
    print <<"EOT";
usage: $0 [options] [<input] [>output]

options:
    -g --generate! : generate the private and public keys
    -b --bits=i    : size of the prime numbers in bits (default: $bits)

    -d --decrypt!  : decrypt mode (default: ${\($decrypt ? 'true' : 'false')})
    -s --sign!     : sign/unsign mode (default: ${\($sign ? 'true' : 'false')})

    --public=s     : public key file (default: $public)
    --private=s    : private key file (default: $private)

    -i --input=s   : input file (default: /dev/stdin)
    -o --output=s  : output file (default: /dev/stdout)

    -h --help      : prints this message

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
           'sign!'     => \$sign,
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
        $bits = 2 << (log($bits) / log(2));
    }

    my $p = Math::AnyNum->new(random_strong_prime($bits));
    my $q = Math::AnyNum->new(random_strong_prime($bits));

    my $n = $p * $q;
    my $ϕ = ($p - 1) * ($q - 1);

    # Choosing `e` (part of the public key)
#<<<
    my $e;
    do {
        say "** Choosing e...";
        $e = irand(65537, $n);
    } until (
            $e < $ϕ
        and gcd($e,     $ϕ    ) == 1
        and gcd($e - 1, $p - 1) == 2
        and gcd($e - 1, $q - 1) == 2
    );
#>>>

    # Computing `d` (part of the private key)
    my $d = invmod($e, $ϕ);

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
    my ($bits, $d, $n) = map { Math::AnyNum->new($_) } do {
        open my $fh, '<', $private;
        split(' ', scalar <$fh>);
    };

    $bits >>= 2;
    $bits += shortsize + shortsize;

    while (1) {
        my $len = read($in_fh, my ($message), $bits) || last;

        my ($s1, $s2, $msg) = unpack('SSb*', $message);

        my $c = Math::AnyNum->new(substr($msg, 0, $s1), 2);
        my $M = powmod($c, $d, $n);

        print $out_fh pack('b*', substr($M->as_bin, 1, $s2));

        last if $len != $bits;
    }
}

sub encrypt {
    my ($bits, $e, $n) = map { Math::AnyNum->new($_) } do {
        open my $fh, '<', $public;
        split(' ', scalar <$fh>);
    };

    my $L = $bits << 1;

    $bits >>= 2;
    $bits -= 1;

    while (1) {
        my $len = read($in_fh, my ($message), $bits) || last;

        my $B = '1' . unpack('b*', $message);

        if ($bits != $len) {
            $B .= join('', map { urandomm("2") } 1 .. ($L - ($len << 3) - 8));
        }

        my $m = Math::AnyNum->new($B, 2);
        my $c = powmod($m, $e, $n);
        my $bin = $c->as_bin;

        print $out_fh pack("SSb$L", length($bin), $len << 3, $bin);

        last if $len != $bits;
    }
}

if ($sign) {
    ($private, $public) = ($public, $private);
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
