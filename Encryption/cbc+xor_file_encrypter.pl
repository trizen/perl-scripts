#!/usr/bin/perl

# Author: Trizen
# Date: 18 March 2022
# https://github.com/trizen

# A simple file encryption cihpher, using XOR with SHA-512 of the key and substring shuffling.

# WARNING: should NOT be used for encrypting real-world data.

# See also:
#   https://en.wikipedia.org/wiki/Block_cipher
#   https://en.wikipedia.org/wiki/XOR_cipher

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

binmode(STDOUT, ':raw');

package SimpleXORCipher {

    require Digest::SHA;

    sub new ($class, %opt) {

        $opt{rounds} ||= 1;

        if (!defined($opt{key})) {
            die "Undefined key parameter";
        }

        if ($opt{rounds} <= 0) {
            die "Number of rounds must be > 0";
        }

        $opt{key} = Digest::SHA::sha512($opt{key});

        bless \%opt, $class;
    }

    sub encrypt ($self, $str) {

        my $key = $self->{key};
        $str ^= $key;

        my $i = my $l = length($str);

        for my $k (1 .. $self->{rounds}) {
            $str =~ s/(.{$i})(.)/$2$1/sg while (--$i > 0);
            $str ^= Digest::SHA::sha512($key . $k);
            $str =~ s/(.{$i})(.)/$2$1/sg while (++$i < $l);
            $str ^= Digest::SHA::sha512($k . $key);
        }

        return $str;
    }

    sub decrypt ($self, $str) {

        my $key = $self->{key};

        my $i = my $l = length($str);

        for my $k (reverse(1 .. $self->{rounds})) {
            $str ^= Digest::SHA::sha512($k . $key);
            $str =~ s/(.)(.{$i})/$2$1/sg while (--$i > 0);
            $str ^= Digest::SHA::sha512($key . $k);
            $str =~ s/(.)(.{$i})/$2$1/sg while (++$i < $l);
        }

        $str ^= $key;
        return $str;
    }

    sub cbc_encrypt ($crypt, $iv, $result, $blocks) {
        my ($i, $r) = ($$iv, $$result);
        foreach (@$blocks) {
            $r .= $i = $crypt->encrypt($i ^ $_);
        }
        ($$iv, $$result) = ($i, $r);
    }

    sub cbc_decrypt ($crypt, $iv, $result, $blocks) {
        my ($i, $r) = ($$iv, $$result);
        foreach (@$blocks) {
            $r .= $i ^ $crypt->decrypt($_);
            $i = $_;
        }
        ($$iv, $$result) = ($i, $r);
    }

    sub generate_iv ($self) {
        my $iv = Digest::SHA::sha512($self->{key});
        foreach my $i (1 .. $self->{rounds}) {
            $iv = Digest::SHA::sha512(($i % 2 == 0) ? $iv : scalar(reverse($iv)));
        }
        return $iv;
    }
}

use constant {BUFFER_SIZE => 1024 * 10,};

sub encrypt_file ($file, $key) {

    my $crypt = SimpleXORCipher->new(key => $key);
    my $iv    = $crypt->generate_iv;

    open(my $fh, '<:raw', $file)
      or die "can't open file <<$file>> for reading: $!";

    my $size = -s $file;
    $crypt->cbc_encrypt(\$iv, \(my $size_enc), [pack("N*", $size)]);
    print $size_enc;

    my $key_size = length($crypt->{key});

    while (read($fh, (my $buffer), BUFFER_SIZE)) {
        my @blocks = unpack("(a$key_size)*", $buffer);
        $crypt->cbc_encrypt(\$iv, \(my $result), \@blocks);
        print $result;
    }

    close $fh;
}

sub decrypt_file ($file, $key) {

    my $crypt    = SimpleXORCipher->new(key => $key);
    my $iv       = $crypt->generate_iv;
    my $key_size = length($crypt->{key});

    open(my $fh, '<:raw', $file)
      or die "can't open file <<$file>> for reading: $!";

    read($fh, (my $size), $key_size);

    $crypt->cbc_decrypt(\$iv, \(my $size_dec), [$size]);
    $size = unpack("N*", substr($size_dec, 0, 4));

    my $dec_size = 0;

    while (read($fh, (my $buffer), BUFFER_SIZE)) {
        my @blocks = unpack("(a$key_size)*", $buffer);

        $crypt->cbc_decrypt(\$iv, \(my $result), \@blocks);
        $dec_size += $key_size * scalar(@blocks);

        if ($dec_size > $size) {
            print substr($result, 0, (scalar(@blocks) - 1) * $key_size, '');
            print substr($result, 0,                                    $size % $key_size);
            last;
        }
        else {
            print $result;
        }
    }

    close $fh;
}

sub help ($exit_code = 0) {
    print <<"EOT";
usage: $0 [options] [input file]

options:

    -k  --key=s    : encryption/decryption symmetric key
    -d  --decrypt  : decryption mode
    -h  --help     : print this message

example:

    # Encrypt file
    perl $0 -k=foo msg.txt > msg.enc

    # Decrypt file
    perl $0 -d -k=foo msg.enc > msg.dec
EOT

    exit($exit_code);
}

use Getopt::Long qw(GetOptions);

my $key     = undef;
my $decrypt = 0;

GetOptions(
           "d|decrypt" => \$decrypt,
           "key=s"     => \$key,
           "h|help"    => sub { help(0) },
          )
  or die("Error in command line arguments\n");

my $input_file = $ARGV[0] // help(2);

if ($decrypt) {
    decrypt_file($input_file, $key);
}
else {
    encrypt_file($input_file, $key);
}
