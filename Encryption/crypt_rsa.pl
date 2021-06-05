#!/usr/bin/perl

# Using Crypt::RSA with a specific private key.

use 5.014;
use Crypt::RSA;

my $rsa = Crypt::RSA->new;
my $key = Crypt::RSA::Key->new;

my ($public, $private) =
  $key->generate(
                 p => "94424081139901371883469166542407095517576260048697655243",
                 q => "79084622052242264844238683495727691663247340251867615781",
                 e => 65537,
                )
  or die "error";

my $cyphertext = $rsa->encrypt(
                               Message => "Hello world!",
                               Key     => $public,
                               Armour  => 1,
                              )
  || die $rsa->errstr();

say $cyphertext;

my $plaintext = $rsa->decrypt(
                              Cyphertext => $cyphertext,
                              Key        => $private,
                              Armour     => 1,
                             )
  || die $rsa->errstr();

say $plaintext;
