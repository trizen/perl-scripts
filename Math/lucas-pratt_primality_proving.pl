#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 08 January 2020
# https://github.com/trizen

# Prove the primality of a number, using the Lucas `U` sequence, recursively factoring N+1.

# Choose P and Q such that D = P^2 - 4*Q is not a square modulo N.
# Let N+1 = F*R with F > R, where R is odd and the prime factorization of F is known.
# If there exists a Lucas sequence of discriminant D with U(N+1) == 0 (mod N) and gcd(U((N+1)/q), N) = 1 for each prime q dividing F, then N is prime;
# If no such sequence exists for a given P and Q, a new P' and Q' with the same D can be computed as P' = P + 2 and Q' = P + Q + 1 (the same D must be used for all the factors q).

# See also:
#   https://en.wikipedia.org/wiki/Primality_certificate
#   https://math.stackexchange.com/questions/663341/n1-primality-proving-is-slow

use 5.020;
use strict;
use warnings;
use experimental qw(signatures);

use List::Util qw(uniq);
use ntheory qw(is_prime is_prob_prime);
use Math::Prime::Util::GMP qw(ecm_factor is_strong_pseudoprime);

use Math::AnyNum qw(
  :overload prod primorial is_coprime
  irand min is_square lucasUmod gcd kronecker
  );

my $primorial = primorial(10**6);

sub trial_factor ($n) {

    my @f;
    my $g = gcd($primorial, $n);

    if ($g > 1) {
        my @primes = ntheory::factor($g);
        foreach my $p (@primes) {
            while ($n % $p == 0) {
                push @f, $p;
                $n /= $p;
            }
        }
    }

    $n > 1 and push(@f, $n);
    return @f;
}

sub lucas_primality_proving ($n, $lim = 2**64) {

    if ($n <= $lim or $n <= 2) {
        return is_prime($n);    # fast deterministic test for small n
    }

    is_prob_prime($n) || return 0;

    if (ref($n) ne 'Math::AnyNum') {
        $n = Math::AnyNum->new("$n");
    }

    my $d = $n + 1;
    my @f = trial_factor($d);
    my $B = pop @f;

    if (__SUB__->($B, $lim)) {
        push @f, $B;
        $B = 1;
    }

    my $find_PQD = sub {

        my $l = min(10**9, $n - 1);

        for (; ;) {
            my $P = (irand(1, $l));
            my $Q = (irand(1, $l) * ((rand(1) < 0.5) ? 1 : -1));
            my $D = ($P * $P - 4 * $Q);

            next if is_square($D % $n);
            next if ($P >= $n);
            next if ($Q >= $n);
            next if (kronecker($D, $n) != -1);

            return ($P, $Q, $D);
        }
    };

    my $primality_proving = sub {
        my ($P, $Q, $D) = $find_PQD->();

        is_strong_pseudoprime($n, $P + 1)  or return 0;
        lucasUmod($P, $Q, $n + 1, $n) == 0 or return 0;

        foreach my $p (uniq(@f)) {
            for (; ;) {
                $D == ($P * $P - 4 * $Q) or die "error: $P^2 - 4*$Q != $D";

                if ($P >= $n or $Q >= $n) {
                    return __SUB__->();
                }

                if (is_coprime(lucasUmod($P, $Q, $d / $p, $n), $n)) {
                    say "P = $P ; Q = $Q ; p = $p";
                    last;
                }

                ($P, $Q) = ($P + 2, $P + $Q + 1);
                is_strong_pseudoprime($n, $P) || return 0;
            }
        }

        return 1;
    };

    for (; ;) {
        my $A = prod(@f);

        if ($A > $B and is_coprime($A, $B)) {
            say "\n:: Proving primality of: $n";
            return $primality_proving->();
        }

        my @ecm_factors = map { Math::AnyNum->new($_) } ecm_factor($B);

        foreach my $p (@ecm_factors) {
            if (__SUB__->($p, $lim)) {
                while ($B % $p == 0) {
                    $B /= $p;
                    $A *= $p;
                    push @f, $p;
                }
            }
            if ($A > $B) {
                say ":: Stopping early with A = $A and B = $B" if ($B > 1);
                last;
            }
        }
    }
}

say "Is prime: ", lucas_primality_proving(115792089237316195423570985008687907853269984665640564039457584007913129603823);

__END__
:: Proving primality of: 160667761273563902473
P = 637005555 ; Q = -759408520 ; p = 2
P = 637005555 ; Q = -759408520 ; p = 23
P = 637005555 ; Q = -759408520 ; p = 137
P = 637005555 ; Q = -759408520 ; p = 2591
P = 637005555 ; Q = -759408520 ; p = 77261
P = 637005555 ; Q = -759408520 ; p = 127356937

:: Proving primality of: 84919921767502888050045396989
P = 154974193 ; Q = -225311358 ; p = 2
P = 154974199 ; Q = 239611230 ; p = 3
P = 154974199 ; Q = 239611230 ; p = 5
P = 154974199 ; Q = 239611230 ; p = 257
P = 154974199 ; Q = 239611230 ; p = 2539
P = 154974199 ; Q = 239611230 ; p = 160667761273563902473

:: Proving primality of: 767990784468614637092681680819989903265059687929
P = 339178992 ; Q = 3659163746 ; p = 2
P = 339178992 ; Q = 3659163746 ; p = 3
P = 339178994 ; Q = 3998342739 ; p = 5
P = 339178994 ; Q = 3998342739 ; p = 7
P = 339178994 ; Q = 3998342739 ; p = 56737
P = 339178994 ; Q = 3998342739 ; p = 190097
P = 339178994 ; Q = 3998342739 ; p = 3992873
P = 339178994 ; Q = 3998342739 ; p = 84919921767502888050045396989

:: Proving primality of: 1893865274499603695070553024902095101451637190432913
P = 699534120 ; Q = -225663681 ; p = 2
P = 699534120 ; Q = -225663681 ; p = 3
P = 699534120 ; Q = -225663681 ; p = 137
P = 699534120 ; Q = -225663681 ; p = 767990784468614637092681680819989903265059687929

:: Proving primality of: 115792089237316195423570985008687907853269984665640564039457584007913129603823
P = 753451984 ; Q = 491391542 ; p = 2
P = 753451984 ; Q = 491391542 ; p = 3
P = 753451984 ; Q = 491391542 ; p = 1669
P = 753451984 ; Q = 491391542 ; p = 14083
P = 753451984 ; Q = 491391542 ; p = 1857767
P = 753451984 ; Q = 491391542 ; p = 29170630189
P = 753451984 ; Q = 491391542 ; p = 1893865274499603695070553024902095101451637190432913
Is prime: 1
