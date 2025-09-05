#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# 04 September 2025
# https://github.com/trizen

# Basic implementation of the Meissel–Lehmer algorithm for counting the number of primes <= n in sublinear time.

# See also:
#   https://en.wikipedia.org/wiki/Meissel%E2%80%93Lehmer_algorithm

use 5.036;
use ntheory qw(:all);

no warnings 'recursion';

# Memoization
my %phi_cache;
my %pi_cache;

# Recursive φ(n, a): numbers <= n not divisible by first a primes
sub recursive_rough_count ($n, $P) {

    sub ($n, $a) {

        my $key = "$n,$a";

        return $phi_cache{$key}
          if exists $phi_cache{$key};

        my $count = $n - ($n >> 1);

        foreach my $j (1 .. $a - 1) {
            my $np = divint($n, $P->[$j]);
            last if ($np == 0);
            $count -= __SUB__->($np, $j);
        }

        $phi_cache{$key} = $count;
      }
      ->($n, scalar @$P);
}

# P2 correction term
sub P2($n, $a, $p_a) {

    my $j     = $a;
    my $lo    = $p_a + 1;
    my $hi    = sqrtint($n);
    my $count = 0;

    foreach my $p (@{primes($lo, $hi)}) {
        $count += meissel_lehmer_prime_count(divint($n, $p)) - $j++;
    }

    return $count;
}

# Meissel-Lehmer prime-counting function
sub meissel_lehmer_prime_count($n) {

    return $pi_cache{$n}
      if exists $pi_cache{$n};

    if ($n <= 10) {
        return $pi_cache{$n} = (0, 0, 1, 2, 2, 3, 3, 4, 4, 4, 4)[$n];
    }

    my $cbrt = rootint($n, 3) + 1;
    my @P    = @{primes($cbrt)};
    my $a    = scalar @P;
    my $p_a  = $P[-1];

    my $phi = recursive_rough_count($n, \@P);
    my $p2  = P2($n, $a, $p_a);

    my $result = $phi + $a - 1 - $p2;
    $pi_cache{$n} = $result;
}

# --- Testing Loop ---
for my $n (1 .. 9) {

    my $ten_pow_n = powint(10, $n);
    my $pi_est    = meissel_lehmer_prime_count($ten_pow_n);
    say "pi(10^$n) = $pi_est";

    my $x   = int(rand($ten_pow_n));
    my $ref = prime_count($x);                  # MPU's built-in π(x)
    my $cmp = meissel_lehmer_prime_count($x);

    die "Mismatch at x=$x: $cmp != $ref" unless $cmp == $ref;
}

__END__
pi(10^1) = 4
pi(10^2) = 25
pi(10^3) = 168
pi(10^4) = 1229
pi(10^5) = 9592
pi(10^6) = 78498
pi(10^7) = 664579
pi(10^8) = 5761455
pi(10^9) = 50847534
