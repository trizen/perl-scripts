#!/usr/bin/perl

# RSA key generation, backdoored using curve25519.

# Inspired by:
#   https://gist.github.com/ryancdotorg/18235723e926be0afbdd

# See also:
#   https://eprint.iacr.org/2002/183.pdf
#   https://www.reddit.com/r/crypto/comments/2ss1v5/rsa_key_generation_backdoored_using_curve25519/

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use ntheory qw(:all);
use Crypt::PK::X25519;

sub generate_rsa_key ($bits = 2048, $ephem_pub = "", $pos = 80, $seed = undef) {

    if (defined($seed)) {
        csrand($seed);
    }

    my $p = random_strong_prime($bits >> 1);
    my $q = random_strong_prime($bits >> 1);

    if ($p > $q) {
        ($p, $q) = ($q, $p);
    }

    my $n = ($p * $q);

    # Embed the public key into the modulus
    my $n_hex = todigitstring($n, 16);
    substr($n_hex, $pos, length($ephem_pub), $ephem_pub);

    # Recompute n, reusing p in computing a new q
    $n = fromdigits($n_hex, 16);
    $q = next_prime(divint($n, $p));
    $n = $p * $q;

    my $phi = ($p - 1) * ($q - 1);

    my $e = 0;
    for (my $k = 16 ; gcd($e, $phi) != 1 ; ++$k) {
        $e = 2**$k + 1;
    }

    my $d = invmod($e, $phi);

    return
      scalar {
              e => $e,
              p => $p,
              q => $q,
              d => $d,
              n => $n,
             };
}

sub recover_rsa_key ($bits, $n, $master_private_key, $pos) {

    my $n_hex     = todigitstring($n, 16);
    my $ephem_pub = substr($n_hex, $pos, 64);    # extract the embeded public key

    # Import the public key
    my $ephem_pub_key = Crypt::PK::X25519->new->import_key(
                                                           {
                                                            curve => "x25519",
                                                            pub   => $ephem_pub,
                                                           }
                                                          );

    # Import the master private key
    my $master_priv_key = Crypt::PK::X25519->new->import_key(
                                                             {
                                                              curve => "x25519",
                                                              priv  => $master_private_key,
                                                             }
                                                            );

    # Recover the shared secret that was used as a seed value for the random number generator
    my $recovered_secret = $master_priv_key->shared_secret($ephem_pub_key);

    # Recompute the RSA key, given the embeded public key and the seed value
    generate_rsa_key($bits, $ephem_pub, $pos, $recovered_secret);
}

my $BITS = 2048;            # must be >= 1024
my $POS  = $BITS >> 5;

# Public and private master keys
my $MASTER_PUBLIC  = "c10811d4e424305c6696f9b5f787efb67f80530e6115e367bd7967ba05093e3d";
my $MASTER_PRIVATE = "3a35b10511bcd20bcb9b12bd73ab9ad0bf8f7f469ffb70d2ae8fb110b761df97";

# Generate a random ephemeral key-pair, using in created the shared secret
my $random_ephem_key = Crypt::PK::X25519->new->generate_key;

# Import the master public key
my $master_public_key = Crypt::PK::X25519->new->import_key(
                                                           {
                                                            curve => "x25519",
                                                            pub   => $MASTER_PUBLIC,
                                                           }
                                                          );

my $ephem_pub     = $random_ephem_key->key2hash->{pub};
my $shared_secret = $random_ephem_key->shared_secret($master_public_key);

# Generate the backdoored RSA key, using the ephemeral random public key, which will be embeded
# in the RSA modulus, and pass the shared secret value as a seed for the random number generator.
my $rsa_key = generate_rsa_key($BITS, $ephem_pub, $POS, $shared_secret);

my $message = "Hello, world!";
my $m       = fromdigits(unpack("H*", $message), 16);    # message

if ($m >= $rsa_key->{n}) {
    die "Message is too long!";
}

my $c = powmod($m, $rsa_key->{e}, $rsa_key->{n});        # encoded message
my $M = powmod($c, $rsa_key->{d}, $rsa_key->{n});        # decoded message

say pack("H*", todigitstring($M, 16));

# Recover the RSA key, given the RSA modulus n and the private master key.
my $recovered_rsa = recover_rsa_key($BITS, $rsa_key->{n}, $MASTER_PRIVATE, $POS);

# Decode the encrypted message, using the recovered RSA key
my $decoded_message = powmod($c, $recovered_rsa->{d}, $rsa_key->{n});

# Print the decoded message, decoded with the recovered key
say pack("H*", todigitstring($decoded_message, 16));
