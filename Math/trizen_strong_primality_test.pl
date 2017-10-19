#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 02 August 2017
# https://github.com/trizen

# A very strong primality test, inspired by Fermat's Little Theorem and the AKS test.

# No counter-examples are known.

use 5.020;
use strict;
use warnings;

no warnings 'recursion';

use ntheory qw(is_prime powmod);
use experimental qw(signatures);

sub mulmod {
    my ($n, $k, $mod) = @_;

    ref($mod)
        ? ((($n % $mod) * $k) % $mod)
        : ntheory::mulmod($n, $k, $mod);
}

#
## Creates the `modulo_test*` subroutines.
#
foreach my $g (
    [1, 1,  4,  5],
    [2, 1,  3,  5],
    [3, 1,  5,  3],
    [4, 1,  3, 17],
    [5, 1, 11, 43],
) {

    no strict 'refs';
    *{__PACKAGE__ . '::' . 'modulo_test' . $g->[0]} = sub ($n, $mod) {
        my %cache;

        sub ($n) {

            $n == 0 && return $g->[1];
            $n == 1 && return $g->[2];

            if (exists $cache{$n}) {
                return $cache{$n};
            }

            my $k = $n >> 1;

#<<<
            $cache{$n} = (
                $n % 2 == 0
                    ? (mulmod(__SUB__->($k), __SUB__->($k),   $mod) - mulmod(mulmod($g->[3], __SUB__->($k-1), $mod), __SUB__->($k-1), $mod)) % $mod
                    : (mulmod(__SUB__->($k), __SUB__->($k+1), $mod) - mulmod(mulmod($g->[3], __SUB__->($k-1), $mod), __SUB__->($k),   $mod)) % $mod
            );
#>>>

          }->($n - 1);
    };
}

sub is_probably_prime($n) {

    $n <=  1 && return 0;
    $n ==  2 && return 1;
    $n ==  3 && return 1;
    $n == 11 && return 1;
    $n == 13 && return 1;
    $n == 17 && return 1;
    $n == 59 && return 1;

    powmod(2, $n-1, $n) == 1 or return 0;

    my $r1 = modulo_test1($n, $n);
    (($n % 4 == 3) ? ($r1 == $n-1) : ($r1 == 1)) or return 0;

    my $r2 = modulo_test2($n, $n);
    ($r2 == 1) or ($r2 == $n-1) or return 0;

    my $r3 = modulo_test3($n, $n);
    ($r3 == 1) or ($r3 == $n-1) or return 0;

    my $r4 = modulo_test4($n, $n);
    ($r4 == 1) or ($r4 == $n-1) or return 0;

    my $r5 = modulo_test5($n, $n);
    ($r5 == 1) or ($r5 == $n-1) or return 0;
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

say "=> Searching for counter-examples...";

# Look for counter-examples
foreach my $n (1..3000) {
    if (is_probably_prime($n)) {

        if (not is_prime($n)) {
            warn "Counter-example: $n\n";
        }
    }
    elsif (is_prime($n)) {
        warn "Missed a prime: $n\n";
    }
}
