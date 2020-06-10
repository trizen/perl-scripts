#!/usr/bin/perl

# Erdos construction method for Carmichael numbers:
#   1. Choose an even integer L with many prime factors.
#   2. Let P be the set of primes d+1, where d|L and d+1 does not divide L.
#   3. Find a subset S of P such that prod(S) == 1 (mod L). Then prod(S) is a Carmichael number.

# Alternatively:
#   3. Find a subset S of P such that prod(S) == prod(P) (mod L). Then prod(P) / prod(S) is a Carmichael number.

use 5.020;
use warnings;
use ntheory qw(:all);
use experimental qw(signatures);

# Modular product of a list of integers
sub vecprodmod ($arr, $mod) {
    my $prod = 1;
    foreach my $k (@$arr) {
        $prod = mulmod($prod, $k, $mod);
    }
    $prod;
}

# Primes p such that p-1 divides L and p does not divide L
sub lambda_primes ($L) {
    grep { $L % $_ != 0 } grep { $_ > 2 and is_prime($_) } map { $_ + 1 } divisors($L);
}

sub method_1 ($L) {     # smallest numbers first

    my @P = lambda_primes($L);

    foreach my $k (3 .. @P) {
        forcomb {
            if (vecprodmod([@P[@_]], $L) == 1) {
                say vecprod(@P[@_]);
            }
        } scalar(@P), $k;
    }
}

sub method_2 ($L) {     # largest numbers first

    my @P = lambda_primes($L);
    my $B = vecprodmod(\@P, $L);
    my $T = vecprod(@P);

    foreach my $k (1 .. (@P-3)) {
        forcomb {
            if (vecprodmod([@P[@_]], $L) == $B) {
                my $S = vecprod(@P[@_]);
                say ($T / $S) if ($T != $S);
            }
        } scalar(@P), $k;
    }
}

method_1(720);
method_2(720);

__END__
15841
115921
488881
41041
172081
5310721
12262321
16778881
18162001
76595761
609865201
133205761
561777121
1836304561
832060801
1932608161
20064165121
84127131361
354725143201
1487328704641
3305455474321
1945024664401
2110112460001
8879057210881
65121765643441
30614445878401
