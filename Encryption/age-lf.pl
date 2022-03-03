#!/usr/bin/perl

# Author: Trizen
# Date: 02 February 2022
# Edit: 09 February 2022
# https://github.com/trizen

# A large file encryption tool, inspired by Age, using Curve25519 and CBC+Serpent for encrypting data.

# See also:
#   https://github.com/FiloSottile/age
#   https://metacpan.org/pod/Crypt::CBC
#   https://metacpan.org/pod/Crypt::PK::X25519

# This is a simplified version of `plage`, optimized for large files:
#   https://github.com/trizen/perl-scripts/blob/master/Encryption/plage.pl

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Crypt::CBC;
use Crypt::PK::X25519;

use JSON::PP qw(encode_json decode_json);
use Getopt::Long qw(GetOptions :config no_ignore_case);

binmode(STDIN,  ':raw');
binmode(STDOUT, ':raw');

use constant {
              SHORT_APPNAME   => "age-lf",
              BUFFER_SIZE     => 1024 * 1024,
              EXPORT_KEY_BASE => 62,
              VERSION         => '0.01',
             };

my %CONFIG = (
              cipher     => 'Serpent',
              chain_mode => 'CBC',
             );

sub create_cipher ($pass, $cipher = $CONFIG{cipher}, $chain_mode = $CONFIG{chain_mode}) {
    Crypt::CBC->new(
                    -pass       => $pass,
                    -cipher     => 'Cipher::' . $cipher,
                    -chain_mode => lc($chain_mode),
                    -pbkdf      => 'pbkdf2',
                   );
}

sub x25519_from_public ($hex_key) {
    Crypt::PK::X25519->new->import_key(
                                       {
                                        curve => "x25519",
                                        pub   => $hex_key,
                                       }
                                      );
}

sub x25519_from_private ($hex_key) {
    Crypt::PK::X25519->new->import_key(
                                       {
                                        curve => "x25519",
                                        priv  => $hex_key,
                                       }
                                      );
}

sub x25519_random_key {
    while (1) {
        my $key  = Crypt::PK::X25519->new->generate_key;
        my $hash = $key->key2hash;

        next if substr($hash->{pub},  0, 1) eq '0';
        next if substr($hash->{priv}, 0, 1) eq '0';

        next if substr($hash->{pub},  -1) eq '0';
        next if substr($hash->{priv}, -1) eq '0';

        return $key;
    }
}

sub encrypt ($fh, $public_key) {

    # Generate a random ephemeral key-pair.
    my $random_ephem_key = x25519_random_key();

    # Create a shared secret, using the random key and the reciever's public key
    my $shared_secret = $random_ephem_key->shared_secret($public_key);

    my $cipher    = create_cipher($shared_secret);
    my $ephem_pub = $random_ephem_key->key2hash->{pub};
    my $dest_pub  = $public_key->key2hash->{pub};

    my %info = (
                dest       => $dest_pub,
                cipher     => $CONFIG{cipher},
                chain_mode => $CONFIG{chain_mode},
                ephem_pub  => $ephem_pub,
               );

    my $json = encode_json(\%info);
    syswrite(STDOUT, pack("N*", length($json)));
    syswrite(STDOUT, $json);

    $cipher->start('encrypting');

    while (sysread($fh, (my $buffer), BUFFER_SIZE)) {
        syswrite(STDOUT, $cipher->crypt($buffer) // '');
    }

    syswrite(STDOUT, $cipher->finish);
}

sub decrypt ($fh, $private_key) {

    if (not defined $private_key) {
        die "No private key provided!\n";
    }

    if (ref($private_key) ne 'Crypt::PK::X25519') {
        die "Invalid private key!\n";
    }

    sysread($fh, (my $json_length), 32 >> 3);
    sysread($fh, (my $json),        unpack("N*", $json_length));

    my $enc = decode_json($json);

    # Make sure the private key is correct
    if ($enc->{dest} ne $private_key->key2hash->{pub}) {
        die "Incorrect private key!\n";
    }

    # The ephemeral public key
    my $ephem_pub = $enc->{ephem_pub};

    # Import the public key
    my $ephem_pub_key = x25519_from_public($ephem_pub);

    # Recover the shared secret
    my $shared_secret = $private_key->shared_secret($ephem_pub_key);

    # Create the cipher
    my $cipher = create_cipher($shared_secret, $enc->{cipher}, $enc->{chain_mode});

    $cipher->start('decrypting');

    while (sysread($fh, (my $buffer), BUFFER_SIZE)) {
        syswrite(STDOUT, $cipher->crypt($buffer) // '');
    }

    syswrite(STDOUT, $cipher->finish);
}

sub export_key ($x_public_key) {
    require Math::BigInt;
    Math::BigInt->from_hex($x_public_key)->to_base(EXPORT_KEY_BASE);
}

sub decode_exported_key ($public_key) {
    require Math::BigInt;
    Math::BigInt->from_base($public_key, EXPORT_KEY_BASE)->to_hex;
}

sub decode_public_key ($key) {
    x25519_from_public(decode_exported_key($key));
}

sub decode_private_key ($file) {

    if (not -T $file) {
        die "Invalid key file!\n";
    }

    open(my $fh, '<:utf8', $file)
      or die "Can't open file <<$file>>: $!";

    local $/;
    my $key = decode_json(<$fh>);
    x25519_from_private(decode_exported_key($key->{x_priv}));
}

sub generate_new_key {

    my $x25519_key = x25519_random_key();
    my $x_key      = $x25519_key->key2hash;

    my $x_public_key  = $x_key->{pub};
    my $x_private_key = $x_key->{priv};

    my %info = (
                x_pub  => export_key($x_public_key),
                x_priv => export_key($x_private_key),
               );

    say encode_json(\%info);
    warn sprintf("Public key: %s\n", $info{x_pub});
    return 1;
}

sub help ($exit_code) {

    local $" = " ";

    my @chaining_modes = map { uc } qw(cbc pcbc cfb ofb ctr);

    my @valid_ciphers = sort grep {
        eval { require "Crypt/Cipher/$_.pm"; 1 };
      } qw(
      AES Anubis Twofish Camellia Serpent SAFERP
      );

    print <<"EOT";
usage: $0 [options] [<input] [>output]

Encryption and signing:

    -g --generate-key   : Generate a new key-pair
    -e --encrypt=key    : Encrypt data with a given public key
    -d --decrypt=key    : Decrypt data with a given private key file
       --cipher=s       : Change the symmetric cipher (default: $CONFIG{cipher})
                          valid: @valid_ciphers
       --chain-mode=s   : Change the chaining mode (default: $CONFIG{chain_mode})
                          valid: @chaining_modes

Examples:

    # Generate a key-pair
    $0 -g > key.txt

    # Encrypt a message for Alice
    $0 -e=RBZ17knALkL5N1AWYjAgBwZDpQpQmvLbuTphVAx7XQC < message.txt > message.enc

    # Decrypt a received message
    $0 -d=key.txt < message.enc > message.txt
EOT

    exit($exit_code);
}

sub version {

    my $width = 20;

    printf("%-*s %s\n", $width, SHORT_APPNAME,        VERSION);
    printf("%-*s %s\n", $width, 'Crypt::CBC',         $Crypt::CBC::VERSION);
    printf("%-*s %s\n", $width, 'Crypt::PK::X25519',  $Crypt::PK::X25519::VERSION);
    printf("%-*s %s\n", $width, 'Crypt::PK::Ed25519', $Crypt::PK::Ed25519::VERSION);

    exit(0);
}

GetOptions(
           'cipher=s'          => \$CONFIG{cipher},
           'chain-mode|mode=s' => \$CONFIG{chain_mode},
           'g|generate-key!'   => \$CONFIG{generate_key},
           'e|encrypt=s'       => \$CONFIG{encrypt},
           'd|decrypt=s'       => \$CONFIG{decrypt},
           'v|version'         => \&version,
           'h|help'            => sub { help(0) },
          )
  or die("Error in command line arguments\n");

if ($CONFIG{generate_key}) {
    generate_new_key();
    exit 0;
}

sub get_input_fh {
    my $fh = \*STDIN;

    if (@ARGV and -t $fh) {
        sysopen(my $file_fh, $ARGV[0], 0)
          or die "Can't open file <<$ARGV[0]>> for reading: $!";
        return $file_fh;
    }

    return $fh;
}

if (defined($CONFIG{encrypt})) {
    my $x_pub = decode_public_key($CONFIG{encrypt});
    encrypt(get_input_fh(), $x_pub);
    exit 0;
}

if (defined($CONFIG{decrypt})) {
    my $x_priv = decode_private_key($CONFIG{decrypt});
    decrypt(get_input_fh(), $x_priv);
    exit 0;
}

help(1);
