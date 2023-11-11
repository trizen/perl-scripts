#!/usr/bin/perl

# Erdos construction method for Carmichael numbers:
#   1. Choose an even integer L with many prime factors.
#   2. Let P be the set of primes d+1, where d|L and d+1 does not divide L.
#   3. Find a subset S of P such that prod(S) == 1 (mod L). Then prod(S) is a Carmichael number.

# Alternatively:
#   3. Find a subset S of P such that prod(S) == prod(P) (mod L). Then prod(P) / prod(S) is a Carmichael number.

use 5.036;
use Math::GMPz qw();
use ntheory    qw(:all);

# Primes p such that p-1 divides L and p does not divide L
sub lambda_primes ($L) {
    grep { $_ > 2 and $L % $_ != 0 and is_prime($_) } map { $_ + 1 } divisors($L);
}

sub method_1 ($L, $callback) {    # smallest numbers first

    my @P = lambda_primes($L);
    my @d = (Math::GMPz->new(1));

    foreach my $p (@P) {

        my @t;
        foreach my $u (@d) {
            my $t = $u * $p;
            push(@t, $t);
            if ($t % $L == 1) {
                $callback->($t);
            }
        }

        push @d, @t;
    }

    return;
}

sub method_2 ($L, $callback) {    # largest numbers first

    my @P = lambda_primes($L);
    my @d = (Math::GMPz->new(1));

    my $T = Math::GMPz->new(vecprod(@P));
    my $s = $T % $L;

    foreach my $p (@P) {

        my @t;
        foreach my $u (@d) {
            my $t = $u * $p;
            push(@t, $t);
            if ($t % $L == $s) {
                $callback->($T / $t) if ($T != $t);
            }
        }

        push @d, @t;
    }

    return;
}

method_1(720, sub ($c) { say $c });
method_2(720, sub ($c) { say $c });

__END__
41041
172081
15841
16778881
832060801
5310721
76595761
488881
20064165121
84127131361
561777121
18162001
115921
1932608161
133205761
1836304561
12262321
30614445878401
2110112460001
609865201
1945024664401
8879057210881
354725143201
3305455474321
1487328704641
65121765643441
