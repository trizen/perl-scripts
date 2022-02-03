#!/usr/bin/perl

# Author: Trizen
# Date: 02 February 2022
# Edit: 03 February 2022
# https://github.com/trizen

# A message encryption tool, inspired by Age and GnuPG, using Curve25519 and CBC for encrypting data.

# Main features include:
#   - generation of X25519 and Ed25519 key-pairs
#   - encryption and decryption of messages
#   - signing and verification of signatures
#   - compression support
#   - import and export of public keys
#   - local encryption of private keys
#   - local keyring, similar to PGP
#   - ASCII armor

# See also:
#   https://github.com/FiloSottile/age
#   https://metacpan.org/pod/Crypt::CBC
#   https://metacpan.org/pod/Crypt::PK::X25519
#   https://metacpan.org/pod/Crypt::PK::Ed25519

use 5.020;
use strict;
use warnings;

no warnings 'once';
use experimental qw(signatures);

use Crypt::CBC;

use Digest::SHA qw(sha256_hex);
use Crypt::PK::X25519;
use Crypt::PK::Ed25519;

use Term::UI;
use Term::ReadLine;
use Term::ReadKey qw(ReadMode);

use JSON::PP qw(encode_json decode_json);
use Getopt::Long qw(GetOptions :config no_ignore_case);
use MIME::Base64 qw(encode_base64 decode_base64);
use File::Spec::Functions qw(catdir catfile curdir);
use Storable qw(store retrieve);

use constant {
              SHORT_APPNAME     => "plage",
              JSON_LENGTH_WIDTH => 6,
              EXPORT_KEY_BASE   => 62,
              VERSION           => '0.01',
             };

my $term = Term::ReadLine->new(SHORT_APPNAME);

my $plage_dir = catdir(get_config_dir(), SHORT_APPNAME);

if (not -d $plage_dir) {
    require File::Path;
    File::Path::make_path($plage_dir)
      or die "Can't create directory: $plage_dir";
}

my $keyring_file = catfile($plage_dir, 'keys.dat');

if (not -f $keyring_file) {
    store(
          {
           version => VERSION,
          },
          $keyring_file
         );
}

my %KEYRING = %{retrieve($keyring_file)};

my %CONFIG = (
              cipher          => 'Serpent',
              sign            => 0,
              compress        => 1,
              compress_method => 'gzip',
             );

my %COMPRESSION_METHODS = (
                           gzip  => \&gzip_compress_data,
                           zstd  => \&zstd_compress_data,
                           zip   => \&zip_compress_data,
                           xz    => \&xz_compress_data,
                           bzip2 => \&bzip2_compress_data,
                           lzop  => \&lzop_compress_data,
                           lzf   => \&lzf_compress_data,
                           lzip  => \&lzip_compress_data,
                          );

sub create_cipher ($pass, $cipher = $CONFIG{cipher}) {
    Crypt::CBC->new(
                    -pass   => $pass,
                    -cipher => 'Cipher::' . $cipher,
                    -pbkdf  => 'pbkdf2'
                   );
}

sub get_config_dir {

    my $xdg_config_home = $ENV{XDG_CONFIG_HOME};

    if ($xdg_config_home and -d -w $xdg_config_home) {
        return $xdg_config_home;
    }

    my $home_dir =
         $ENV{HOME}
      || $ENV{LOGDIR}
      || (($^O eq 'MSWin32') ? '\Local Settings\Application Data' : ((getpwuid($<))[7] || `echo -n ~`));

    if (not -d -w $home_dir) {
        $home_dir = curdir();
    }

    return catdir($home_dir, '.config');
}

sub x25519_from_public ($hex_key) {
    Crypt::PK::X25519->new->import_key(
                                       {
                                        curve => "x25519",
                                        pub   => $hex_key,
                                       }
                                      );
}

sub ed25519_from_public ($hex_key) {
    Crypt::PK::Ed25519->new->import_key(
                                        {
                                         curve => "ed25519",
                                         pub   => $hex_key,
                                        }
                                       );
}

sub ed25519_from_private ($hex_key) {
    Crypt::PK::Ed25519->new->import_key(
                                        {
                                         curve => "ed25519",
                                         priv  => $hex_key,
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

sub x25519_from_private_raw ($raw_key) {
    Crypt::PK::X25519->new->import_key_raw($raw_key, 'private');
}

sub ed25519_from_private_raw ($raw_key) {
    Crypt::PK::Ed25519->new->import_key_raw($raw_key, 'private');
}

sub x25519_random_key {
    Crypt::PK::X25519->new->generate_key;
}

sub ed25519_random_key {
    Crypt::PK::Ed25519->new->generate_key;
}

sub uncompress_data ($data) {
    require IO::Uncompress::AnyUncompress;
    IO::Uncompress::AnyUncompress::anyuncompress(\$data, \my $uncompressed)
      or die "anyuncompress failed: $IO::Uncompress::AnyUncompress::AnyUncompressError\n";
    return $uncompressed;
}

sub gzip_compress_data ($data) {
    require IO::Compress::Gzip;
    IO::Compress::Gzip::gzip(\$data, \my $compressed)
      or die "gzip failed: $IO::Compress::Gzip::GzipError\n";
    return $compressed;
}

sub zip_compress_data ($data) {
    require IO::Compress::Zip;
    IO::Compress::Zip::zip(\$data, \my $compressed)
      or die "zip failed: $IO::Compress::Zip::ZipError\n";
    return $compressed;
}

sub lzop_compress_data ($data) {
    require IO::Compress::Lzop;
    IO::Compress::Lzop::lzop(\$data, \my $compressed)
      or die "lzop failed: $IO::Compress::Lzop::LzopError\n";
    return $compressed;
}

sub lzip_compress_data ($data) {
    require IO::Compress::Lzip;
    IO::Compress::Lzip::lzip(\$data, \my $compressed)
      or die "lzop failed: $IO::Compress::Lzip::LzipError\n";
    return $compressed;
}

sub lzf_compress_data ($data) {
    require IO::Compress::Lzf;
    IO::Compress::Lzf::lzf(\$data, \my $compressed)
      or die "lzop failed: $IO::Compress::Lzf::LzfError\n";
    return $compressed;
}

sub bzip2_compress_data ($data) {
    require IO::Compress::Bzip2;
    IO::Compress::Bzip2::bzip2(\$data, \my $compressed)
      or die "bzip2 failed: $IO::Compress::Bzip2::Bzip2Error\n";
    return $compressed;
}

sub xz_compress_data ($data) {
    require IO::Compress::Xz;
    IO::Compress::Xz::xz(\$data, \my $compressed)
      or die "xz failed: $IO::Compress::Xz::XzError\n";
    return $compressed;
}

sub zstd_compress_data ($data) {
    require IO::Compress::Zstd;
    IO::Compress::Zstd::zstd(\$data, \my $compressed)
      or die "zstd failed: $IO::Compress::Zstd::ZstdError\n";
    return $compressed;
}

sub sign_message ($data, $signature_private_key) {
    $signature_private_key->sign_message($data);
}

sub verify_signature ($data, $signature, $signature_public_key) {
    $signature_public_key->verify_message($signature, $data);
}

sub encrypt ($data, $public_key) {

    # Generate a random ephemeral key-pair.
    my $random_ephem_key = x25519_random_key();

    # Create a shared secret, using the random key and the reciever's public key
    my $shared_secret = $random_ephem_key->shared_secret($public_key);

    if ($CONFIG{compress}) {
        $data = $COMPRESSION_METHODS{$CONFIG{compress_method}}($data);
    }

    my $cipher     = create_cipher($shared_secret);
    my $ciphertext = $cipher->encrypt($data);
    my $ephem_pub  = $random_ephem_key->key2hash->{pub};
    my $dest_pub   = $public_key->key2hash->{pub};

    return {
            time       => time,
            dest       => $dest_pub,
            cipher     => $CONFIG{cipher},
            compressed => $CONFIG{compress},
            ephem_pub  => $ephem_pub,
            ciphertext => $ciphertext,
           };
}

sub decrypt ($cipher_data, $private_key) {

    if (not defined $private_key) {
        die "No private key provided!\n";
    }

    if (ref($private_key) ne 'Crypt::PK::X25519') {
        die "Invalid private key!\n";
    }

    my $ephem_pub  = $cipher_data->{ephem_pub};
    my $ciphertext = $cipher_data->{ciphertext};

    # Import the public key
    my $ephem_pub_key = x25519_from_public($ephem_pub);

    # Recover the shared secret
    my $shared_secret = $private_key->shared_secret($ephem_pub_key);

    my $cipher = create_cipher($shared_secret, $cipher_data->{cipher});
    my $data   = $cipher->decrypt($ciphertext);

    if ($cipher_data->{compressed}) {
        $data = uncompress_data($data);
    }

    return $data;
}

sub create_clear_signed_message ($text, $ed_private_key) {

    if (not defined $ed_private_key) {
        die "No signature key provided!\n";
    }

    if (ref($ed_private_key) ne 'Crypt::PK::Ed25519') {
        die "Invalid signature key provided!\n";
    }

    my $signed_message = "-----BEGIN PLAGE SIGNED MESSAGE-----\n";

    $text .= "\n";

    my $signature = sign_message($text, $ed_private_key);

    $signed_message .= ($text =~ s/^/~/mgr);
    $signed_message .= "-----BEGIN PLAGE SIGNATURE-----\n";

    my $ed_pub = $ed_private_key->key2hash->{pub};

    my %info = (
                time   => time,
                sig    => encode_base64($signature),
                ed_pub => $ed_pub,
                x_pub  => $KEYRING{keys}{Ed25519}{$ed_pub}{x_pub},
               );

    my $json_data = encode_json(\%info);
    my $sha256    = sha256_hex($json_data);

    $signed_message .= encode_base64($sha256 . sign_message($sha256, $ed_private_key) . $json_data);
    $signed_message .= "-----END PLAGE SIGNATURE-----\n";

    return $signed_message;
}

sub verify_clear_signed_message ($message, $callback = sub { print $_[0] }) {

    my $collect_msg = 0;
    my $collect_sig = 0;

    my $msg        = '';
    my $base64_sig = '';

    open my $fh, '<:raw', \$message;
    while (defined(my $line = <$fh>)) {
        if ($line =~ /^-----BEGIN PLAGE SIGNED MESSAGE-----\s*\z/) {
            $collect_msg = 1;
        }
        elsif ($line =~ /^-----BEGIN PLAGE SIGNATURE-----\s*\z/) {
            $collect_sig = 1;
            $collect_msg = 0;
        }
        elsif ($line =~ /^-----END PLAGE SIGNATURE-----\s*\z/) {
            last;
        }
        elsif ($collect_msg) {
            $msg .= ($line =~ s/^~//r);
        }
        elsif ($collect_sig) {
            $base64_sig .= $line;
        }
    }

    my $json_data = decode_base64($base64_sig);

    my $sha256     = substr($json_data, 0, 64, '');
    my $sha256_sig = substr($json_data, 0, 64, '');

    if ($sha256 eq '' or $sha256_sig eq '') {
        die "No signature found!\n";
    }

    if (sha256_hex($json_data) ne $sha256) {
        die "The signature has been modified: the SHA256 hash does not match!\n";
    }

    my $info       = eval { decode_json($json_data) } // die "Invalid JSON data!\n";
    my $sig        = decode_base64($info->{sig});
    my $ed_pub     = $info->{ed_pub};
    my $x_pub      = $info->{x_pub};
    my $ed_pub_key = ed25519_from_public($ed_pub);
    my $user_info  = $KEYRING{keys}{Ed25519}{$ed_pub};

    if (not verify_signature($sha256, $sha256_sig, $ed_pub_key)) {
        die "The signature has been modified: invalid signature for the SHA256 hash!\n";
    }

    if (not verify_signature($msg, $sig, $ed_pub_key)) {
        die "Bad signature: the message has been modified!\n";
    }

    $callback->($msg);

    if (defined $user_info) {

        if ($user_info->{x_pub} ne $x_pub) {
            die "The public X25519 key does not match!\n";
        }

        if (export_key($info->{x_pub}, $ed_pub) ne $user_info->{public_key}) {
            die "Public key does not match!\n";
        }

        warn "Signature from $user_info->{username}\n";
    }
    else {
        warn "Public key: " . export_key($info->{x_pub}, $ed_pub) . "\n";
        warn "WARNING: Could not find the key in our keyring!\n";
    }

    warn "Created on: " . scalar localtime($info->{time}) . "\n";
    warn "\nGood signature!\n\n";
    return 1;
}

sub create_armor ($enc) {

    my %info  = %$enc;
    my $armor = "-----BEGIN PLAGE ENCRYPTED DATA-----\n";

    my $ciphertext = delete $info{ciphertext};
    my $json       = encode_json(\%info);
    my $length     = length($json);
    my $content    = sprintf("%*d%s%s", JSON_LENGTH_WIDTH, $length, $json, $ciphertext);

    $armor .= encode_base64($content);
    $armor .= "-----END PLAGE ENCRYPTED DATA-----\n";

    return $armor;
}

sub decode_armor ($armor) {

    my $collect     = 0;
    my $base64_data = '';

    open my $fh, '<:raw', \$armor;
    while (defined(my $line = <$fh>)) {
        if ($line =~ /^-----BEGIN PLAGE ENCRYPTED DATA-----\s*\z/) {
            $collect = 1;
        }
        elsif ($line =~ /^-----END PLAGE ENCRYPTED DATA-----\s*\z/) {
            last;
        }
        elsif ($collect) {
            $base64_data .= $line;
        }
    }

    my $content = decode_base64($base64_data);
    my $length  = substr($content, 0, JSON_LENGTH_WIDTH, '');

    if ($length =~ /^\s*([0-9]+)\z/) {
        $length = 0 + $1;
    }

    if (!$length or $length <= 0) {
        die "Invalid armor!\n";
    }

    my $json       = substr($content, 0, $length, '');
    my $ciphertext = $content;

    my $info = decode_json($json) // die "Invalid JSON data!\n";
    $info->{ciphertext} = $ciphertext;
    return $info;
}

sub export_key ($x_public_key, $ed_public_key) {
    require Math::BigInt;

    my $x  = Math::BigInt->from_hex($x_public_key)->to_base(EXPORT_KEY_BASE);
    my $ed = Math::BigInt->from_hex($ed_public_key)->to_base(EXPORT_KEY_BASE);

    join('-', $x, $ed);
}

sub decode_exported_key ($public_key) {
    require Math::BigInt;

    my ($x, $ed) = split(/\s*-\s*/, $public_key, 2);

    $x  // return;
    $ed // return;

#<<<
    (
        Math::BigInt->from_base($x, EXPORT_KEY_BASE)->to_hex,
        Math::BigInt->from_base($ed, EXPORT_KEY_BASE)->to_hex
    );
#>>>
}

sub read_password ($text) {

    ReadMode('noecho');
    my $passphrase = $term->readline($text);
    ReadMode('restore');
    warn "\n";

    return $passphrase;
}

sub create_cipher_password ($passphrase, $x_public_key, $ed_public_key) {
#<<<
    sha256_hex(
            pack("H*", sha256_hex(pack("H*", $x_public_key)))  .
            pack("H*", sha256_hex($passphrase))                .
            pack("H*", sha256_hex(pack("H*", $ed_public_key)))
    );
#>>>
}

sub decrypt_private_keys ($info, $prompt = 'Passphrase: ') {

    my $x_pub   = $info->{x_pub};
    my $x_priv  = $info->{x_priv};
    my $ed_pub  = $info->{ed_pub};
    my $ed_priv = $info->{ed_priv};

    for (1 .. 10) {

        my $passphrase = '';

        if ($info->{has_password}) {
            $passphrase = read_password($prompt) // last;
        }

        my $pass   = create_cipher_password($passphrase, $x_pub, $ed_pub);
        my $cipher = create_cipher($pass, 'Serpent');

        my $x_raw = $cipher->decrypt($x_priv);
        my $x_key = eval { x25519_from_private_raw($x_raw) } // next;

        if ($x_key->key2hash->{pub} ne $x_pub) {
            next;
        }

        my $ed_raw = $cipher->decrypt($ed_priv);
        my $ed_key = eval { ed25519_from_private_raw($ed_raw) } // next;

        if ($ed_key->key2hash->{pub} ne $ed_pub) {
            next;
        }

        return ($x_key, $ed_key);
    }

    return (undef, undef);
}

sub import_key ($public_key) {
    my ($x_pub, $ed_pub) = decode_exported_key($public_key);

    if (   not defined($x_pub)
        or not defined($ed_pub)
        or length($x_pub) != 64
        or length($ed_pub) != 64) {
        die "Invalid public key!\n";
    }

    if (exists $KEYRING{keys}{X25519}{$x_pub}) {
        die "The X25519 key already exists for username: $KEYRING{keys}{X25519}{$x_pub}{username}\n";
    }

    if (exists $KEYRING{keys}{Ed25519}{$ed_pub}) {
        die "The Ed25519 key already exists for username:  $KEYRING{keys}{Ed25519}{$ed_pub}{username}\n";
    }

    # Make sure the keys work
    my $x_key  = x25519_from_public($x_pub);
    my $ed_key = ed25519_from_public($ed_pub);

    if ($x_key->key2hash->{pub} ne $x_pub) {
        die "Invalid X25519 key!\n";
    }

    if ($ed_key->key2hash->{pub} ne $ed_pub) {
        die "Invalid Ed25519 key!\n";
    }

    my $username = $CONFIG{name} // $term->readline('Username: ') // return;

    $username = make_unique_username($username, $x_pub);

    my %info = (
        time     => time,
        username => $username,

        x_pub  => $x_pub,
        ed_pub => $ed_pub,

        public_key => export_key($x_pub, $ed_pub),
               );

    $KEYRING{keys}{X25519}{$x_pub}   = \%info;
    $KEYRING{keys}{Ed25519}{$ed_pub} = \%info;

    if (store(\%KEYRING, $keyring_file)) {
        say "Successfully imported key: $username";
    }
    else {
        die "Failed to import key: $!\n";
    }

    return 1;
}

sub remove_key ($username) {
    my @keys = find_keys($username);

    if (not @keys) {
        die "No keys found matching the given username.\n";
    }

    my $removed = 0;

    foreach my $key (@keys) {
        say "Public key : $key->{public_key}";
        say "Added on   : " . localtime($key->{time});
        if ($term->ask_yn(prompt => "Remove key $key->{username}?", default => 'n')) {
            if ($key->{mine} ? $term->ask_yn(prompt => "Are you sure?", default => 'n') : 1) {
                delete $KEYRING{keys}{X25519}{$key->{x_pub}};
                delete $KEYRING{keys}{Ed25519}{$key->{ed_pub}};
                ++$removed;
            }
        }
    }

    if ($removed and store(\%KEYRING, $keyring_file)) {
        say "Successfully removed $removed keys.";
    }
    else {
        say "No keys removed.";
    }

    return 1;
}

sub change_password ($username) {
    my @keys = grep { $_->{mine} } find_keys($username);

    if (not @keys) {
        die "No owned keys found matching the given username.\n";
    }

    my $updated = 0;

    foreach my $key (@keys) {
        if ($term->ask_yn(prompt => "Change password for $key->{username}?", default => 'n')) {

            my ($x_key, $ed_key) = decrypt_private_keys($key, "Old passphrase: ");
            my $passphrase = read_confirmed_passphrase("New passphrase: ");

            if (not defined($passphrase) or $passphrase eq '') {
                if ($term->ask_yn(prompt => "Are you sure you want to use no password?", default => 'n')) {
                    $passphrase = '';
                }
                else {
                    next;
                }
            }

            my $x_key_hash  = $x_key->key2hash;
            my $ed_key_hash = $ed_key->key2hash;

            my $x_public_key  = $x_key_hash->{pub};
            my $ed_public_key = $ed_key_hash->{pub};

            my ($x_private_key, $ed_private_key) = encrypt_private_keys($passphrase, $x_key_hash, $ed_key_hash);

            if ($passphrase eq '') {
                $key->{has_password} = 0;
            }
            else {
                $key->{has_password} = 1;
            }

            $key->{x_priv}  = $x_private_key;
            $key->{ed_priv} = $ed_private_key;

            $KEYRING{keys}{X25519}{$x_public_key}   = $key;
            $KEYRING{keys}{Ed25519}{$ed_public_key} = $key;

            ++$updated;
        }
    }

    if ($updated and store(\%KEYRING, $keyring_file)) {
        say "Successfully changed the password of $updated keys.";
    }
    else {
        say "No passwords changed.";
    }

    return 1;
}

sub make_unique_username ($username, $x_public_key) {

    $username = join('_', split(' ', $username));

    if ($username ne '') {
        $username .= '-';
    }

    $username .= substr($x_public_key, -32);

    return $username;
}

sub read_confirmed_passphrase ($prompt = 'Passprhase: ') {
    my $passphrase = read_password($prompt) // return;

    while (1) {

        my $confirmed_passphrase = read_password('Confirm passphrase: ') // return;

        if ($passphrase eq $confirmed_passphrase) {
            last;
        }

        say "Passphrases do not match. Try again.";
        $passphrase = read_password($prompt) // return;
    }

    return $passphrase;
}

sub encrypt_private_keys ($passphrase, $x_key, $ed_key) {

    my $cipher_password = create_cipher_password($passphrase, $x_key->{pub}, $ed_key->{pub});
    my $cipher          = create_cipher($cipher_password, 'Serpent');

    my $x_private_key  = $cipher->encrypt(pack("H*", $x_key->{priv}));
    my $ed_private_key = $cipher->encrypt(pack("H*", $ed_key->{priv}));

    return ($x_private_key, $ed_private_key);
}

sub generate_new_key {

    my $username   = $term->readline('Username: ') // return;
    my $passphrase = read_confirmed_passphrase()   // return;

    my $default = $term->ask_yn(prompt => "Make this the default key?", default => 'y');

    my $x25519_key  = x25519_random_key();
    my $ed25519_key = ed25519_random_key();

    my $x_key  = $x25519_key->key2hash;
    my $ed_key = $ed25519_key->key2hash;

    my $x_public_key  = $x_key->{pub};
    my $ed_public_key = $ed_key->{pub};

    $username = make_unique_username($username, $x_public_key);

    my ($x_private_key, $ed_private_key) = encrypt_private_keys($passphrase, $x_key, $ed_key);

    my %info = (
        time => time,
        mine => 1,

        username     => $username,
        has_password => (($passphrase eq '') ? 0 : 1),

        x_pub  => $x_public_key,
        x_priv => $x_private_key,

        ed_pub  => $ed_public_key,
        ed_priv => $ed_private_key,

        public_key => export_key($x_public_key, $ed_public_key),
               );

    $KEYRING{keys}{X25519}{$x_public_key}   = \%info;
    $KEYRING{keys}{Ed25519}{$ed_public_key} = \%info;

    if ($default) {
        $KEYRING{keys}{default} = $x_public_key;
    }

    store(\%KEYRING, $keyring_file);

    say "Successfully generated key: $username";
    return 1;
}

sub get_all_keys {
    my $xkeys = $KEYRING{keys}{X25519};
    my @keys  = map { $_->[1] } sort { $a->[0] cmp $b->[0] } map { [CORE::fc($_->{username}), $_] } values %$xkeys;
    return @keys;
}

sub list_my_keys {

    my @my_keys = grep { $_->{mine} } get_all_keys();

    foreach my $key (@my_keys) {
        say "Username     : ", $key->{username};
        say "Public key   : ", $key->{public_key};
        say "Created on   : ", scalar localtime($key->{time});
        say "Has password : ", ($key->{has_password}                       ? 'Yes' : 'No');
        say "Default key  : ", (($KEYRING{keys}{default} eq $key->{x_pub}) ? "Yes" : "No");
        say '';
    }

    return 1;
}

sub list_keys {

    my @keys = get_all_keys();

    foreach my $key (@keys) {
        say "Username   : ", $key->{username};
        say "Public key : ", $key->{public_key};
        say "Added on   : ", scalar localtime($key->{time});
        say '';
    }

    return 1;
}

sub select_one_key ($keys) {

    if (scalar(@$keys) == 1) {
        return $keys->[0];
    }

    if (scalar(@$keys) > 1) {
        die "Multiple usernames matched:\n\t" . join("\n\t", map { $_->{username} } @$keys) . "\n";
    }

    die "No username could be matched.\n";
}

sub find_keys ($username) {

    my @keys  = get_all_keys();
    my $regex = qr/\Q$username\E/i;

    my @found_keys;
    foreach my $key (@keys) {
        if ($key->{username} =~ $regex) {
            push @found_keys, $key;
        }
    }

    return @found_keys;
}

sub get_public_x25519_for_user ($username) {
    my @keys = find_keys($username);
    my $key  = select_one_key(\@keys);
    return x25519_from_public($key->{x_pub});
}

sub get_info_for_public_x25519 ($x_pub) {
    $KEYRING{keys}{X25519}{$x_pub};
}

sub get_private_keys_for_public_x25519 ($x_pub) {
    my $info = get_info_for_public_x25519($x_pub);
    ref($info) eq 'HASH' or die "No decryption key found!\n";
    $info->{mine} || die "Sorry! You don't have the private key of $info->{username}!\n";
    decrypt_private_keys($info);
}

sub change_user ($username) {
    my @keys = grep { $_->{mine} } find_keys($username);
    my $key  = select_one_key(\@keys);
    $KEYRING{keys}{default} = $key->{x_pub};
    warn "Current user: $key->{username}\n";
    return 1;
}

sub read_input {
    my $text = '';

    while (defined(my $line = <>)) {
        $text .= $line;
    }

    return $text;
}

sub help ($exit_code) {

    local $" = " ";

    my @compression_methods = grep {
        eval { uncompress_data($COMPRESSION_METHODS{$_}('test')) eq 'test' }
    } sort keys %COMPRESSION_METHODS;

    my @valid_ciphers = sort grep {
        eval { require "Crypt/Cipher/$_.pm"; 1 };
      } qw(
      AES Anubis Twofish Camellia Serpent SAFERP
      );

    print <<"EOT";
usage: $0 [options] [<input] [>output]

Encryption and signing:

    -e --encrypt=user   : Encrypt data for a given user
    -d --decrypt        : Decrypt data encrypted for you
    -s --sign!          : Sign the message with your private key (default: $CONFIG{sign})
       --clear-sign     : Create a signed message, without encryption
       --cipher=s       : Change the symmetric cipher (default: $CONFIG{cipher})
                          valid: @valid_ciphers

Users:

    --user=name         : Change the default user temporarily
    --default-user=name : Set a new default user

Keys:

    -l --list-keys      : List all the keys
    -L --list-mine      : List the keys that you own
    -g --generate-key   : Generate a new key-pair
    -i --import=key     : Import a given public key
       --name=s         : Give a name to the imported key
       --export=name    : Export a public key from your keyring
       --remove=name    : Remove a given key from your keyring
       --password=name  : Change the passphrase of your key

Compression options:

    --compress!         : Compress data before encryption (default: $CONFIG{compress})
    --compress-method=s : Compression method (default: $CONFIG{compress_method})
                          valid: @compression_methods

Examples:

    # Generate a key
    $0 -g

    # Import a key
    $0 -i [PublicKey] --name=Alice

    # Encrypt and sign a message for Alice
    $0 -e=Alice -s message.txt > message.enc

    # Decrypt a received message
    $0 -d message.enc > message.txt
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
           'compress!'         => \$CONFIG{compress},
           'compress-method=s' => \$CONFIG{compress_method},
           'name=s'            => \$CONFIG{name},
           'user=s'            => \$CONFIG{change_user},
           'default-user=s'    => \$CONFIG{change_default_user},
           'password:s'        => \$CONFIG{change_password},
           'a|armor'           => \$CONFIG{armor},
           'l|list-keys'       => \$CONFIG{list_keys},
           'L|list-mine'       => \$CONFIG{list_my_keys},
           'i|import-key=s'    => \$CONFIG{import},
           'export-key:s'      => \$CONFIG{export},
           'remove-key:s'      => \$CONFIG{remove},
           'g|generate-key!'   => \$CONFIG{generate_key},
           'e|encrypt=s'       => \$CONFIG{encrypt},
           'd|decrypt!'        => \$CONFIG{decrypt},
           's|sign!'           => \$CONFIG{sign},
           'clear-sign'        => \$CONFIG{clear_sign},
           'verify-message'    => \$CONFIG{verify_message},
           'v|version'         => \&version,
           'h|help'            => sub { help(0) },
          )
  or die("Error in command line arguments\n");

if (not exists $COMPRESSION_METHODS{$CONFIG{compress_method}}) {
    die "Invalid compression method: $CONFIG{compress_method}\n";
}

if (defined $CONFIG{change_user}) {
    change_user($CONFIG{change_user});
}

if (defined $CONFIG{change_default_user}) {
    change_user($CONFIG{change_default_user});
    store(\%KEYRING, $keyring_file);
}

if ($CONFIG{generate_key}) {
    generate_new_key();
    exit 0;
}

if ($CONFIG{list_keys}) {
    list_keys();
    exit 0;
}

if ($CONFIG{list_my_keys}) {
    list_my_keys();
    exit 0;
}

if (defined($CONFIG{export})) {
    foreach my $key (find_keys($CONFIG{export})) {
        say "Username   : $key->{username}";
        say "Public key : $key->{public_key}";
        say '';
    }
    exit 0;
}

if (defined($CONFIG{import})) {
    import_key($CONFIG{import});
    exit 0;
}

if (defined($CONFIG{remove})) {
    remove_key($CONFIG{remove});
    exit 0;
}

if (defined($CONFIG{change_password})) {
    change_password($CONFIG{change_password});
    exit 0;
}

my $local_user = sub {

    if (not defined($KEYRING{keys}{default}) or not defined($KEYRING{keys}{X25519}{$KEYRING{keys}{default}})) {
        die "No default user found!\nPass --user=s to select a key, or generate a new key with -g\n";
    }

    state $x_key;
    state $ed_key;

    if (defined($x_key) and defined($ed_key)) {
        return ($x_key, $ed_key);
    }

    ($x_key, $ed_key) = decrypt_private_keys($KEYRING{keys}{X25519}{$KEYRING{keys}{default}});

    return ($x_key, $ed_key);
};

if ($CONFIG{clear_sign}) {
    my $text = read_input();
    my ($x_key, $ed_key) = $local_user->();
    print create_clear_signed_message($text, $ed_key);
    exit 0;
}

if ($CONFIG{verify_message}) {
    my $text = read_input();
    verify_clear_signed_message($text);
    exit 0;
}

if (defined($CONFIG{encrypt})) {

    my $x_pub = get_public_x25519_for_user($CONFIG{encrypt});

    my $text  = read_input();
    my $enc   = encrypt($text, $x_pub);
    my $armor = create_armor($enc);

    if ($CONFIG{sign}) {
        my (undef, $ed_key) = $local_user->();
        print create_clear_signed_message($armor, $ed_key);
    }
    else {
        print $armor;
    }

    exit 0;
}

if ($CONFIG{decrypt}) {
    my $armor = read_input();

    if ($armor =~ /^-----BEGIN PLAGE SIGNED MESSAGE-----\s*$/m) {
        verify_clear_signed_message($armor, sub ($msg) { $armor = $msg });
    }

    my $enc_info  = decode_armor($armor);
    my $dest_info = get_info_for_public_x25519($enc_info->{dest});

    if (not defined $dest_info) {
        die "Sorry! You don't have the private key to decrypt this message!\n";
    }

    warn "Destination  : " . $dest_info->{username} . "\n";
    warn "Cipher used  : " . $enc_info->{cipher} . "\n";
    warn "Compressed   : " . ($enc_info->{compressed} ? "Yes" : "No") . "\n";
    warn "Encrypted on : " . localtime($enc_info->{time}) . "\n";

    my ($x_priv, undef) = get_private_keys_for_public_x25519($enc_info->{dest});

    print decrypt($enc_info, $x_priv);
    exit 0;
}

help(1);
