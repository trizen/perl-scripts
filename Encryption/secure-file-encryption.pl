#!/usr/bin/perl

# Authenticated streaming encryption.

use 5.036;
use Fcntl qw(
  O_CREAT
  O_EXCL
  O_WRONLY
);

use Getopt::Long  qw(GetOptions);
use Crypt::PRNG   qw(random_bytes);
use Crypt::Argon2 qw(argon2id_raw);
use Crypt::NaCl::Sodium;

binmode(STDOUT, ':raw');
binmode(STDIN,  ':raw');

use constant {
              MAGIC      => "SXC4",
              VERSION    => 1,
              SALT_SIZE  => 16,
              NONCE_SIZE => 24,            # crypto_secretbox_NONCEBYTES
              CHUNK_SIZE => 1024 * 1024,
              ARGON_T    => 3,
              ARGON_M    => 131072,        # 128MB
              ARGON_P    => 2,
              KEY_SIZE   => 32,
             };

sub fail ($msg) {
    die "ERROR: $msg\n";
}

sub read_exact ($fh, $len) {
    my $buf = '';
    while (length($buf) < $len) {
        my $r = read($fh, $buf, $len - length($buf), length($buf));
        defined($r)
          or fail("read failed: $!");
        $r > 0
          or fail("unexpected EOF");
    }
    return $buf;
}

sub derive_key ($password, $salt) {
    defined($password)
      or fail("missing password");
    length($password)
      or fail("empty password");
    return argon2id_raw($password, $salt, ARGON_T, ARGON_M, ARGON_P, KEY_SIZE);
}

sub secure_open_output ($filename) {
    sysopen(my $fh, $filename, O_WRONLY | O_CREAT | O_EXCL) or fail("refusing to overwrite '$filename': $!");
    binmode($fh, ':raw');
    return $fh;
}

sub encrypt_file ($input, $output, $password) {
    -f $input
      or fail("input is not a file");
    -r $input
      or fail("input is not readable");
    open(my $in, '<:raw', $input) or fail("cannot open '$input': $!");
    my $out  = secure_open_output($output);
    my $salt = random_bytes(SALT_SIZE);
    my $key  = derive_key($password, $salt);

    my $sodium    = Crypt::NaCl::Sodium->new;
    my $secretbox = $sodium->secretbox;

    print {$out}
      MAGIC, pack("C", VERSION), $salt
      or fail("write failed");

    my $counter = 0;
    while (1) {
        my $buffer;
        my $n = read($in, $buffer, CHUNK_SIZE);
        defined($n)
          or fail("read failed: $!");
        last if $n == 0;

        # Generate a unique nonce for each chunk (e.g., using a counter or random bytes)
        # Here we pack a 24-byte nonce using a counter or random bytes.
        # For simplicity and uniqueness per chunk, pack counter into nonce:
        my $nonce = pack("Q>", $counter++) . "\0" x (NONCE_SIZE - 8);

        my $ciphertext = $secretbox->encrypt($buffer, $nonce, $key);

        print {$out}
          pack("N", length($nonce)), $nonce, pack("N", length($ciphertext)), $ciphertext
          or fail("write failed");
    }
    close($in)  or fail("close failed");
    close($out) or fail("close failed");
    $key =~ tr/\0-\377/\0/;
}

sub decrypt_file ($input, $output, $password) {
    -f $input
      or fail("input is not a file");
    -r $input
      or fail("input is not readable");
    open(my $in, '<:raw', $input) or fail("cannot open '$input': $!");

    my $magic = read_exact($in, 4);
    $magic eq MAGIC
      or fail("not an SXC4 file");

    my $version = unpack("C", read_exact($in, 1));
    $version == VERSION
      or fail("unsupported format version");

    my $salt = read_exact($in, SALT_SIZE);
    my $key  = derive_key($password, $salt);

    my $sodium    = Crypt::NaCl::Sodium->new;
    my $secretbox = $sodium->secretbox;
    my $out       = secure_open_output($output);

    while (1) {
        my $nbuf;
        my $n = read($in, $nbuf, 4);
        defined($n) or fail("read error");
        last if $n == 0;
        $n == 4 or fail("truncated file");

        my $nonce_len = unpack("N", $nbuf);
        my $nonce     = read_exact($in, $nonce_len);

        my $cibuf      = read_exact($in, 4);
        my $cipher_len = unpack("N", $cibuf);

        my $ciphertext = read_exact($in, $cipher_len);

        my $plaintext;
        eval { $plaintext = $secretbox->decrypt($ciphertext, $nonce, $key); };
        if ($@) {
            fail("authentication failed (wrong password or corrupted file)");
        }

        print {$out} $plaintext
          or fail("write failed");
    }

    close($in)  or fail("close failed");
    close($out) or fail("close failed");
    $key =~ tr/\0-\377/\0/;
}

sub usage ($code = 0) {
    print <<"EOF";
usage:

Encrypt:
  $0 --encrypt --key password input.file output.sxc

Decrypt:
  $0 --decrypt --key password input.sxc output.file

Options:
  -e --encrypt
  -d --decrypt
  -k --key
  -h --help
EOF
    exit($code);
}

my $encrypt = 0;
my $decrypt = 0;
my $key;

GetOptions(
           'encrypt|e' => \$encrypt,
           'decrypt|d' => \$decrypt,
           'key|k=s'   => \$key,
           'help|h'    => sub { usage(0) },
          )
  or usage(1);

($encrypt xor $decrypt)
  or fail("specify exactly one of --encrypt or --decrypt");

defined($key) && length($key)
  or fail("missing --key");

@ARGV == 2
  or usage(1);

my ($input, $output) = @ARGV;

if ($encrypt) {
    encrypt_file($input, $output, $key);
}
else {
    decrypt_file($input, $output, $key);
}

