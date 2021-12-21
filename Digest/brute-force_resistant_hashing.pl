#!/usr/bin/perl

# Author: Trizen
# Date: 21 December 2021
# https://github.com/trizen

# A concept for a brute-force resistant hashing method.

# It requires a deterministic hash function, which is used in computing a
# non-deterministic brute-force resistant hash, based on the processor speed
# of the computer, taking about 2 seconds to hash a password, and about 1.5 seconds
# to verify if the hash of a password is correct, given the password and the hash.

# The method can be made deterministic, by providing a fixed number of iterations.
# Otherwise, the method automatically computes a safe number of iterations based on hardware speed.

# See also:
#   https://en.wikipedia.org/wiki/Bcrypt
#   https://en.wikipedia.org/wiki/Argon2

use 5.020;
use strict;
use warnings;

use Digest::SHA qw(sha512_hex);
use experimental qw(signatures);

sub bfr_hash ($password, $hash_function, $iterations = undef) {

    my $strength = 1;    # delay time in seconds

    my $salt_hash = $hash_function->('');
    my $pass_hash = $hash_function->($password);

    my $hash_password = sub {
        $salt_hash = $hash_function->($salt_hash);
        $pass_hash = $hash_function->($salt_hash . $pass_hash);
        #$pass_hash = $hash_function->($pass_hash . $salt_hash);
    };

    if (defined $iterations) {
        for (1 .. $iterations) {
            $hash_password->();
        }
    }
    else {

        $iterations = 0;

        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            alarm $strength;

            while (1) {
                $hash_password->();
                ++$iterations;
            }

            alarm 0;
        };

        say "[DEBUG] Iterations: $iterations";
        return __SUB__->($password, $hash_function, $iterations);
    }

    my $check_hash = $hash_function->($pass_hash . $salt_hash);
    return join('$', $pass_hash, $salt_hash, $check_hash);
}

sub check_bfr_hash ($password, $bfr_hash, $hash_function) {
    my ($pass_hash, $salt_hash, $check_hash) = split(/\$/, $bfr_hash);

    $salt_hash  // return 0;
    $pass_hash  // return 0;
    $check_hash // return 0;

    if ($hash_function->($pass_hash . $salt_hash) ne $check_hash) {
        return 0;
    }

    my $iterations = 0;
    my $hash       = $hash_function->('');

    while (1) {
        $hash = $hash_function->($hash);
        ++$iterations;
        last if ($hash eq $salt_hash);
    }

    if (bfr_hash($password, $hash_function, $iterations) eq $bfr_hash) {
        return 1;
    }

    return 0;
}

my $password1 = 'foo';
my $password2 = 'bar';

my $hash1 = bfr_hash($password1, \&sha512_hex);
my $hash2 = bfr_hash($password2, \&sha512_hex);

say qq{bfr_hash("$password1", sha512) = $hash1};
say qq{bfr_hash("$password2", sha512) = $hash2};

say check_bfr_hash($password1, $hash1, \&sha512_hex);    #=> 1
say check_bfr_hash($password2, $hash2, \&sha512_hex);    #=> 1
say check_bfr_hash($password1, $hash2, \&sha512_hex);    #=> 0
say check_bfr_hash($password2, $hash1, \&sha512_hex);    #=> 0

__END__
bfr_hash("foo", sha512) = d0cd2ed4ef19e55ea8d69212417e21d5723e41a716f74fea2bbc7d8e114108d1a439c763b2673c2e79ccc684b7558d42956982d6396abd6bcd99aca30b516787$a65bff3e58823c51d7a4a44bcebc8f5c8ba148e3eea81fc017ecd20eb94b5892f2112e397a48e5185ab500051ec285a0a9d104a6eed4828d04cc0661c0ea1885$03061c61439174d1a4f8f3fa73e53ff9b9480f02afa270544aaeacfc6cc08db27742f2d3721edc13a4cefabb0accbf476ef6c9596932fc81816c018e8fd6ca6e
bfr_hash("bar", sha512) = 3eefe86bfbc36d7099625a3b3ab741c373435ab873d841eccbf9db465637b0c7a7e612cbc65fda0a9333c2065d10cbcb8120a8271b932234849753f899c4c396$906e9a62689d2bc012ff83f777432a2b1235faeff01a582d1fb3eb6b5201f1bca4174a4a983b6951fb211936d2040468c2a695f7b74ad45dcb76789ef267b9a9$e5bc95297be88c0b8003c731a052968ed6c2c75fceea2844e2584fdd05ae97ffa1795dc7f73e6b9c9c7c91d294dc7f435d687221fbf945d6d590fce7f54fcf7d
