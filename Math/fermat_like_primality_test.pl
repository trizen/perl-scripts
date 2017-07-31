#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 31 July 2017
# https://github.com/trizen

# A weak primality test, inspired from the AKS primality test and Fermat's little theorem.

# No known counter-examples are known.

# Conjecture: if there exists any counter-examples, they are all semiprimes.

# A much weaker version, if n is a (pseudo)prime, then:
#   (2 + sqrt(-1))^n - (sqrt(-1))^n - 2 = 0 (mod n)

# Equivalently, let:
#   f(n) = (2 + sqrt(-1))^n - (sqrt(-1))^n - 2

# Then the following expressions are true when n is a (pseudo)prime:
#   Re(f(n)) = 0 (mod n)
#   Im(f(n)) = 0 (mod n)

# Counter-examples known for this weaker versions, are:
# [1105, 2465, 10585, 15841, ...]

use 5.010;
use strict;
use warnings;

use ntheory qw(forprimes powmod is_prime prime_iterator);

sub legendre_power {
    my ($n, $p) = @_;

    my $s = 0;
    while ($n >= $p) {
        $s += int($n /= $p);
    }

    $s;
}

sub modular_binomial {
    my ($n, $k, $m) = @_;

    my $j = $n - $k;

    my $prod = 1;
    my $iter = prime_iterator();

    while ((my $q = $iter->()) <= $n) {
        my $p = legendre_power($n, $q);

        if ($q <= $k) {
            $p -= legendre_power($k, $q);
        }

        if ($q <= $j) {
            $p -= legendre_power($j, $q);
        }

        if ($p > 0) {
            $prod *= ($p == 1) ? ($q % $m) : powmod($q, $p, $m);
            $prod %= $m;
            $prod == 0 and return 0;
        }
    }

    $prod;
}

sub is_probably_prime {
    my ($n) = @_;

    return 0 if $n <= 1;
    return 1 if $n == 2;

    my $re = 0;
    my $im = 0;

    if ($n % 4 == 0) {
        $re -= 1;
    }
    elsif ($n % 4 == 1) {
        $im -= 1;
    }
    elsif ($n % 4 == 2) {
        $re += 1;
    }
    elsif ($n % 4 == 3) {
        $im += 1;
    }

    my $c = 2;
    my $r = log($n)**2;    # can the exponent be improved?

    $re -= $c;

    my $count = 0;
    my ($p_re, $p_im) = ($re, $im);

    foreach my $k (0 .. $n) {
        my $t = (modular_binomial($n, $k, $n) * powmod($c, ($n - $k), $n)) % $n;

        if ($k % 4 == 0) {
            $re += $t;
            $re %= $n;
        }
        elsif ($k % 4 == 1) {
            $im += $t;
            $im %= $n;
        }
        elsif ($k % 4 == 2) {
            $re -= $t;
            $re %= $n;
        }
        elsif ($k % 4 == 3) {
            $im -= $t;
            $im %= $n;
        }

        if (
            $re == 0
            and (   $im == -1
                 or $im == $n - 1
                 or $im == 1
                 or $im == 0)
          ) {

            #say "$n: [$re, $im]";

            if ($count >= $r) {
                return 1;
            }

            if ($re == $p_re and $im == $p_im) {
                ++$count;
            }
            else {
                $count = 0;
            }

        }
        else {
            return 0;    # 100% composite
        }

        ($p_re, $p_im) = ($re, $im);
    }

    if ($im == 0 and $re == 0) {
        return 1;
    }

    return 0;
}

my $count = 0;
my $from  = 1;
my $to    = 100;

foreach my $n ($from .. $to) {
    if (is_probably_prime($n)) {

        if (not is_prime($n)) {
            warn "composite identified as prime: $n";
            sleep 1;
        }

        say $n;
        $count += 1;
    }
    elsif (is_prime($n)) {
        warn "missed a prime: $n";
        sleep 1;
    }
}

say "There are $count primes in the range [$from, $to].";
