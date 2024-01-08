#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 10 January 2020
# https://github.com/trizen

# Prove the primality of a number N, using the Lucas `U` sequence and the Pocklington primality test, recursively factoring N-1 and N+1 (whichever is easier to factorize first).

# See also:
#   https://en.wikipedia.org/wiki/Pocklington_primality_test
#   https://en.wikipedia.org/wiki/Primality_certificate
#   https://mathworld.wolfram.com/PrattCertificate.html
#   https://math.stackexchange.com/questions/663341/n1-primality-proving-is-slow

use 5.020;
use strict;
use warnings;
use experimental qw(signatures);

use List::Util qw(uniq);
use ntheory qw(is_prime is_prob_prime);
use Math::Prime::Util::GMP qw(ecm_factor is_strong_pseudoprime);

use Math::AnyNum qw(
  :overload prod primorial is_coprime powmod
  irand min is_square lucasUmod gcd kronecker
  );

my $TRIAL_LIMIT = 10**6;
my $primorial   = primorial($TRIAL_LIMIT);

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

    return ($n, @f);
}

sub lucas_pocklington_primality_proving ($n, $lim = 2**64) {

    if ($n <= $lim or $n <= 2) {
        return is_prime($n);    # fast deterministic test for small n
    }

    is_prob_prime($n) || return 0;

    if (ref($n) ne 'Math::AnyNum') {
        $n = Math::AnyNum->new("$n");
    }

    my $nm1 = $n - 1;
    my $np1 = $n + 1;

    my ($B1, @f1) = trial_factor($nm1);
    my ($B2, @f2) = trial_factor($np1);

    if (prod(@f1) < $B1 and prod(@f2) < $B2) {
        if ($B1 < $B2) {
            if (__SUB__->($B1)) {
                push @f1, $B1;
                $B1 = 1;
            }
            elsif (__SUB__->($B2)) {
                push @f2, $B2;
                $B2 = 1;
            }
        }
        else {
            if (__SUB__->($B2)) {
                push @f2, $B2;
                $B2 = 1;
            }
            elsif (__SUB__->($B1)) {
                push @f1, $B1;
                $B1 = 1;
            }
        }
    }

    my $pocklington_primality_proving = sub {

        foreach my $p (uniq(@f1)) {
            for (; ;) {
                my $a = irand(2, $nm1);
                is_strong_pseudoprime($n, $a) || return 0;
                if (is_coprime(powmod($a, $nm1 / $p, $n) - 1, $n)) {
                    say "a = $a ; p = $p";
                    last;
                }
            }
        }

        return 1;
    };

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

    my $lucas_primality_proving = sub {
        my ($P, $Q, $D) = $find_PQD->();

        is_strong_pseudoprime($n, $P + 1) or return 0;
        lucasUmod($P, $Q, $np1, $n) == 0  or return 0;

        foreach my $p (uniq(@f2)) {
            for (; ;) {
                $D == ($P * $P - 4 * $Q) or die "error: $P^2 - 4*$Q != $D";

                if ($P >= $n or $Q >= $n) {
                    return __SUB__->();
                }

                if (is_coprime(lucasUmod($P, $Q, $np1 / $p, $n), $n)) {
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
        my $A1 = prod(@f1);
        my $A2 = prod(@f2);

        if ($A1 > $B1 and is_coprime($A1, $B1)) {
            say "\n:: N-1 primality proving of: $n";
            return $pocklington_primality_proving->();
        }

        if ($A2 > $B2 and is_coprime($A2, $B2)) {
            say "\n:: N+1 primality proving of: $n";
            return $lucas_primality_proving->();
        }

        my @ecm_factors = map { Math::AnyNum->new($_) } ecm_factor($B1 * $B2);

        foreach my $p (@ecm_factors) {

            if ($B1 % $p == 0 and __SUB__->($p, $lim)) {
                while ($B1 % $p == 0) {
                    push @f1, $p;
                    $A1 *= $p;
                    $B1 /= $p;
                }
                if (__SUB__->($B1, $lim)) {
                    push @f1, $B1;
                    $A1 *= $B1;
                    $B1 /= $B1;
                }
                last if ($A1 > $B1);
            }

            if ($B2 % $p == 0 and __SUB__->($p, $lim)) {
                while ($B2 % $p == 0) {
                    push @f2, $p;
                    $A2 *= $p;
                    $B2 /= $p;
                }
                if (__SUB__->($B2, $lim)) {
                    push @f2, $B2;
                    $A2 *= $B2;
                    $B2 /= $B2;
                }
                last if ($A2 > $B2);
            }
        }
    }
}

say "Is prime: ",
  lucas_pocklington_primality_proving(115792089237316195423570985008687907853269984665640564039457584007913129603823);

__END__
:: N+1 primality proving of: 924116845936603030416149
P = 446779227 ; Q = -570813692 ; p = 2
P = 446779229 ; Q = -124034464 ; p = 3
P = 446779229 ; Q = -124034464 ; p = 5
P = 446779229 ; Q = -124034464 ; p = 23
P = 446779229 ; Q = -124034464 ; p = 839
P = 446779229 ; Q = -124034464 ; p = 319260971804461153

:: N-1 primality proving of: 145206169609764066844927343258645146513471
a = 65398207550754611976310922745879907064270 ; p = 2
a = 4798691037244889621933820261318904161487 ; p = 3
a = 116906491330255234184370825424228431344076 ; p = 5
a = 136169406264815751493129123529048530997722 ; p = 13
a = 135944141295463967893304597786628217140508 ; p = 37
a = 97262888879650744356761188900815226887264 ; p = 5419
a = 2902916905620381183086755524953265942224 ; p = 2009429159
a = 107195181666607031025002747775812085643863 ; p = 924116845936603030416149

:: N-1 primality proving of: 767990784468614637092681680819989903265059687929
a = 603854703399300341344639520448381233631361828843 ; p = 2
a = 107195257716196052909052603688672743914499334958 ; p = 661121
a = 138452952948919213705556701864021372614716309358 ; p = 145206169609764066844927343258645146513471

:: N+1 primality proving of: 1893865274499603695070553024902095101451637190432913
P = 903800454 ; Q = 701295878 ; p = 2
P = 903800454 ; Q = 701295878 ; p = 3
P = 903800454 ; Q = 701295878 ; p = 137
P = 903800454 ; Q = 701295878 ; p = 767990784468614637092681680819989903265059687929

:: N+1 primality proving of: 57896044618658097711785492504343953926634992332820282019728792003956564801911
P = 263931529 ; Q = -357766694 ; p = 2
P = 263931529 ; Q = -357766694 ; p = 3
P = 263931529 ; Q = -357766694 ; p = 1669
P = 263931529 ; Q = -357766694 ; p = 14083
P = 263931529 ; Q = -357766694 ; p = 1857767
P = 263931529 ; Q = -357766694 ; p = 29170630189
P = 263931529 ; Q = -357766694 ; p = 1893865274499603695070553024902095101451637190432913

:: N-1 primality proving of: 115792089237316195423570985008687907853269984665640564039457584007913129603823
a = 4029039168562415669306341971162211721541916673211300492678829534769579647404 ; p = 2
a = 56569963885874630697971498050698415523204083445143349658260796401052158770186 ; p = 57896044618658097711785492504343953926634992332820282019728792003956564801911
Is prime: 1
