#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 01 August 2017
# https://github.com/trizen

# An efficient implementation of a new primality test, inspired from the AKS primality test.

# When n>2 is a (pseudo)prime:
#
#   (2 + sqrt(-1))^n - (sqrt(-1))^n - 2 = 0 (mod n)
#

# By breaking the formula into pieces, we get the following equivalent statements:
#
#   5^(n/2) * cos(n * atan(1/2)) = 2 (mod n)
#   5^(n/2) * sin(n * atan(1/2)) = { n-1   if n=3 (mod 4)
#                                      1   if n=1 (mod 4) } (mod n)
#

# Additionally, we have the following two identities:
#
#   cos(n * atan(1/2)) = (((2+i)/sqrt(5))^n + exp(-1 * log((2+i)/sqrt(5)) * n))/2
#   sin(n * atan(1/2)) = (((2+i)/sqrt(5))^n - exp(-1 * log((2+i)/sqrt(5)) * n))/(2i)
#

# For numbers of the form `2n+1`, the above formulas simplify to:
#
#   cos((2*n + 1) * atan(1/2)) = a(n)/(sqrt(5) * 5^n)
#   sin((2*n + 1) * atan(1/2)) = b(n)/(sqrt(5) * 5^n)
#
# where `a(n)` and `b(n)` are integers given by:
#
#   a(n) = real((2 + sqrt(-1))^n)
#   b(n) = imag((2 + sqrt(-1))^n)
#
# Defined recursively as:
#
#   a(1) = 2; a(2) = 3; a(n) = 4*a(n-1) - 5*a(n-2)
#   b(1) = 1; b(2) = 4; b(n) = 4*b(n-1) - 5*b(n-2)
#

# Currently, we use only the `b(n)` branch, as it is strong enough to reject most composites.

# Known counter-examples (in order):
#   [1105, 1729, 2465, 10585, 15841, 29341, 38081, 40501, 41041, 46657, ...]

use 5.020;
use strict;
use warnings;

no warnings 'recursion';

use ntheory qw(is_prime);
use experimental qw(signatures);

sub mulmod {
    my ($n, $k, $mod) = @_;

    ref($mod)
        ? ((($n % $mod) * $k) % $mod)
        : ntheory::mulmod($n, $k, $mod);
}

sub modulo_test($n, $mod) {

    my %cache;

    sub ($n) {

        $n == 0 && return 1;
        $n == 1 && return 4;

        if (exists $cache{$n}) {
            return $cache{$n};
        }

        my $k = $n >> 1;

#<<<
        $cache{$n} = (
            $n % 2 == 0
             ? (mulmod(__SUB__->($k), __SUB__->($k),     $mod) - mulmod(mulmod(5, __SUB__->($k - 1), $mod), __SUB__->($k - 1), $mod)) % $mod
             : (mulmod(__SUB__->($k), __SUB__->($k + 1), $mod) - mulmod(mulmod(5, __SUB__->($k - 1), $mod), __SUB__->($k),     $mod)) % $mod
        );
#>>>

      }->($n - 1);
}

sub is_probably_prime($n) {

    $n <= 1 && return 0;
    $n == 2 && return 1;

    my $r = modulo_test($n, $n);

    ($n % 4 == 3) ? ($r == $n - 1) : ($r == 1);
}

#
## Run a few tests
#

say is_probably_prime(6760517005636313)   ? 'prime' : 'error';    #=> prime
say is_probably_prime(204524538079257577) ? 'prime' : 'error';    #=> prime
say is_probably_prime(904935283655003749) ? 'prime' : 'error';    #=> prime

# Big integers
eval {
    require Math::GMPz;
    say is_probably_prime(Math::GMPz->new('90123127846128741241234935283655003749'))                             ? 'prime' : 'error';    #=> prime
    say is_probably_prime(Math::GMPz->new('793534607085486631526003804503819188867498912352777'))                ? 'prime' : 'error';    #=> prime
    say is_probably_prime(Math::GMPz->new('6297842947207644396587450668076662882608856575233692384596461'))      ? 'prime' : 'error';    #=> prime
    say is_probably_prime(Math::GMPz->new('396090926269155174167385236415542573007935497117155349994523806173')) ? 'prime' : 'error';    #=> prime

    say "=> Testing large Mersenne primes...";

    # Mersenne primes
    say is_probably_prime(Math::GMPz->new(2)**127  - 1) ? 'prime' : 'error';   #=> prime
    say is_probably_prime(Math::GMPz->new(2)**521  - 1) ? 'prime' : 'error';   #=> prime
    say is_probably_prime(Math::GMPz->new(2)**1279 - 1) ? 'prime' : 'error';   #=> prime
    say is_probably_prime(Math::GMPz->new(2)**3217 - 1) ? 'prime' : 'error';   #=> prime
    say is_probably_prime(Math::GMPz->new(2)**4423 - 1) ? 'prime' : 'error';   #=> prime
};

# Find counter-examples
foreach my $n (1 .. 2500) {
    if (is_probably_prime($n)) {

        if (not is_prime($n)) {
            warn "Counter-example: $n\n";
        }
    }
    elsif (is_prime($n)) {

        # This should never happen.
        warn "Missed a prime: $n\n";
    }
}
