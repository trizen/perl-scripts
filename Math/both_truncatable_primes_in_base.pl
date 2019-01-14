#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 January 2019
# https://github.com/trizen

# Generate the entire sequence of both-truncatable primes in a given base.

# Optimization:
#   there are far fewer right-truncatable primes than are left-truncatable primes,
#   so we can generate only the RTPs and then check which ones are also LTPs.

# Maximum value for each base is given in the following OEIS sequence:
#   https://oeis.org/A323137

# Total number of primes that are both left-truncatable and right-truncatable in base n:
#   https://oeis.org/A323390

# See also:
#   https://www.youtube.com/watch?v=azL5ehbw_24
#   https://en.wikipedia.org/wiki/Truncatable_prime

# Related sequences:
#  https://oeis.org/A076586 - Total number of right truncatable primes in base n.
#  https://oeis.org/A076623 - Total number of left truncatable primes (without zeros) in base n.
#  https://oeis.org/A323390 - Total number of primes that are both left-truncatable and right-truncatable in base n.
#  https://oeis.org/A323396 - Irregular array read by rows, where T(n, k) is the k-th prime that is both left-truncatable and right-truncatable in base n.

use 5.010;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(primes vecmax);
use Math::Prime::Util::GMP qw(vecsum is_prob_prime);

sub digits2num {
    my ($arr, $base) = @_;

    my $t   = Math::GMPz::Rmpz_init_set_ui(1);
    my $sum = Math::GMPz::Rmpz_init_set_ui(0);

    foreach my $d (@$arr) {
        Math::GMPz::Rmpz_addmul_ui($sum, $t, $d);
        Math::GMPz::Rmpz_mul_ui($t, $t, $base);
    }

    $sum;
}

sub right_truncatable_primes {
    my ($p, $base) = @_;

    my @seq = ($p);

    foreach my $n (1 .. $base - 1) {
        my @next = ($n, @$p);
        if (is_prob_prime(digits2num(\@next, $base))) {
            push @seq, right_truncatable_primes(\@next, $base);
        }
    }

    return @seq;
}

sub is_left_truncatable {
    my ($n, $base) = @_;

    for (my @arr = @$n ; @arr > 0 ; pop(@arr)) {
        is_prob_prime(digits2num(\@arr, $base)) || return 0;
    }

    return 1;
}

sub both_truncatable_primes_in_base {
    my ($base) = @_;

    if ($base <= 2) {
        return;
    }

    my @right;
    foreach my $p (@{primes(2, $base - 1)}) {
        push @right, right_truncatable_primes([$p], $base);
    }

    map { digits2num($_, $base) } grep { is_left_truncatable($_, $base) } @right;
}

foreach my $base (3 .. 36) {
    my @t = both_truncatable_primes_in_base($base);
    printf("There are %3d both-truncatable primes in base %2d where largest is %s\n", scalar(@t), $base, vecmax(@t));
}

__END__
There are   2 both-truncatable primes in base  3 where largest is 23
There are   3 both-truncatable primes in base  4 where largest is 11
There are   5 both-truncatable primes in base  5 where largest is 67
There are   9 both-truncatable primes in base  6 where largest is 839
There are   7 both-truncatable primes in base  7 where largest is 37
There are  22 both-truncatable primes in base  8 where largest is 1867
There are   8 both-truncatable primes in base  9 where largest is 173
There are  15 both-truncatable primes in base 10 where largest is 739397
There are   6 both-truncatable primes in base 11 where largest is 79
There are  35 both-truncatable primes in base 12 where largest is 105691
There are  11 both-truncatable primes in base 13 where largest is 379
There are  37 both-truncatable primes in base 14 where largest is 37573
There are  17 both-truncatable primes in base 15 where largest is 647
There are  22 both-truncatable primes in base 16 where largest is 3389
There are  12 both-truncatable primes in base 17 where largest is 631
There are  69 both-truncatable primes in base 18 where largest is 202715129
There are  12 both-truncatable primes in base 19 where largest is 211
There are  68 both-truncatable primes in base 20 where largest is 155863
There are  18 both-truncatable primes in base 21 where largest is 1283
There are  44 both-truncatable primes in base 22 where largest is 787817
There are  13 both-truncatable primes in base 23 where largest is 439
There are 145 both-truncatable primes in base 24 where largest is 109893629
There are  16 both-truncatable primes in base 25 where largest is 577
There are  47 both-truncatable primes in base 26 where largest is 4195880189
There are  20 both-truncatable primes in base 27 where largest is 1811
There are  77 both-truncatable primes in base 28 where largest is 14474071
There are  13 both-truncatable primes in base 29 where largest is 379
There are 291 both-truncatable primes in base 30 where largest is 21335388527
There are  15 both-truncatable primes in base 31 where largest is 2203
There are  89 both-truncatable primes in base 32 where largest is 1043557
There are  27 both-truncatable primes in base 33 where largest is 2939
There are  74 both-truncatable primes in base 34 where largest is 42741029
