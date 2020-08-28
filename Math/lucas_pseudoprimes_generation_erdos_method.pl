#!/usr/bin/perl

# Erdos construction method for Lucas D-pseudoprimes, for discriminant D = P^2-4Q:
#   1. Choose an even integer L with many divisors.
#   2. Let P be the set of primes p such that p-kronecker(D,p) divides L and p does not divide L.
#   3. Find a subset S of P such that n = prod(S) satisfies U_n(P,Q) == 0 (mod n) and kronecker(D,n) == -1.

# Alternatively:
#   3. Find a subset S of P such that n = prod(P) / prod(S) satisfies U_n(P,Q) == 0 (mod n) and kronecker(D,n) == -1.

use 5.020;
use warnings;

use ntheory qw(:all);
use List::Util qw(uniq);
use experimental qw(signatures);

sub lambda_primes ($L, $D) {

    # Primes p such that `p - kronecker(D,p)` divides L and p does not divide L.

    my @divisors = divisors($L);

    my @A = grep { ($_ > 2) and is_prime($_) and ($L % $_ != 0) and kronecker($D, $_) == -1 } map { $_ - 1 } @divisors;
    my @B = grep { ($_ > 2) and is_prime($_) and ($L % $_ != 0) and kronecker($D, $_) == +1 } map { $_ + 1 } @divisors;

    sort { $a <=> $b } uniq(@A, @B);
}

sub lucas_pseudoprimes ($L, $P = 1, $Q = -1) {

    my $D = ($P * $P - 4 * $Q);
    my @P = lambda_primes($L, $D);

    foreach my $k (2 .. @P) {
        forcomb {

            my $n = vecprod(@P[@_]);
            my $k = kronecker($D, $n);

            if ((lucas_sequence($n, $P, $Q, $n - $k))[0] == 0) {
                say $n;
            }
        } scalar(@P), $k;
    }
}

lucas_pseudoprimes(720, 1, -1);

__END__
323
1891
6601
13981
342271
1590841
852841
3348961
9937081
16778881
72881641
10756801
154364221
205534681
609865201
807099601
1438048801
7692170761
921921121
32252538601
222182990161
2051541911881
2217716806743361
