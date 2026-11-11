#!/usr/bin/perl

# Author: Trizen
# Date: 02 February 2022
# Edit: 10 November 2026 (complete redesign: plage format v1)
# https://github.com/trizen

# A file encryption and signing tool, inspired by age and GnuPG.
#
# Main features:
#   - streaming encryption and decryption (constant memory, fast on large files)
#   - authenticated encryption: ChaCha20-Poly1305, with a STREAM construction (age-style)
#   - X25519 public-key recipients (multiple recipients) and passphrase-based encryption
#   - Ed25519 signatures: signed+encrypted files, clear-signed text, detached signatures
#   - ASCII armor (streaming)
#   - optional compression: zlib (default), bzip2, xz
#   - local keyring (JSON); private keys encrypted with Argon2id (or PBKDF2-HMAC-SHA512)
#
# See the "PROTOCOL" section at the end of this file for the full specification.
#
# Dependencies:
#   CryptX (Crypt::AuthEnc::ChaCha20Poly1305, Crypt::PK::X25519, Crypt::PK::Ed25519, ...)
#   Term::ReadKey              (only for passphrase prompts)
#   Crypt::Argon2              (optional; recommended for protecting private keys)
#   Compress::Raw::Lzma        (optional; for xz compression)

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Fcntl                 qw(O_WRONLY O_CREAT O_EXCL);
use File::Spec::Functions qw(catdir catfile curdir);
use Getopt::Long          qw(GetOptions :config no_ignore_case bundling);
use JSON::PP              ();
use MIME::Base64          qw(encode_base64 decode_base64);

use Crypt::AuthEnc::ChaCha20Poly1305 qw(chacha20poly1305_encrypt_authenticate chacha20poly1305_decrypt_verify);
use Crypt::Digest::BLAKE2b_512       qw(blake2b_512);
use Crypt::Digest::SHA256            qw(sha256 sha256_hex);
use Crypt::KeyDerivation             qw(hkdf pbkdf2);
use Crypt::Mac::HMAC                 qw(hmac);
use Crypt::Misc                      qw(slow_eq);
use Crypt::PK::Ed25519;
use Crypt::PK::X25519;
use Crypt::PRNG qw(random_bytes);

use constant {
    APPNAME => 'plage',
    VERSION => '1.0',

    MAGIC          => 'PLAGE',
    FORMAT_VERSION => 1,

    FLAG_SIGNED => 0x01,

    STANZA_X25519     => 1,
    STANZA_PASSPHRASE => 2,
    X25519_BODY_SIZE  => 32 + 48,
    PASS_BODY_SIZE    => 1 + 4 + 4 + 1 + 16 + 48,

    KDF_ARGON2ID => 1,
    KDF_PBKDF2   => 2,

    KEY_SIZE   => 32,
    TAG_SIZE   => 16,
    NONCE_SIZE => 16,
    MAC_SIZE   => 32,
    ED_SIZE    => 32,
    SIG_SIZE   => 64,
    TIME_SIZE  => 8,

    CHUNK_LOG2_MIN     => 12,
    CHUNK_LOG2_MAX     => 24,
    CHUNK_LOG2_DEFAULT => 16,
    MAX_STANZAS        => 128,

    # signature types (domain separation)
    SIG_ENCRYPTED => 1,
    SIG_DETACHED  => 2,
    SIG_CLEAR     => 3,
    HASH_BLAKE2B  => 1,

    SIGNATURE_MAGIC => 'PLSG',

    ARMOR_COLUMNS  => 64,
    PUBKEY_PREFIX  => 'plage1',
    PUBKEY_VERSION => 1,
    FP_DISPLAY_HEX => 40,

    ARGON2_T        => 3,
    ARGON2_M_KIB    => 65536,
    ARGON2_P        => 1,
    PBKDF2_ITER     => 600_000,
    MAX_ARGON2_M    => 1_048_576,
    MAX_ARGON2_T    => 16,
    MAX_ARGON2_P    => 16,
    MAX_PBKDF2_ITER => 20_000_000,

    READ_SIZE => 1 << 18,
};

use constant {
              ZERO12             => "\0" x 12,
              ZERO32             => "\0" x 32,
              TRAILER_SIZE       => TIME_SIZE + ED_SIZE + SIG_SIZE,
              DETACHED_BLOB_SIZE => 4 + 3 + TIME_SIZE + ED_SIZE + SIG_SIZE,
             };

my %COMPRESSION_ID   = (none => 0, zlib => 1, bzip2 => 2, xz => 3);
my %COMPRESSION_NAME = reverse %COMPRESSION_ID;

my $JSON = JSON::PP->new->ascii->canonical->pretty;

#
# ---------------------------------------------------------------- utilities
#

sub fail ($msg) {
    die "$msg\n";
}

sub warning ($msg) {
    warn "plage: $msg\n";
}

my %OPT;

sub info ($msg) {
    warn "plage: $msg\n" if not $OPT{quiet};
}

sub write_all ($fh, $data) {
    my $len = length($data);
    my $off = 0;
    while ($off < $len) {
        my $w = syswrite($fh, $data, $len - $off, $off);
        if (not defined $w) {
            next if $!{EINTR};
            fail("write error: $!");
        }
        $off += $w;
    }
    return 1;
}

sub be64 ($n) { pack('Q>', $n) }

# Decrypts "ciphertext || tag"; returns undef if authentication fails.
# (The pieces are copied into plain variables first: CryptX misbehaves with inline substr() arguments.)
sub aead_open ($key, $nonce, $aad, $sealed) {
    length($sealed) >= TAG_SIZE or return;
    my $ct  = substr($sealed, 0, length($sealed) - TAG_SIZE);
    my $tag = substr($sealed, length($sealed) - TAG_SIZE);
    return chacha20poly1305_decrypt_verify($key, $nonce, $aad, $ct, $tag);
}

sub safe_name ($name) {
    defined($name) or return;
    $name =~ s/^\s+|\s+$//g;
    $name =~ /[[:cntrl:]]/ and fail("Invalid name: control characters are not allowed.");
    $name ne '' or return;
    return $name;
}

sub get_config_dir {

    my $xdg_config_home = $ENV{XDG_CONFIG_HOME};

    if ($xdg_config_home and -d -w $xdg_config_home) {
        return $xdg_config_home;
    }

    my $home_dir = $ENV{HOME} || $ENV{LOGDIR} || do {
        require File::HomeDir;
        File::HomeDir->my_home;
    };

    if (not defined($home_dir) or not -d -w $home_dir) {
        $home_dir = curdir();
    }

    return catdir($home_dir, '.config');
}

#
# ---------------------------------------------------------------- terminal / passphrases
#

my ($TTY_IN, $TTY_OUT, $PASSFD, $LAST_PASSFD_LINE);

sub open_tty {
    if (not defined $TTY_IN) {
        if ($^O eq 'MSWin32') {
            open($TTY_IN,  '<', 'CONIN$')  or fail("No terminal available for interactive input (see --passphrase-fd).");
            open($TTY_OUT, '>', 'CONOUT$') or fail("Can't open console output handle: $!");
        }
        else {
            open($TTY_IN,  '+<', '/dev/tty') or fail("No terminal available for interactive input (see --passphrase-fd).");
            open($TTY_OUT, '>&', $TTY_IN)    or fail("Can't duplicate the terminal handle: $!");
        }
        select((select($TTY_OUT), $| = 1)[0]);
    }
    return 1;
}

sub ask_line ($prompt) {
    open_tty();
    print $TTY_OUT $prompt;
    my $line = <$TTY_IN>;
    defined($line) or return;
    $line =~ s/\r?\n\z//;
    return $line;
}

sub ask_yn ($prompt, $default = 'n') {
    my $answer = ask_line("$prompt [" . ($default eq 'y' ? 'Y/n' : 'y/N') . "] ") // return 0;
    $answer =~ /\S/ or return ($default eq 'y');
    return ($answer =~ /^\s*y/i ? 1 : 0);
}

sub read_secret ($prompt) {

    if (defined $PASSFD) {
        my $line = <$PASSFD>;

        # when the input is exhausted, keep offering the last passphrase (e.g. to try several keys)
        if (defined $line) {
            $line =~ s/\r?\n\z//;
            $LAST_PASSFD_LINE = $line;
        }

        return ($LAST_PASSFD_LINE // fail("No passphrase available on the given file descriptor."));
    }

    # If STDIN is not a TTY (e.g. piped or redirected) on Windows, Term::ReadKey will fail.
    # Fall back to asking via ask_line if we aren't on an interactive console.
    if ($^O eq 'MSWin32' && !-t STDIN) {
        return ask_line($prompt);
    }

    require Term::ReadKey;

    my $term_in = ($^O eq 'MSWin32') ? \*STDIN : do { open_tty(); $TTY_IN };

    unless ($^O eq 'MSWin32') {
        open_tty();
    }
    else {
        open_tty() unless defined $TTY_OUT;
    }

    my $restore = sub { Term::ReadKey::ReadMode('restore', $term_in) };
    local $SIG{INT} = sub { $restore->(); print $TTY_OUT "\n"; exit 130 };

    print $TTY_OUT $prompt;
    Term::ReadKey::ReadMode('noecho', $term_in);
    my $line = <$term_in>;
    $restore->();
    print $TTY_OUT "\n";

    defined($line) or return;
    $line =~ s/\r?\n\z//;
    return $line;
}

sub read_confirmed_secret ($prompt = 'Passphrase: ') {

    my $pass = read_secret($prompt) // return;

    if (defined $PASSFD) {
        return $pass;
    }

    while (1) {
        my $again = read_secret('Confirm passphrase: ') // return;
        last if $again eq $pass;
        warn "Passphrases do not match. Try again.\n";
        $pass = read_secret($prompt) // return;
    }

    return $pass;
}

#
# ---------------------------------------------------------------- key derivation
#

sub default_kdf {
    if (eval { require Crypt::Argon2; 1 }) {
        return (KDF_ARGON2ID, ARGON2_T, ARGON2_M_KIB, ARGON2_P);
    }
    return (KDF_PBKDF2, PBKDF2_ITER, 0, 0);
}

sub check_kdf_params ($kdf, $p1, $p2, $p3) {
    if ($kdf == KDF_ARGON2ID) {
        ($p1 >= 1       and $p1 <= MAX_ARGON2_T) or fail("Unacceptable Argon2id time cost.");
        ($p3 >= 1       and $p3 <= MAX_ARGON2_P) or fail("Unacceptable Argon2id parallelism.");
        ($p2 >= 8 * $p3 and $p2 <= MAX_ARGON2_M) or fail("Unacceptable Argon2id memory cost.");
    }
    elsif ($kdf == KDF_PBKDF2) {
        ($p1 >= 1 and $p1 <= MAX_PBKDF2_ITER) or fail("Unacceptable PBKDF2 iteration count.");
    }
    else {
        fail("Unknown key derivation function: $kdf");
    }
    return 1;
}

sub derive_key ($pass, $salt, $kdf, $p1, $p2, $p3) {

    check_kdf_params($kdf, $p1, $p2, $p3);

    if ($kdf == KDF_ARGON2ID) {
        eval { require Crypt::Argon2; 1 }
          or fail("The Perl module Crypt::Argon2 is required in order to use this passphrase.");
        return Crypt::Argon2::argon2id_raw($pass, $salt, $p1, "${p2}k", $p3, KEY_SIZE);
    }

    return pbkdf2($pass, $salt, $p1, 'SHA512', KEY_SIZE);
}

#
# ---------------------------------------------------------------- encoding helpers
#

my @B32 = ('a' .. 'z', '2' .. '7');
my %B32 = map { $B32[$_] => $_ } 0 .. $#B32;

sub base32_encode ($data) {
    my $bits = unpack('B*', $data);
    $bits .= '0' x ((5 - length($bits) % 5) % 5);
    return join('', map { $B32[oct("0b$_")] } $bits =~ /(.{5})/g);
}

sub base32_decode ($str) {
    my $bits = '';
    foreach my $c (split(//, $str)) {
        defined($B32{$c}) or return;
        $bits .= sprintf('%05b', $B32{$c});
    }
    my $extra = length($bits) % 8;
    if ($extra >= 5 or substr($bits, length($bits) - $extra) !~ /\A0*\z/) {
        return;
    }
    return pack('B*', substr($bits, 0, length($bits) - $extra));
}

#
# ---------------------------------------------------------------- public keys
#

sub fingerprint ($x_pub, $ed_pub) {
    sha256_hex("plage-v1 fingerprint\0" . $x_pub . $ed_pub);
}

sub format_fingerprint ($fp) {
    join(' ', substr($fp, 0, FP_DISPLAY_HEX) =~ /(.{4})/g);
}

sub pubkey_checksum ($body) {
    my $digest = sha256("plage-v1 pubkey checksum\0" . $body);
    return substr($digest, 0, 4);
}

sub export_public_key ($x_pub, $ed_pub) {
    my $body = pack('C', PUBKEY_VERSION) . $x_pub . $ed_pub;
    return PUBKEY_PREFIX . base32_encode($body . pubkey_checksum($body));
}

sub decode_public_key ($str) {

    $str =~ s/\s+//g;
    $str = lc($str);

    index($str, PUBKEY_PREFIX) == 0 or fail("Invalid public key: wrong prefix.");

    my $raw = base32_decode(substr($str, length(PUBKEY_PREFIX)));

    if (not defined($raw) or length($raw) != 1 + 2 * KEY_SIZE + 4) {
        fail("Invalid public key: malformed encoding.");
    }

    my $body     = substr($raw, 0, -4);
    my $checksum = substr($raw, -4);

    slow_eq($checksum, pubkey_checksum($body))
      or fail("Invalid public key: bad checksum (was it mistyped?).");

    ord(substr($body, 0, 1)) == PUBKEY_VERSION or fail("Unsupported public key version.");

    my $x_pub  = substr($body, 1,  KEY_SIZE);
    my $ed_pub = substr($body, 33, KEY_SIZE);

    # make sure the keys can be imported
    eval { x25519_public($x_pub);   1 } or fail("Invalid public key: bad X25519 key.");
    eval { ed25519_public($ed_pub); 1 } or fail("Invalid public key: bad Ed25519 key.");

    return ($x_pub, $ed_pub);
}

sub x25519_public ($raw) {
    Crypt::PK::X25519->new->import_key_raw($raw, 'public');
}

sub x25519_private ($raw) {
    Crypt::PK::X25519->new->import_key_raw($raw, 'private');
}

sub ed25519_public ($raw) {
    Crypt::PK::Ed25519->new->import_key_raw($raw, 'public');
}

sub ed25519_private ($raw) {
    Crypt::PK::Ed25519->new->import_key_raw($raw, 'private');
}

#
# ---------------------------------------------------------------- keyring
#

my $PLAGE_DIR;
my $KEYRING;

sub keyring_file {
    $PLAGE_DIR //= catdir(get_config_dir(), APPNAME);
    return catfile($PLAGE_DIR, 'keyring.json');
}

sub load_keyring {

    return $KEYRING if defined $KEYRING;

    my $file = keyring_file();

    if (not -e $file) {
        return ($KEYRING = {version => 1, default => undef, keys => {}});
    }

    my $mode = (stat($file))[2] & 07777;
    if ($mode & 0077) {
        warning(sprintf("the keyring file %s is accessible by other users (mode %04o)", $file, $mode));
    }

    open(my $fh, '<:raw', $file) or fail("Can't open keyring <<$file>>: $!");
    my $content = do { local $/; <$fh> };
    close $fh;

    my $data = eval { $JSON->decode($content) };
    ref($data) eq 'HASH' && ref($data->{keys}) eq 'HASH' or fail("The keyring file is corrupted: $file");
    $data->{version} == 1                                or fail("Unsupported keyring version: $data->{version}");

    return ($KEYRING = $data);
}

sub save_keyring {

    my $file = keyring_file();
    my $dir  = $PLAGE_DIR;

    if (not -d $dir) {
        require File::Path;
        File::Path::make_path($dir, {mode => 0700});
        -d $dir or fail("Can't create directory: $dir");
    }

    my $tmp = "$file.tmp$$";
    sysopen(my $fh, $tmp, O_WRONLY | O_CREAT | O_EXCL, 0600) or fail("Can't create <<$tmp>>: $!");

    my $ok = eval {
        write_all($fh, $JSON->encode($KEYRING));
        $fh->flush;
        $fh->sync;
        close($fh)          or die "close: $!\n";
        rename($tmp, $file) or die "rename: $!\n";
        1;
    };

    if (not $ok) {
        my $err = $@;
        unlink($tmp);
        fail("Failed to save the keyring: $err");
    }

    return 1;
}

sub keys_sorted {
    my $keys = load_keyring()->{keys};
    return sort { fc($a->{name}) cmp fc($b->{name}) } values %$keys;
}

sub key_info ($rec) {
    return {
            name   => $rec->{name},
            fp     => $rec->{fp},
            x_pub  => pack('H*', $rec->{x_pub}),
            ed_pub => pack('H*', $rec->{ed_pub}),
            mine   => $rec->{mine},
            rec    => $rec,
           };
}

# Find keyring entries: exact name, then fingerprint prefix, then name substring.
sub find_keys ($query) {

    my @keys = keys_sorted();

    my @found = grep { fc($_->{name}) eq fc($query) } @keys;
    return @found if @found;

    if ($query =~ /^[0-9a-f]{6,64}\z/i) {
        @found = grep { index($_->{fp}, lc($query)) == 0 } @keys;
        return @found if @found;
    }

    my $re = qr/\Q$query\E/i;
    return grep { $_->{name} =~ $re } @keys;
}

sub select_one_key ($query, @keys) {

    if (@keys == 1) {
        return $keys[0];
    }

    if (@keys > 1) {
        fail("Multiple keys matched '$query':\n\t" . join("\n\t", map { $_->{name} } @keys));
    }

    fail("No key found matching '$query'.");
}

# Resolve either a keyring entry or a raw public key string.
sub resolve_public ($query) {

    if ($query =~ /^\s*\Q${\PUBKEY_PREFIX}\E[a-z2-7\s]+\z/i) {
        my ($x_pub, $ed_pub) = decode_public_key($query);
        return {name => undef, fp => fingerprint($x_pub, $ed_pub), x_pub => $x_pub, ed_pub => $ed_pub};
    }

    return key_info(select_one_key($query, find_keys($query)));
}

sub lookup_by_ed_public ($ed_pub) {
    my $hex = unpack('H*', $ed_pub);
    foreach my $rec (keys_sorted()) {
        return key_info($rec) if $rec->{ed_pub} eq $hex;
    }
    return;
}

sub protect_private_keys ($passphrase, $x_pub, $ed_pub, $x_priv, $ed_priv) {

    my $plain = $x_priv . $ed_priv;

    if ($passphrase eq '') {
        return {kdf => 'none', data => encode_base64($plain, '')};
    }

    my ($kdf, $p1, $p2, $p3) = default_kdf();
    my $salt = random_bytes(16);
    my $key  = derive_key($passphrase, $salt, $kdf, $p1, $p2, $p3);

    # The key is unique (random salt), so a fixed nonce is safe.
    my ($ct, $tag) = chacha20poly1305_encrypt_authenticate($key, ZERO12, "plage-v1 keyring\0" . $x_pub . $ed_pub, $plain);

    return {
            kdf  => ($kdf == KDF_ARGON2ID ? 'argon2id' : 'pbkdf2-sha512'),
            p1   => $p1,
            p2   => $p2,
            p3   => $p3,
            salt => encode_base64($salt,      ''),
            data => encode_base64($ct . $tag, ''),
           };
}

sub unprotect_private_keys ($rec, $passphrase) {

    my $priv   = $rec->{private};
    my $x_pub  = pack('H*', $rec->{x_pub});
    my $ed_pub = pack('H*', $rec->{ed_pub});
    my $data   = decode_base64($priv->{data});
    my $plain;

    if ($priv->{kdf} eq 'none') {
        $plain = $data;
    }
    else {
        my $kdf = $priv->{kdf} eq 'argon2id' ? KDF_ARGON2ID : $priv->{kdf} eq 'pbkdf2-sha512' ? KDF_PBKDF2 : fail("Unknown KDF in keyring: $priv->{kdf}");
        length($data) > TAG_SIZE or fail("The keyring is corrupted.");
        my $key = derive_key($passphrase, decode_base64($priv->{salt}), $kdf, $priv->{p1}, $priv->{p2}, $priv->{p3});
        $plain = aead_open($key, ZERO12, "plage-v1 keyring\0" . $x_pub . $ed_pub, $data) // return;
    }

    length($plain) == 2 * KEY_SIZE or fail("The keyring is corrupted.");

    my $x_priv  = substr($plain, 0,        KEY_SIZE);
    my $ed_priv = substr($plain, KEY_SIZE, KEY_SIZE);

    # sanity check: the private keys must match the public ones
    my $x_key  = x25519_private($x_priv);
    my $ed_key = ed25519_private($ed_priv);

    slow_eq($x_key->export_key_raw('public'),  $x_pub)  or fail("The keyring is corrupted (X25519 mismatch).");
    slow_eq($ed_key->export_key_raw('public'), $ed_pub) or fail("The keyring is corrupted (Ed25519 mismatch).");

    return ($x_key, $ed_key);
}

my %UNLOCKED;

# Returns ($x_private_key, $ed_private_key), or an empty list if the user gave up.
sub unlock_key ($info) {

    my $rec = $info->{rec};

    $info->{mine} or fail("You don't have the private key of '$info->{name}'.");

    if ($UNLOCKED{$info->{fp}}) {
        return @{$UNLOCKED{$info->{fp}}};
    }

    my $tries = defined($PASSFD) ? 1 : 3;

    for (1 .. $tries) {

        my $pass = '';

        if ($rec->{private}{kdf} ne 'none') {
            $pass = read_secret("Passphrase for '$info->{name}' (empty to skip): ") // last;
            $pass eq '' and last;
        }

        my @keys = unprotect_private_keys($rec, $pass);

        if (@keys) {
            $UNLOCKED{$info->{fp}} = \@keys;
            return @keys;
        }

        warn "Wrong passphrase.\n";
    }

    return;
}

sub local_identity ($user) {

    my $keyring = load_keyring();

    if (defined $user) {
        my $info = key_info(select_one_key($user, grep { $_->{mine} } find_keys($user)));
        return $info;
    }

    my $default = $keyring->{default};

    if (not defined($default) or not defined($keyring->{keys}{$default})) {
        fail("No default key found!\nPass --user=NAME to select a key, or generate a new key with -g");
    }

    return key_info($keyring->{keys}{$default});
}

sub unlocked_signer ($user) {
    my $info = local_identity($user);
    my (undef, $ed_key) = unlock_key($info);
    defined($ed_key) or fail("Could not unlock the signing key of '$info->{name}'.");
    return ($info, $ed_key);
}

sub print_key ($rec, $full) {
    say "Name        : $rec->{name}";
    say "Fingerprint : ", format_fingerprint($rec->{fp});
    say "Public key  : ", export_public_key(pack('H*', $rec->{x_pub}), pack('H*', $rec->{ed_pub}));
    say "Created on  : ", scalar localtime($rec->{created});
    if ($full) {
        say "Passphrase  : ", ($rec->{private}{kdf} eq 'none'                    ? 'No'  : "Yes ($rec->{private}{kdf})");
        say "Default     : ", (((load_keyring()->{default} // '') eq $rec->{fp}) ? 'Yes' : 'No');
    }
    say '';
}

sub cmd_list_keys ($mine_only) {
    foreach my $rec (keys_sorted()) {
        next if ($mine_only and not $rec->{mine});
        print_key($rec, $rec->{mine});
    }
    return 1;
}

sub cmd_generate_key ($name) {

    $name = safe_name($name // ask_line('Name: ')) // fail("A name is required.");

    if (grep { fc($_->{name}) eq fc($name) } keys_sorted()) {
        fail("A key named '$name' already exists.");
    }

    my $passphrase = read_confirmed_secret() // fail("Aborted.");

    if ($passphrase eq '' and not defined $PASSFD) {
        ask_yn("Are you sure you want to use no passphrase?", 'n') or fail("Aborted.");
    }

    my $x_key  = Crypt::PK::X25519->new->generate_key;
    my $ed_key = Crypt::PK::Ed25519->new->generate_key;

    my $x_pub   = $x_key->export_key_raw('public');
    my $x_priv  = $x_key->export_key_raw('private');
    my $ed_pub  = $ed_key->export_key_raw('public');
    my $ed_priv = $ed_key->export_key_raw('private');
    my $fp      = fingerprint($x_pub, $ed_pub);

    my $keyring = load_keyring();

    $keyring->{keys}{$fp} = {
                             name    => $name,
                             fp      => $fp,
                             created => time,
                             mine    => JSON::PP::true,
                             x_pub   => unpack('H*', $x_pub),
                             ed_pub  => unpack('H*', $ed_pub),
                             private => protect_private_keys($passphrase, $x_pub, $ed_pub, $x_priv, $ed_priv),
                            };

    if (not defined $keyring->{default} or not defined $keyring->{keys}{$keyring->{default}}) {
        $keyring->{default} = $fp;
    }

    save_keyring();

    say "Successfully generated key: $name";
    say "Fingerprint : ", format_fingerprint($fp);
    say "Public key  : ", export_public_key($x_pub, $ed_pub);
    return 1;
}

sub cmd_import_key ($public_key, $name) {

    my ($x_pub, $ed_pub) = decode_public_key($public_key);
    my $fp      = fingerprint($x_pub, $ed_pub);
    my $keyring = load_keyring();

    if (my $old = $keyring->{keys}{$fp}) {
        fail("This key already exists, under the name: $old->{name}");
    }

    say "Fingerprint : ", format_fingerprint($fp);

    $name = safe_name($name // ask_line('Name: ')) // fail("A name is required.");

    if (grep { fc($_->{name}) eq fc($name) } keys_sorted()) {
        fail("A key named '$name' already exists.");
    }

    $keyring->{keys}{$fp} = {
                             name    => $name,
                             fp      => $fp,
                             created => time,
                             mine    => JSON::PP::false,
                             x_pub   => unpack('H*', $x_pub),
                             ed_pub  => unpack('H*', $ed_pub),
                            };

    save_keyring();
    say "Successfully imported key: $name";
    return 1;
}

sub cmd_export_key ($query) {
    my $key = select_one_key($query, find_keys($query));
    say export_public_key(pack('H*', $key->{x_pub}), pack('H*', $key->{ed_pub}));
    return 1;
}

sub cmd_remove_key ($query) {

    my $keyring = load_keyring();
    my @keys    = find_keys($query);

    @keys or fail("No keys found matching '$query'.");

    my $removed = 0;

    foreach my $key (@keys) {
        print_key($key, $key->{mine});
        ask_yn("Remove key '$key->{name}'?", 'n') or next;
        if ($key->{mine}) {
            ask_yn("This is a PRIVATE key; it cannot be recovered. Are you sure?", 'n') or next;
        }
        delete $keyring->{keys}{$key->{fp}};
        if (defined($keyring->{default}) and $keyring->{default} eq $key->{fp}) {
            $keyring->{default} = undef;
        }
        ++$removed;
    }

    $removed and save_keyring();
    say "Removed $removed key(s).";
    return 1;
}

sub cmd_default_user ($query) {
    my $key = select_one_key($query, grep { $_->{mine} } find_keys($query));
    load_keyring()->{default} = $key->{fp};
    save_keyring();
    say "Default key: $key->{name}";
    return 1;
}

sub cmd_change_passphrase ($query) {

    my $rec  = select_one_key($query, grep { $_->{mine} } find_keys($query));
    my $info = key_info($rec);

    $UNLOCKED{$info->{fp}} and delete $UNLOCKED{$info->{fp}};

    my ($x_key, $ed_key) = unlock_key($info);
    defined($ed_key) or fail("Could not unlock the key.");

    my $pass = read_confirmed_secret('New passphrase: ') // fail("Aborted.");

    if ($pass eq '' and not defined $PASSFD) {
        ask_yn("Are you sure you want to use no passphrase?", 'n') or fail("Aborted.");
    }

    $rec->{private} = protect_private_keys($pass, $info->{x_pub}, $info->{ed_pub}, $x_key->export_key_raw('private'), $ed_key->export_key_raw('private'));
    save_keyring();
    say "Passphrase changed for: $rec->{name}";
    return 1;
}

#
# ---------------------------------------------------------------- streaming I/O
#

package Plage::Reader {

    # Buffered reader over a source callback; `read($n)` returns fewer than $n bytes only at EOF.
    sub new ($class, $source) {
        bless {src => $source, buf => '', eof => 0}, $class;
    }

    sub from_fh ($class, $fh) {
        $class->new(
            sub {
                while (1) {
                    my $r = sysread($fh, my $data, main::READ_SIZE());
                    if (not defined $r) { next if $!{EINTR}; die "read error: $!\n" }
                    return $data;
                }
            }
        );
    }

    sub from_string ($class, $string) {
        my $pos = 0;
        $class->new(
            sub {
                my $data = substr($string, $pos, main::READ_SIZE());
                $pos += length($data);
                return $data;
            }
        );
    }

    sub _fill ($self) {
        return 0 if $self->{eof};
        my $data = $self->{src}->();
        if (not defined($data) or $data eq '') {
            $self->{eof} = 1;
            return 0;
        }
        $self->{buf} .= $data;
        return 1;
    }

    sub read ($self, $n) {
        while (length($self->{buf}) < $n) {
            $self->_fill or last;
        }
        return substr($self->{buf}, 0, $n, '');
    }

    sub read_some ($self, $n) {
        length($self->{buf}) or $self->_fill;
        return substr($self->{buf}, 0, $n, '');
    }

    sub unread ($self, $data) {
        substr($self->{buf}, 0, 0, $data);
    }

    sub read_line ($self, $max = 4096) {
        while ((my $i = index($self->{buf}, "\n")) < 0) {
            die "Line too long\n" if length($self->{buf}) > $max;
            $self->_fill or last;
        }
        my $i = index($self->{buf}, "\n");
        if ($i < 0) {
            length($self->{buf}) or return;
            return substr($self->{buf}, 0, length($self->{buf}), '');
        }
        my $line = substr($self->{buf}, 0, $i + 1, '');
        $line =~ s/\r?\n\z//;
        return $line;
    }
}

package Plage::ArmorReader {

    # Strict streaming decoder for: BEGIN line, base64 lines of exactly 64 columns, one shorter
    # (padded) last line, END line.
    sub new ($class, $under, $label) {

        my $header = $under->read_line() // die "Invalid armor: empty input\n";

        $header =~ /^-----BEGIN \Q$label\E-----[ \t]*\z/ or die "Invalid armor: bad header line\n";

        bless {under => $under, label => $label, text => '', bin => '', done => 0}, $class;
    }

    sub _ingest ($self) {

        my $label = $self->{label};

        my $chunk = $self->{under}->read_some(1 << 19);
        my $eof   = (length($chunk) == 0);

        $self->{text} .= $chunk;
        $self->{text} =~ s/\r\n/\n/g;

        if ($eof and $self->{text} ne '' and substr($self->{text}, -1) ne "\n") {
            $self->{text} .= "\n";
        }

        my $col = main::ARMOR_COLUMNS();

        while (1) {

            # full-width lines
            if ($self->{text} =~ /\A((?:[A-Za-z0-9+\/]{$col}\n)+)/) {
                my $lines = $1;
                substr($self->{text}, 0, length($lines), '');
                $lines =~ tr/\n//d;
                $self->{bin} .= MIME::Base64::decode_base64($lines);
                next;
            }

            # optional short last line, then END line
            if (   $self->{text} =~ /\A((?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?)\n-----END \Q$label\E-----[ \t]*\n/
                or $self->{text} =~ /\A()-----END \Q$label\E-----[ \t]*\n/) {

                my $last = $1;
                length($last) < $col or die "Invalid armor: non-canonical last line\n";
                substr($self->{text}, 0, $+[0], '');
                $self->{bin} .= MIME::Base64::decode_base64($last);
                $self->{text} =~ /\A\s*\z/ or die "Invalid armor: unexpected data after the END line\n";
                $self->{done} = 1;
                $self->{text} = '';
                return;
            }

            last;
        }

        if ($eof) {
            die "Invalid armor: truncated or malformed data\n";
        }

        if (length($self->{text}) > 2 * $col + 256) {
            die "Invalid armor: malformed data\n";
        }
    }

    sub read ($self, $n) {
        while (length($self->{bin}) < $n and not $self->{done}) {
            $self->_ingest;
        }
        return substr($self->{bin}, 0, $n, '');
    }

    sub unread ($self, $data) {
        substr($self->{bin}, 0, 0, $data);
    }
}

package Plage::ArmorWriter {

    sub new ($class, $label, $write) {
        $write->("-----BEGIN $label-----\n");
        bless {label => $label, write => $write, buf => ''}, $class;
    }

    sub _lines ($data) {
        my $col = main::ARMOR_COLUMNS();
        return join("\n", unpack("(A$col)*", MIME::Base64::encode_base64($data, ''))) . "\n";
    }

    sub add ($self, $data) {
        $self->{buf} .= $data;
        my $n = int(length($self->{buf}) / 48) * 48;
        $n or return;
        $self->{write}->(_lines(substr($self->{buf}, 0, $n, '')));
    }

    sub finish ($self) {
        length($self->{buf}) and $self->{write}->(_lines(substr($self->{buf}, 0, length($self->{buf}), '')));
        $self->{write}->("-----END $self->{label}-----\n");
    }
}

package Plage::ChunkWriter {

    # STREAM construction: every chunk is sealed with ChaCha20-Poly1305 under a 12-byte nonce made of
    # a 64-bit big-endian counter and a final-chunk flag. Only the last chunk carries the flag.
    sub new ($class, $key, $chunk_size, $write) {
        bless {key => $key, cs => $chunk_size, write => $write, buf => '', ctr => 0}, $class;
    }

    sub add ($self, $data) {
        $self->{buf} .= $data;
        my $cs = $self->{cs};
        while (length($self->{buf}) > $cs) {
            $self->_seal(substr($self->{buf}, 0, $cs, ''), 0);
        }
    }

    sub finish ($self) {
        $self->_seal($self->{buf}, 1);
        $self->{buf} = '';
    }

    sub _seal ($self, $plain, $final) {
        my ($ct, $tag) =
          Crypt::AuthEnc::ChaCha20Poly1305::chacha20poly1305_encrypt_authenticate($self->{key}, pack('x3Q>C', $self->{ctr}++, $final), '', $plain);
        $self->{write}->($ct . $tag);
    }
}

package Plage::ChunkReader {

    sub new ($class, $key, $chunk_size, $reader) {
        bless {key => $key, bs => $chunk_size + main::TAG_SIZE(), rd => $reader, ctr => 0, cur => undef, done => 0}, $class;
    }

    # Returns the next plaintext chunk, or undef after the final chunk.
    sub next_chunk ($self) {

        $self->{done} and return;

        my $bs = $self->{bs};
        my $rd = $self->{rd};

        $self->{cur} //= $rd->read($bs);

        my $cur  = $self->{cur};
        my $next = (length($cur) == $bs) ? $rd->read($bs) : '';

        my $final = (length($next) == 0) ? 1 : 0;

        length($cur) >= main::TAG_SIZE() or die "Decryption failed: the data is truncated.\n";

        if ($final and length($cur) == main::TAG_SIZE() and $self->{ctr} > 0) {
            die "Decryption failed: invalid (empty) final chunk.\n";
        }

        my $plain = main::aead_open($self->{key}, pack('x3Q>C', $self->{ctr}, $final), '', $cur);

        defined($plain) or die "Decryption failed: the data is corrupted, truncated, or has been tampered with.\n";

        ++$self->{ctr};
        $self->{cur}  = $next;
        $self->{done} = $final;

        return $plain;
    }
}

package main;

#
# ---------------------------------------------------------------- compression (streaming)
#

sub available_compression {
    my @ok = ('none');
    push @ok, 'zlib'  if eval { require Compress::Raw::Zlib;  1 };
    push @ok, 'bzip2' if eval { require Compress::Raw::Bzip2; 1 };
    push @ok, 'xz'    if eval { require Compress::Raw::Lzma;  1 };
    return @ok;
}

# Returns ($add, $finish) closures. Compressed output is passed to $emit.
sub make_compressor ($algo, $level, $emit) {

    if ($algo eq 'none') {
        return (sub ($data) { $emit->($data) }, sub { });
    }

    if ($algo eq 'zlib') {
        require Compress::Raw::Zlib;
        my ($z, $st) = Compress::Raw::Zlib::Deflate->new(-Level => $level // 6, -AppendOutput => 1, -Bufsize => 1 << 16);
        $st == Compress::Raw::Zlib::Z_OK() or fail("zlib initialization failed.");
        return (
            sub ($data) {
                my $out = '';
                $z->deflate($data, $out) == Compress::Raw::Zlib::Z_OK() or fail("zlib compression failed.");
                length($out) and $emit->($out);
            },
            sub {
                my $out = '';
                $z->flush($out) == Compress::Raw::Zlib::Z_OK() or fail("zlib compression failed.");
                length($out) and $emit->($out);
            }
        );
    }

    if ($algo eq 'bzip2') {
        require Compress::Raw::Bzip2;
        my ($z, $st) = Compress::Raw::Bzip2->new(1, 9, 0, 0);
        $st == Compress::Raw::Bzip2::BZ_OK() or fail("bzip2 initialization failed.");
        return (
            sub ($data) {
                my $out = '';
                $z->bzdeflate($data, $out) == Compress::Raw::Bzip2::BZ_RUN_OK() or fail("bzip2 compression failed.");
                length($out) and $emit->($out);
            },
            sub {
                my $out = '';
                $z->bzclose($out) == Compress::Raw::Bzip2::BZ_STREAM_END() or fail("bzip2 compression failed.");
                length($out) and $emit->($out);
            }
        );
    }

    if ($algo eq 'xz') {
        require Compress::Raw::Lzma;
        my ($z, $st) =
          Compress::Raw::Lzma::EasyEncoder->new(
                                                AppendOutput => 1,
                                                Preset       => $level // 6,
                                                Check        => Compress::Raw::Lzma::LZMA_CHECK_CRC64(),
                                               );
        $st == Compress::Raw::Lzma::LZMA_OK() or fail("xz initialization failed.");
        return (
            sub ($data) {
                my $out = '';
                $z->code($data, $out) == Compress::Raw::Lzma::LZMA_OK() or fail("xz compression failed.");
                length($out) and $emit->($out);
            },
            sub {
                my $out = '';
                $z->flush($out) == Compress::Raw::Lzma::LZMA_STREAM_END() or fail("xz compression failed.");
                length($out) and $emit->($out);
            }
        );
    }

    fail("Unknown compression method: $algo");
}

# Returns ($add, $finish). Output is limited per call so that decompression bombs
# can't exhaust the memory. Data after the end of the compressed stream is rejected.
sub make_decompressor ($algo, $emit) {

    if ($algo eq 'none') {
        return (sub ($data) { $emit->($data) }, sub { });
    }

    my ($ended, $inflate, $is_end, $is_ok);

    if ($algo eq 'zlib') {
        require Compress::Raw::Zlib;
        my ($z, $st) = Compress::Raw::Zlib::Inflate->new(-AppendOutput => 1, -ConsumeInput => 1, -LimitOutput => 1, -Bufsize => 1 << 16);
        $st == Compress::Raw::Zlib::Z_OK() or fail("zlib initialization failed.");
        $inflate = sub { $z->inflate($_[0], $_[1]) };
        $is_end  = sub { $_[0] == Compress::Raw::Zlib::Z_STREAM_END() };
        $is_ok   = sub { $_[0] == Compress::Raw::Zlib::Z_OK() or $_[0] == Compress::Raw::Zlib::Z_BUF_ERROR() };
    }
    elsif ($algo eq 'bzip2') {
        require Compress::Raw::Bzip2;
        my ($z, $st) = Compress::Raw::Bunzip2->new(1, 1, 0, 0, 1);
        $st == Compress::Raw::Bzip2::BZ_OK() or fail("bzip2 initialization failed.");
        $inflate = sub { $z->bzinflate($_[0], $_[1]) };
        $is_end  = sub { $_[0] == Compress::Raw::Bzip2::BZ_STREAM_END() };
        $is_ok   = sub { $_[0] == Compress::Raw::Bzip2::BZ_OK() };
    }
    elsif ($algo eq 'xz') {
        require Compress::Raw::Lzma;
        my ($z, $st) = Compress::Raw::Lzma::StreamDecoder->new(AppendOutput => 1, ConsumeInput => 1, LimitOutput => 1, Bufsize => 1 << 16);
        $st == Compress::Raw::Lzma::LZMA_OK() or fail("xz initialization failed.");
        $inflate = sub { $z->code($_[0], $_[1]) };
        $is_end  = sub { $_[0] == Compress::Raw::Lzma::LZMA_STREAM_END() };
        $is_ok   = sub { $_[0] == Compress::Raw::Lzma::LZMA_OK() };
    }
    else {
        fail("Unknown compression method: $algo");
    }

    return (
        sub ($data) {

            $ended and fail("Corrupt data: unexpected data after the end of the compressed stream.");

            while (1) {
                my $out    = '';
                my $before = length($data);
                my $status = $inflate->($data, $out);

                length($out) and $emit->($out);

                if ($is_end->($status)) {
                    $ended = 1;
                    length($data) and fail("Corrupt data: unexpected data after the end of the compressed stream.");
                    last;
                }

                $is_ok->($status) or fail("Corrupt data: decompression failed.");

                # No progress at all means that more input is needed.
                last if (!length($data)           and !length($out));
                last if (length($data) == $before and !length($out));
            }
        },
        sub {
            $ended or fail("Corrupt data: the compressed stream is truncated.");
        }
    );
}

#
# ---------------------------------------------------------------- signatures
#

sub signature_message ($type, $time, $ed_pub, $binding, $digest) {
    return "plage-v1 signature\0" . pack('CC', $type, HASH_BLAKE2B) . be64($time) . $ed_pub . pack('n', length($binding)) . $binding . $digest;
}

sub create_signature ($ed_key, $type, $binding, $digest) {
    my $time   = time;
    my $ed_pub = $ed_key->export_key_raw('public');
    my $sig    = $ed_key->sign_message(signature_message($type, $time, $ed_pub, $binding, $digest));
    return ($time, $ed_pub, $sig);
}

sub verify_signature ($type, $time, $ed_pub, $sig, $binding, $digest) {
    my $key = eval { ed25519_public($ed_pub) } // return 0;
    return ($key->verify_message($sig, signature_message($type, $time, $ed_pub, $binding, $digest)) ? 1 : 0);
}

sub pack_detached_signature ($type, $time, $ed_pub, $sig) {
    return SIGNATURE_MAGIC . pack('CCC', FORMAT_VERSION, $type, HASH_BLAKE2B) . be64($time) . $ed_pub . $sig;
}

sub unpack_detached_signature ($blob, $want_type) {

    length($blob) == DETACHED_BLOB_SIZE    or fail("Invalid signature: bad length.");
    substr($blob, 0, 4) eq SIGNATURE_MAGIC or fail("Invalid signature: bad magic.");

    my ($version, $type, $hash) = unpack('CCC', substr($blob, 4, 3));

    $version == FORMAT_VERSION or fail("Unsupported signature version: $version");
    $hash == HASH_BLAKE2B      or fail("Unsupported signature hash function: $hash");
    $type == $want_type        or fail("Invalid signature: wrong signature type.");

    my $time   = unpack('Q>', substr($blob, 7, TIME_SIZE));
    my $ed_pub = substr($blob, 15,           ED_SIZE);
    my $sig    = substr($blob, 15 + ED_SIZE, SIG_SIZE);

    return ($time, $ed_pub, $sig);
}

# Decide whether we accept this signer. Returns the keyring info (or undef if unknown).
sub check_signer ($ed_pub, $strict) {

    my $info = lookup_by_ed_public($ed_pub);

    if (@{$OPT{signer} // []}) {
        my $match;
        foreach my $query (@{$OPT{signer}}) {
            my $who = resolve_public($query);
            $match //= $who if slow_eq($who->{ed_pub}, $ed_pub);
        }
        $match or fail("The signature was made by a key that is not one of the requested signers.");
        return $info // $match;
    }

    if (not defined $info and $strict) {
        fail(  "The signature is valid, but the signing key is not in your keyring\n  (signer Ed25519 key: "
             . unpack('H*', $ed_pub)
             . ").\nImport the key, or pass --signer=KEY.");
    }

    return $info;
}

sub report_signature ($info, $ed_pub, $time) {

    my $who =
      defined($info)
      ? (defined($info->{name}) ? "'$info->{name}' " : "key ") . "(" . format_fingerprint($info->{fp}) . ")"
      : "UNKNOWN key (Ed25519: " . unpack('H*', $ed_pub) . ")";

    info("Good signature from $who");
    info("Signature made on " . scalar(localtime($time)));
    defined($info) or warning("WARNING: the signing key is not in your keyring; the signer's identity is NOT verified!");
    return 1;
}

#
# ---------------------------------------------------------------- input / output
#

sub open_input ($path) {

    if (not defined($path) or $path eq '-') {
        binmode(STDIN) or fail("binmode: $!");
        return \*STDIN;
    }

    open(my $fh, '<:raw', $path) or fail("Can't open <<$path>> for reading: $!");
    return $fh;
}

# Output goes to a temporary file, which is renamed only after everything has been verified.
sub open_output ($path) {

    if (not defined($path) or $path eq '-') {
        binmode(STDOUT) or fail("binmode: $!");
        return {fh => \*STDOUT, tty => (-t STDOUT)};
    }

    if (-e $path and not $OPT{force}) {
        fail("Output file <<$path>> already exists (use --force to overwrite).");
    }

    my $tmp = "$path.plage-tmp$$";
    sysopen(my $fh, $tmp, O_WRONLY | O_CREAT | O_EXCL, 0666) or fail("Can't create <<$tmp>>: $!");
    binmode($fh);

    return {fh => $fh, tmp => $tmp, path => $path};
}

sub output_writer ($out) {
    my $fh = $out->{fh};
    return sub ($data) { write_all($fh, $data) };
}

sub commit_output ($out) {

    if ($out->{tmp}) {
        close($out->{fh})                 or fail("Error closing the output file: $!");
        rename($out->{tmp}, $out->{path}) or fail("Can't rename <<$out->{tmp}>> to <<$out->{path}>>: $!");
        delete $out->{tmp};
    }

    return 1;
}

my @PENDING_OUTPUTS;

END {
    foreach my $out (@PENDING_OUTPUTS) {
        defined($out->{tmp}) and unlink($out->{tmp});
    }
}

sub slurp ($fh) {
    my $reader = Plage::Reader->from_fh($fh);
    my $data   = '';
    while (length(my $chunk = $reader->read_some(1 << 20))) {
        $data .= $chunk;
    }
    return $data;
}

#
# ---------------------------------------------------------------- the encrypted file format
#

sub mac_key ($file_key) {
    hkdf($file_key, '', 'SHA256', KEY_SIZE, 'plage-v1 header mac');
}

sub payload_key ($file_key, $nonce) {
    hkdf($file_key, $nonce, 'SHA256', KEY_SIZE, 'plage-v1 payload');
}

sub wrap_x25519 ($file_key, $recipient_x_pub) {

    my $eph     = Crypt::PK::X25519->new->generate_key;
    my $eph_pub = $eph->export_key_raw('public');
    my $shared  = $eph->shared_secret(x25519_public($recipient_x_pub));

    $shared eq ZERO32 and fail("Invalid recipient key (low-order point).");

    my $wrap_key = hkdf($shared, $eph_pub . $recipient_x_pub, 'SHA256', KEY_SIZE, 'plage-v1 x25519 wrap');

    # --- CONTEXTUAL AAD BINDING ---
    # Bind the stanza type, ephemeral public key, and recipient public key as AAD
    my $aad = pack('C', STANZA_X25519) . $eph_pub . $recipient_x_pub;

    my ($ct, $tag) = chacha20poly1305_encrypt_authenticate($wrap_key, ZERO12, $aad, $file_key);

    return pack('C', STANZA_X25519) . $eph_pub . $ct . $tag;
}

sub unwrap_x25519 ($stanza, $x_private_key) {

    my $eph_pub = substr($stanza->{body}, 0, 32);
    my $wrapped = substr($stanza->{body}, 32);

    my $shared = eval { $x_private_key->shared_secret(x25519_public($eph_pub)) } // return;
    $shared eq ZERO32 and return;

    my $my_pub   = $x_private_key->export_key_raw('public');
    my $wrap_key = hkdf($shared, $eph_pub . $my_pub, 'SHA256', KEY_SIZE, 'plage-v1 x25519 wrap');

    # --- CONTEXTUAL AAD BINDING ---
    # Reconstruct the exact same AAD using the decrypting recipient's public key
    my $aad = pack('C', STANZA_X25519) . $eph_pub . $my_pub;

    return aead_open($wrap_key, ZERO12, $aad, $wrapped);
}

sub wrap_passphrase ($file_key, $passphrase) {

    my ($kdf, $p1, $p2, $p3) = default_kdf();
    my $salt = random_bytes(16);
    my $key  = hkdf(derive_key($passphrase, $salt, $kdf, $p1, $p2, $p3), $salt, 'SHA256', KEY_SIZE, 'plage-v1 passphrase wrap');

    # --- CONTEXTUAL AAD BINDING ---
    # Bind the stanza type, KDF configuration parameters, and salt as AAD
    my $stanza_header = pack('C C N N C', STANZA_PASSPHRASE, $kdf, $p1, $p2, $p3) . $salt;

    my ($ct, $tag) = chacha20poly1305_encrypt_authenticate($key, ZERO12, $stanza_header, $file_key);

    return $stanza_header . $ct . $tag;
}

sub unwrap_passphrase ($stanza, $passphrase) {

    my $body = $stanza->{body};

    # Extract the exact stanza header fields used during wrapping for AAD verification
    my $stanza_header = substr($body, 0, 1 + 1 + 4 + 4 + 1 + 16);

    my ($kdf, $p1, $p2, $p3) = unpack('C N N C', substr($body, 0, 10));
    my $salt    = substr($body, 10, 16);
    my $wrapped = substr($body, 26);

    my $key = hkdf(derive_key($passphrase, $salt, $kdf, $p1, $p2, $p3), $salt, 'SHA256', KEY_SIZE, 'plage-v1 passphrase wrap');

    # --- CONTEXTUAL AAD BINDING ---
    return aead_open($key, ZERO12, $stanza_header, $wrapped);
}

sub build_header ($flags, $compression_id, $chunk_log2, $nonce, $file_key, @stanzas) {

    my $header = MAGIC . pack('CCCCC', FORMAT_VERSION, $flags, $compression_id, $chunk_log2, scalar(@stanzas)) . $nonce . join('', @stanzas);

    return $header . hmac('SHA256', mac_key($file_key), $header);
}

sub parse_header ($reader) {

    my $raw = '';

    my $get = sub ($n) {
        my $data = $reader->read($n);
        length($data) == $n or fail("Invalid file: truncated header.");
        $raw .= $data;
        return $data;
    };

    $get->(length(MAGIC)) eq MAGIC or fail("Not a plage file (bad magic).");

    my ($version, $flags, $comp, $chunk_log2, $count) = unpack('CCCCC', $get->(5));

    $version == FORMAT_VERSION                                        or fail("Unsupported plage format version: $version");
    ($flags & ~FLAG_SIGNED) == 0                                      or fail("Unsupported flags in header.");
    defined($COMPRESSION_NAME{$comp})                                 or fail("Unsupported compression method in header: $comp");
    ($chunk_log2 >= CHUNK_LOG2_MIN and $chunk_log2 <= CHUNK_LOG2_MAX) or fail("Invalid chunk size in header.");
    ($count >= 1 and $count <= MAX_STANZAS)                           or fail("Invalid number of recipients in header.");

    my $nonce = $get->(NONCE_SIZE);

    my @stanzas;
    foreach (1 .. $count) {
        my $type = ord($get->(1));
        if ($type == STANZA_X25519) {
            push @stanzas, {type => $type, body => $get->(X25519_BODY_SIZE)};
        }
        elsif ($type == STANZA_PASSPHRASE) {
            my $body = $get->(PASS_BODY_SIZE);
            check_kdf_params(unpack('C N N C', substr($body, 0, 10)));
            push @stanzas, {type => $type, body => $body};
        }
        else {
            fail("Unsupported recipient type in header: $type");
        }
    }

    if (grep { $_->{type} == STANZA_PASSPHRASE } @stanzas) {
        @stanzas == 1 or fail("Invalid header: a passphrase recipient can't be combined with other recipients.");
    }

    my $mac = $reader->read(MAC_SIZE);
    length($mac) == MAC_SIZE or fail("Invalid file: truncated header.");

    return {
            raw        => $raw . $mac,
            body       => $raw,
            mac        => $mac,
            flags      => $flags,
            compress   => $COMPRESSION_NAME{$comp},
            chunk_log2 => $chunk_log2,
            nonce      => $nonce,
            stanzas    => \@stanzas,
           };
}

sub encrypt_file ($opt) {

    my $compression = $opt->{compress};
    my $chunk_log2  = CHUNK_LOG2_DEFAULT;
    my $chunk_size  = 1 << $chunk_log2;

    my $file_key = random_bytes(KEY_SIZE);
    my @stanzas;

    if ($opt->{symmetric}) {
        @{$opt->{recipient}} and fail("Use either --recipient or --symmetric, not both.");
        my $pass = read_confirmed_secret('Passphrase for encryption: ') // fail("Aborted.");
        $pass ne '' or fail("The passphrase must not be empty.");
        push @stanzas, wrap_passphrase($file_key, $pass);
    }
    else {
        @{$opt->{recipient}} or fail("No recipients given. Use -r NAME (or -c for a passphrase).");

        my %seen;
        foreach my $query (@{$opt->{recipient}}) {
            my $who = resolve_public($query);
            next if $seen{$who->{x_pub}}++;
            push @stanzas, wrap_x25519($file_key, $who->{x_pub});
        }

        @stanzas <= MAX_STANZAS or fail("Too many recipients.");
    }

    my ($signer, $ed_key);
    if ($opt->{sign}) {
        ($signer, $ed_key) = unlocked_signer($opt->{user});
    }

    my $in  = open_input($opt->{file});
    my $out = open_output($opt->{output});
    push @PENDING_OUTPUTS, $out;

    if ($out->{tty} and not $opt->{armor}) {
        fail("Refusing to write binary data to the terminal. Use --armor or --output.");
    }

    my $write = output_writer($out);
    my ($emit_out, $finish_out) = ($write, sub { });

    if ($opt->{armor}) {
        my $armor = Plage::ArmorWriter->new('PLAGE ENCRYPTED FILE', $write);
        ($emit_out, $finish_out) = (sub ($d) { $armor->add($d) }, sub { $armor->finish });
    }

    my $nonce  = random_bytes(NONCE_SIZE);
    my $header = build_header($ed_key ? FLAG_SIGNED : 0, $COMPRESSION_ID{$compression}, $chunk_log2, $nonce, $file_key, @stanzas);

    $emit_out->($header);

    my $chunker = Plage::ChunkWriter->new(payload_key($file_key, $nonce), $chunk_size, $emit_out);
    my ($compress, $finish_compress) = make_compressor($compression, $opt->{level}, sub ($d) { $chunker->add($d) });

    my $hasher = $ed_key ? Crypt::Digest::BLAKE2b_512->new : undef;

    while (1) {
        my $r = sysread($in, my $buf, $chunk_size * 4);
        if (not defined $r) { next if $!{EINTR}; fail("read error: $!") }
        last if not $r;
        $hasher and $hasher->add($buf);
        $compress->($buf);
    }

    $finish_compress->();

    if ($ed_key) {
        my ($time, $ed_pub, $sig) = create_signature($ed_key, SIG_ENCRYPTED, blake2b_512($header), $hasher->digest);
        $chunker->add(be64($time) . $ed_pub . $sig);
        info("Signed as '$signer->{name}'");
    }

    $chunker->finish;
    $finish_out->();
    commit_output($out);

    return 1;
}

sub open_encrypted ($in) {

    my $reader = Plage::Reader->from_fh($in);

    # skip leading whitespace
    while (1) {
        my $c = $reader->read(1);
        $c eq '' and fail("Empty input.");
        if ($c !~ /\s/) {
            $reader->unread($c);
            last;
        }
    }

    my $peek = $reader->read(length(MAGIC));
    $reader->unread($peek);

    if ($peek eq MAGIC) {
        return $reader;
    }

    if (substr($peek, 0, 5) eq '-----') {
        return Plage::ArmorReader->new($reader, 'PLAGE ENCRYPTED FILE');
    }

    fail("Not a plage file.");
}

sub find_file_key ($header, $opt) {

    my @stanzas = @{$header->{stanzas}};
    my $file_key;

    if ($stanzas[0]{type} == STANZA_PASSPHRASE) {

        my $tries = defined($PASSFD) ? 1 : 3;

        for (1 .. $tries) {
            my $pass = read_secret('Passphrase for decryption: ') // last;
            $file_key = unwrap_passphrase($stanzas[0], $pass) and last;
            warn "Wrong passphrase.\n";
        }

        defined($file_key) or fail("Decryption failed: wrong passphrase.");
        info("Decrypted with a passphrase");
    }
    else {

        my @candidates;

        if (defined $opt->{user}) {
            @candidates = local_identity($opt->{user});
        }
        else {
            my $default = load_keyring()->{default} // '';
            @candidates = sort { (($b->{fp} eq $default) <=> ($a->{fp} eq $default)) } grep { $_->{mine} } map { key_info($_) } keys_sorted();
        }

        @candidates or fail("You don't have any private key. Generate one with -g");

      KEY: foreach my $info (@candidates) {
            my ($x_key) = unlock_key($info) or next;
            foreach my $stanza (grep { $_->{type} == STANZA_X25519 } @stanzas) {
                $file_key = unwrap_x25519($stanza, $x_key);
                if (defined $file_key) {
                    info("Decrypted with key '$info->{name}'");
                    last KEY;
                }
            }
        }

        defined($file_key) or fail("Decryption failed: none of your keys can decrypt this file.");
    }

    slow_eq(hmac('SHA256', mac_key($file_key), $header->{body}), $header->{mac})
      or fail("Decryption failed: the header is corrupted or has been tampered with.");

    return $file_key;
}

sub decrypt_file ($opt) {

    my $in     = open_input($opt->{file});
    my $reader = open_encrypted($in);
    my $header = parse_header($reader);

    my $signed = ($header->{flags} & FLAG_SIGNED) ? 1 : 0;

    if (not $signed and ($opt->{require_signed} or @{$opt->{signer} // []})) {
        fail("The file is not signed, but a signature is required.");
    }

    my $file_key = find_file_key($header, $opt);

    my $out = open_output($opt->{output});
    push @PENDING_OUTPUTS, $out;

    my $write  = output_writer($out);
    my $hasher = $signed ? Crypt::Digest::BLAKE2b_512->new : undef;

    my $emit = $signed ? sub ($d) { $hasher->add($d); $write->($d) } : $write;
    my ($decompress, $finish_decompress) = make_decompressor($header->{compress}, $emit);

    my $chunker = Plage::ChunkReader->new(payload_key($file_key, $header->{nonce}), 1 << $header->{chunk_log2}, $reader);

    my $hold = '';
    while (defined(my $plain = $chunker->next_chunk)) {
        if ($signed) {
            $hold .= $plain;
            if (length($hold) > TRAILER_SIZE) {
                $decompress->(substr($hold, 0, length($hold) - TRAILER_SIZE, ''));
            }
        }
        else {
            $decompress->($plain);
        }
    }

    $finish_decompress->();

    if ($signed) {

        length($hold) == TRAILER_SIZE or fail("Decryption failed: the signature trailer is missing.");

        my $time   = unpack('Q>', substr($hold, 0, TIME_SIZE));
        my $ed_pub = substr($hold, TIME_SIZE,           ED_SIZE);
        my $sig    = substr($hold, TIME_SIZE + ED_SIZE, SIG_SIZE);

        verify_signature(SIG_ENCRYPTED, $time, $ed_pub, $sig, blake2b_512($header->{raw}), $hasher->digest)
          or fail("BAD SIGNATURE: the signature does not match the decrypted data. Discard the output!");

        my $who = check_signer($ed_pub, $opt->{require_signed});
        report_signature($who, $ed_pub, $time);
    }
    else {
        info("The file is not signed");
    }

    commit_output($out);
    return 1;
}

#
# ---------------------------------------------------------------- detached and clear signatures
#

sub hash_stream ($fh) {
    my $hasher = Crypt::Digest::BLAKE2b_512->new;
    while (1) {
        my $r = sysread($fh, my $buf, 1 << 20);
        if (not defined $r) { next if $!{EINTR}; fail("read error: $!") }
        last if not $r;
        $hasher->add($buf);
    }
    return $hasher->digest;
}

sub armor_small ($label, $blob) {
    my $text  = '';
    my $armor = Plage::ArmorWriter->new($label, sub ($d) { $text .= $d });
    $armor->add($blob);
    $armor->finish;
    return $text;
}

sub unarmor_small ($label, $text) {
    my $reader = Plage::ArmorReader->new(Plage::Reader->from_string($text), $label);
    my $blob   = $reader->read(1 << 16);
    length($reader->read(1)) == 0 or fail("Invalid armor: too much data.");
    return $blob;
}

sub cmd_detach_sign ($opt) {

    my ($signer, $ed_key) = unlocked_signer($opt->{user});
    my $digest = hash_stream(open_input($opt->{file}));

    my ($time, $ed_pub, $sig) = create_signature($ed_key, SIG_DETACHED, '', $digest);

    my $out = open_output($opt->{output});
    push @PENDING_OUTPUTS, $out;
    output_writer($out)->(armor_small('PLAGE SIGNATURE', pack_detached_signature(SIG_DETACHED, $time, $ed_pub, $sig)));
    commit_output($out);
    return 1;
}

sub cmd_verify_detached ($opt) {

    my $sigfile = $opt->{verify_detached};
    open(my $sfh, '<:raw', $sigfile) or fail("Can't open <<$sigfile>>: $!");
    my $text = slurp($sfh);

    $text =~ /\A\s*-----BEGIN PLAGE SIGNATURE-----/ or fail("Invalid signature file.");
    my ($time, $ed_pub, $sig) = unpack_detached_signature(unarmor_small('PLAGE SIGNATURE', $text =~ s/\A\s+//r), SIG_DETACHED);

    my $digest = hash_stream(open_input($opt->{file}));

    verify_signature(SIG_DETACHED, $time, $ed_pub, $sig, '', $digest)
      or fail("BAD SIGNATURE: the signature does not match the data.");

    report_signature(check_signer($ed_pub, 1), $ed_pub, $time);
    return 1;
}

# Canonical text: LF line endings, no trailing whitespace on lines, final newline.
sub canonicalize_text ($text) {

    $text =~ s/\r\n/\n/g;

    my @lines = split(/\n/, $text, -1);
    @lines and $lines[-1] eq '' and pop @lines;

    return join('', map { s/[ \t]+\z//r . "\n" } @lines);
}

sub cmd_clear_sign ($opt) {

    my ($signer, $ed_key) = unlocked_signer($opt->{user});

    my $text = canonicalize_text(slurp(open_input($opt->{file})));
    my ($time, $ed_pub, $sig) = create_signature($ed_key, SIG_CLEAR, '', blake2b_512($text));

    my $message =
        "-----BEGIN PLAGE SIGNED MESSAGE-----\n"
      . ($text =~ s/^-/- -/mgr)
      . armor_small('PLAGE SIGNATURE', pack_detached_signature(SIG_CLEAR, $time, $ed_pub, $sig));

    my $out = open_output($opt->{output});
    push @PENDING_OUTPUTS, $out;
    output_writer($out)->($message);
    commit_output($out);
    return 1;
}

sub cmd_verify_clear ($opt) {

    my $input = slurp(open_input($opt->{file}));

    $input =~ s/\r\n/\n/g;
    $input =~ s/\A\s+//;

    my $header = "-----BEGIN PLAGE SIGNED MESSAGE-----\n";
    index($input, $header) == 0 or fail("Not a plage clear-signed message.");
    substr($input, 0, length($header), '');

    my $marker = "-----BEGIN PLAGE SIGNATURE-----\n";
    my $pos    = ($input =~ /^\Q$marker\E/m) ? $-[0] : fail("The signature block is missing.");

    my $escaped = substr($input, 0, $pos);
    my $sigtext = substr($input, $pos);

    my $text = '';
    foreach my $line (split(/^/, $escaped)) {
        if ($line =~ /^-/) {
            $line =~ s/^- // or fail("Invalid clear-signed message: bad dash-escaping.");
        }
        $text .= $line;
    }

    $text = canonicalize_text($text);

    my ($time, $ed_pub, $sig) = unpack_detached_signature(unarmor_small('PLAGE SIGNATURE', $sigtext), SIG_CLEAR);

    verify_signature(SIG_CLEAR, $time, $ed_pub, $sig, '', blake2b_512($text))
      or fail("BAD SIGNATURE: the message has been modified or the signature is invalid.");

    my $who = check_signer($ed_pub, 1);

    my $out = open_output($opt->{output});
    push @PENDING_OUTPUTS, $out;
    output_writer($out)->($text);
    commit_output($out);

    report_signature($who, $ed_pub, $time);
    return 1;
}

#
# ---------------------------------------------------------------- command line
#

sub version {
    my $w = 22;
    printf("%-*s %s\n", $w, APPNAME,       VERSION);
    printf("%-*s %s\n", $w, 'format',      FORMAT_VERSION);
    printf("%-*s %s\n", $w, 'CryptX',      $CryptX::VERSION                      // '?');
    printf("%-*s %s\n", $w, 'argon2id',    eval { require Crypt::Argon2; 'yes' } // 'no (PBKDF2 fallback)');
    printf("%-*s %s\n", $w, 'compression', join(', ', available_compression()));
    exit 0;
}

sub help ($exit_code) {

    my $compression = join(', ', grep { $_ ne 'none' } available_compression());

    print <<"EOT";
usage: $0 [options] [FILE]        (FILE defaults to standard input)

Encryption (streaming, authenticated):

    -e --encrypt           : Encrypt FILE
    -r --recipient=KEY     : Recipient: a name from the keyring, or a plage1... public key
                             (can be repeated)
    -c --symmetric         : Encrypt with a passphrase instead of public keys
    -s --sign              : Also sign the data (the signature is hidden inside the encryption)
    -d --decrypt           : Decrypt FILE (and verify the signature, if there is one)
    -a --armor             : ASCII armor the encrypted output
    -o --output=FILE       : Write to FILE (atomically) instead of standard output
    -f --force             : Overwrite the output file, if it exists
    -z                     : Compress before encrypting (zlib)
       --compress=METHOD   : Compress with METHOD (default: none; available: $compression)
       --level=N           : Compression level

Signatures:

       --clear-sign        : Create a clear-signed text message
       --detach-sign       : Create a detached signature of FILE
       --verify            : Verify a clear-signed message, and print its text
       --verify-detached=SIGFILE : Verify FILE against a detached signature
       --signer=KEY        : Only accept signatures made by KEY (can be repeated)
       --require-signed    : When decrypting, fail unless the file is signed by a known key

Keys:

    -g --generate-key      : Generate a new key-pair (Ed25519 + X25519)
       --name=NAME         : Name of the key to generate or import
    -l --list-keys         : List all the keys
       --list-mine         : List the keys you own
    -i --import-key=KEY    : Import a public key
       --export-key=NAME   : Print the public key of NAME
       --remove-key=NAME   : Remove a key from the keyring
       --change-passphrase=NAME : Change the passphrase of one of your keys
       --default-user=NAME : Set the default key
    -u --user=NAME         : Use this key for signing/decryption instead of the default

Other:

       --passphrase-fd=N   : Read passphrases (one per line) from file descriptor N
    -q --quiet             : Don't print status messages
    -v --version           : Show version information
    -h --help              : Show this help

Examples:

    $0 -g --name=alice                              # generate a key
    $0 --export-key=alice                           # print the public key to share
    $0 -i plage1xyz... --name=bob                   # import bob's public key
    $0 -e -r bob -s -a -o secret.txt.plage secret.txt
    $0 -d secret.txt.plage -o secret.txt
    $0 -c bigfile.iso -o bigfile.iso.plage          # passphrase encryption
    $0 --detach-sign release.tar.gz -o release.tar.gz.sig
    $0 --verify-detached=release.tar.gz.sig release.tar.gz
EOT

    exit($exit_code);
}

$OPT{recipient} = [];
$OPT{signer}    = [];
$OPT{compress}  = 'none';

GetOptions(
           'e|encrypt'           => \$OPT{encrypt},
           'd|decrypt'           => \$OPT{decrypt},
           'r|recipient=s'       => $OPT{recipient},
           'c|symmetric'         => \$OPT{symmetric},
           's|sign'              => \$OPT{sign},
           'a|armor'             => \$OPT{armor},
           'o|output=s'          => \$OPT{output},
           'f|force'             => \$OPT{force},
           'z'                   => sub { $OPT{compress} = 'zlib' },
           'compress=s'          => \$OPT{compress},
           'level=i'             => \$OPT{level},
           'clear-sign'          => \$OPT{clear_sign},
           'detach-sign'         => \$OPT{detach_sign},
           'verify'              => \$OPT{verify},
           'verify-detached=s'   => \$OPT{verify_detached},
           'signer=s'            => $OPT{signer},
           'require-signed'      => \$OPT{require_signed},
           'g|generate-key'      => \$OPT{generate_key},
           'name=s'              => \$OPT{name},
           'l|list-keys'         => \$OPT{list_keys},
           'list-mine'           => \$OPT{list_mine},
           'i|import-key=s'      => \$OPT{import_key},
           'export-key=s'        => \$OPT{export_key},
           'remove-key=s'        => \$OPT{remove_key},
           'change-passphrase=s' => \$OPT{change_passphrase},
           'default-user=s'      => \$OPT{default_user},
           'u|user=s'            => \$OPT{user},
           'passphrase-fd=i'     => \$OPT{passphrase_fd},
           'q|quiet'             => \$OPT{quiet},
           'v|version'           => \&version,
           'h|help'              => sub { help(0) },
          )
  or exit 2;

@ARGV <= 1 or fail("Too many arguments: expected at most one input file.");
$OPT{file} = $ARGV[0];

$OPT{compress} = lc($OPT{compress});

if (not defined $COMPRESSION_ID{$OPT{compress}}) {
    fail("Invalid compression method: $OPT{compress}");
}

if ($OPT{compress} ne 'none' and not grep { $_ eq $OPT{compress} } available_compression()) {
    fail("The compression method '$OPT{compress}' is not available (missing Perl module).");
}

if (defined $OPT{passphrase_fd}) {
    open($PASSFD, '<&=', $OPT{passphrase_fd}) or fail("Can't open file descriptor $OPT{passphrase_fd}: $!");
}

# Terminal output may contain attacker-chosen names: only keyring names are shown, and they are sanitized.
my @actions = grep { $OPT{$_} } qw(encrypt decrypt clear_sign detach_sign verify generate_key list_keys list_mine);
push @actions, grep { defined $OPT{$_} } qw(verify_detached import_key export_key remove_key change_passphrase default_user);

@actions <= 1 or fail("Conflicting actions given: " . join(', ', @actions));

if ($OPT{generate_key})              { cmd_generate_key($OPT{name});                   exit 0 }
if ($OPT{list_keys})                 { cmd_list_keys(0);                               exit 0 }
if ($OPT{list_mine})                 { cmd_list_keys(1);                               exit 0 }
if (defined $OPT{import_key})        { cmd_import_key($OPT{import_key}, $OPT{name});   exit 0 }
if (defined $OPT{export_key})        { cmd_export_key($OPT{export_key});               exit 0 }
if (defined $OPT{remove_key})        { cmd_remove_key($OPT{remove_key});               exit 0 }
if (defined $OPT{change_passphrase}) { cmd_change_passphrase($OPT{change_passphrase}); exit 0 }
if (defined $OPT{default_user})      { cmd_default_user($OPT{default_user});           exit 0 }

if ($OPT{encrypt})                 { encrypt_file(\%OPT);        exit 0 }
if ($OPT{decrypt})                 { decrypt_file(\%OPT);        exit 0 }
if ($OPT{clear_sign})              { cmd_clear_sign(\%OPT);      exit 0 }
if ($OPT{detach_sign})             { cmd_detach_sign(\%OPT);     exit 0 }
if ($OPT{verify})                  { cmd_verify_clear(\%OPT);    exit 0 }
if (defined $OPT{verify_detached}) { cmd_verify_detached(\%OPT); exit 0 }

help(1);

__END__

PROTOCOL (plage format v1)
==========================

Goals: confidentiality + integrity of the whole file (including truncation and reordering),
no unauthenticated metadata, streaming operation in constant memory, anonymous recipients,
and signatures that are bound to what was signed and to whom it was encrypted.

Primitives
----------
  AEAD        ChaCha20-Poly1305 (RFC 8439, 96-bit nonce, 128-bit tag)
  KEM         X25519 (ephemeral-static Diffie-Hellman)
  KDF         HKDF-SHA256;  passphrases: Argon2id (default) or PBKDF2-HMAC-SHA512
  MAC         HMAC-SHA256
  Hash        BLAKE2b-512 (signature digests), SHA-256 (fingerprints)
  Signature   Ed25519

All integers are big-endian.

Encrypted file
--------------
  file    = header payload
  header  = "PLAGE" version(1) flags(1) compression(1) chunk_log2(1) n_recipients(1)
            payload_nonce(16) stanza{n_recipients} header_mac(32)
  flags       bit 0: the plaintext stream ends with a signature trailer
  compression 0 none, 1 zlib, 2 bzip2, 3 xz
  chunk_log2  chunk size = 2^chunk_log2 bytes (12..24, default 16)

  stanza (X25519, type 1, 81 bytes):
      type(1) ephemeral_public(32) wrapped_file_key(32 + 16)
        shared   = X25519(ephemeral_private, recipient_public)       (all-zero output is rejected)
        wrap_key = HKDF-SHA256(ikm = shared, salt = ephemeral_public || recipient_public,
                               info = "plage-v1 x25519 wrap")
        wrapped_file_key = ChaCha20-Poly1305(wrap_key, nonce = 0^12, aad = "", file_key)

  stanza (passphrase, type 2, 75 bytes; must be the only stanza):
      type(1) kdf(1) p1(4) p2(4) p3(1) salt(16) wrapped_file_key(48)
        kdf 1 = Argon2id: p1 = iterations, p2 = memory in KiB, p3 = parallelism
        kdf 2 = PBKDF2-HMAC-SHA512: p1 = iterations
        wrap_key = HKDF-SHA256(ikm = KDF(passphrase, salt), salt = salt,
                               info = "plage-v1 passphrase wrap")
      Parameters are bounded by the reader so that a hostile file can't force excessive work.

  There are no recipient identifiers: a reader tries each of its keys against each stanza.

  header_mac = HMAC-SHA256(HKDF-SHA256(file_key, "", "plage-v1 header mac"), all header bytes before the MAC)
  A reader MUST verify the MAC after unwrapping the file key and before releasing any plaintext.
  Because a random 32-byte file_key is created for each file and every stanza wraps the same key,
  a sender can't make different recipients see different headers.

Payload (STREAM)
----------------
  payload_key = HKDF-SHA256(ikm = file_key, salt = payload_nonce, info = "plage-v1 payload")
  The (optionally compressed) plaintext stream, followed by the signature trailer if flag 0 is set,
  is cut in chunks of chunk_size bytes; every chunk but the last has exactly chunk_size bytes, the
  last has 1..chunk_size bytes (0 only if the entire stream is empty).
  chunk_i = ChaCha20-Poly1305(payload_key, nonce = 0^3 || counter_i(8) || final(1), aad = "", chunk)
  counter_i starts at 0; final is 1 for the last chunk only and 0 otherwise. This prevents
  truncation, extension, reordering, and chunk duplication. A reader MUST fail if the stream
  ends without a final chunk, if data follows the final chunk, or if the final chunk is empty
  but not the first. Plaintext of a chunk is only released after its tag verified.

Compression
-----------
  Applied to the plaintext before chunking (a single compressed stream). The trailer is never
  compressed. Readers bound the memory used for decompression and reject data after the end of
  the compressed stream. Compression before encryption leaks the compressed length;
  it is therefore disabled unless requested.

Signature trailer (flag 0)
--------------------------
  trailer = time(8) ed25519_public(32) signature(64)         (104 bytes, last bytes of the stream)
  signature = Ed25519(signature_message(type = 1, time, public, binding = BLAKE2b-512(header),
                                        digest = BLAKE2b-512(original plaintext)))
  signature_message = "plage-v1 signature\0" type(1) hash_id(1) time(8) ed25519_public(32)
                      len(binding)(2) binding digest
  The signature is inside the encryption (the signer's identity is hidden from outsiders) and is
  bound to the whole header, i.e. to the recipient set: a recipient can't re-encrypt the signed
  data for someone else and make it look like the sender did so. Types separate the contexts:
  1 = encrypted file, 2 = detached signature, 3 = clear-signed text.
  Since the plaintext is streamed out before the final signature is checked, the output file (-o)
  is only moved into place after verification; with standard output, a non-zero exit status means
  the output must be discarded (the data itself is always authenticated by the AEAD).

Detached signature / clear-signed text
--------------------------------------
  blob = "PLSG" version(1) type(1) hash_id(1) time(8) ed25519_public(32) signature(64)
  Armored with label "PLAGE SIGNATURE". Clear-signed text is canonicalized (LF line endings, no
  trailing whitespace, final newline), lines starting with "-" are escaped with "- ", and the
  signature is over BLAKE2b-512 of the canonical text. Verification requires the signer to be
  in the keyring (or named with --signer).

ASCII armor
-----------
  "-----BEGIN PLAGE ENCRYPTED FILE-----", the binary file in base64 with exactly 64 characters
  per line (the last line may be shorter, with padding), "-----END PLAGE ENCRYPTED FILE-----".
  Readers are strict: no extra characters, no non-canonical line lengths, no trailing data.

Keys
----
  An identity is an X25519 key (encryption) plus an Ed25519 key (signing); the two are independent.
  Public key string: "plage1" + base32(version(1) x25519_pub(32) ed25519_pub(32) checksum(4)), where
  checksum = first 4 bytes of SHA-256("plage-v1 pubkey checksum\0" || previous fields).
  Fingerprint: SHA-256("plage-v1 fingerprint\0" || x25519_pub || ed25519_pub).
  Compare fingerprints out-of-band when importing keys.

Keyring
-------
  $XDG_CONFIG_HOME/plage/keyring.json (or ~/.config/plage/keyring.json), mode 0600, written atomically.
  Private keys (x25519_priv || ed25519_priv) are sealed with ChaCha20-Poly1305 under
  KDF(passphrase, random 16-byte salt); the public keys are authenticated as associated data.

