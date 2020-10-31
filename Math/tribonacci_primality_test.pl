#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 18 May 2019
# https://github.com/trizen

# A new primality test, using a Tribonacci-like sequence.

# Sequence definition:
#   T(0) = 0
#   T(1) = 0
#   T(2) = 9
#   T(n) = T(n-1) + 3*T(n-2) + 9*T(n-3)

# Closed form:
#   T(n) = (-9 sqrt(2) (-1 + i sqrt(2))^n + 2 (sqrt(2) + 4 i)×3^n + (7 sqrt(2) - 8 i) (-1 - i sqrt(2))^n)/(4 (sqrt(2) + 4 i))

# The sequence starts as:
#   0, 0, 9, 9, 36, 144, 333, 1089, 3384, 9648, 29601, 89001, 264636, 798048, ...

# When p is a prime > 5 congruent to {1,3} mod 8, then T(p) == 0 (mod p).
# When p is a prime > 5 congruent to {5,7} mod 8, then T(p) == 4 (mod p).

# Counter-examples:
#   for n == 1 (mod 8): 88561,107185,162401,221761,226801,334153,410041,665281,825265,1569457,1615681,2727649, ...
#   for n == 3 (mod 8): 80375707,154287451,267559627,326266051,478614067,573183451,643767931,2433943891,4297753027, ....

# See also:
#   https://trizenx.blogspot.com/2020/01/primality-testing-algorithms.html

use 5.020;
use strict;
use warnings;

use Math::AnyNum qw(:overload);
use Math::MatrixLUP;

use ntheory qw(is_prime);
use experimental qw(signatures);

my $A = Math::MatrixLUP->new([[0, 3, 0], [0, 0, 3], [1, 1, 1]]);
my $B = Math::MatrixLUP->new([[4, 2, 3], [1, 5, 3], [1, 2, 6]]);
my $I = Math::MatrixLUP->new([[1, 0, 0], [0, 1, 0], [0, 0, 1]]);

sub is_tribonacci_prime ($n) {

    my $r = $n % 8;

    if ($r == 1 or $r == 3) {
        return ($A->powmod($n - 1, $n) == $I);
    }

    if ($r == 5 or $r == 7) {
        return ($A->powmod($n + 1, $n) == $B);
    }

    return;
}

local $| = 1;
foreach my $n (7 .. 1e3) {
    if (is_tribonacci_prime($n)) {
        if (not is_prime($n)) {
            say "\nCounter-example: $n\n";
        }
        print($n, ", ");
    }
    elsif (is_prime($n)) {
        say "\nMissed prime: $n\n";
    }
}
