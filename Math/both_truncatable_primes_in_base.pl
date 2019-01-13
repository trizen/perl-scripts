#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 January 2019
# https://github.com/trizen

# Generate the entire sequence of both-truncatable primes in a given base between 3 and 36.

# Optimization:
#   there are far fewer right-truncatable primes than are left-truncatable primes,
#   so we can generate only the RTPs and then check which ones are also LTPs.

# Maximum value for each base is given in the following OEIS sequence:
#   https://oeis.org/A323137

# See also:
#   https://www.youtube.com/watch?v=azL5ehbw_24
#   https://en.wikipedia.org/wiki/Truncatable_prime

# Related sequences:
#  https://oeis.org/A076586 - Total number of right truncatable primes in base n.
#  https://oeis.org/A076623 - Total number of left truncatable primes (without zeros) in base n.

# TODO: extend the program to bases > 36

use 5.010;
use strict;
use warnings;

use ntheory qw(fromdigits is_prob_prime vecmax);

sub right_truncatable_primes {
    my ($p, $base, $digits) = @_;

    my @seq = ($p);

    foreach my $n (@$digits) {
        my $next = "$p$n";
        if (is_prob_prime(fromdigits($next, $base))) {
            push @seq, right_truncatable_primes($next, $base, $digits);
        }
    }

    return @seq;
}

sub is_left_truncatable {
    my ($n, $base) = @_;

    while (length($n) > 0) {
        is_prob_prime(fromdigits($n, $base)) || return 0;
        $n = substr($n, 1);
    }

    return 1;
}

sub both_truncatable_primes_in_base {
    my ($base) = @_;

    if ($base < 3 or $base > 36) {
        die "error: base must be between 3 and 36\n";
    }

    my @digits = (1 .. $base - 1);

    if ($base > 10) {

        @digits = (1 .. 9);

        my $letter = 'a';
        for (1 .. $base - 10) {
            push @digits, $letter;
            ++$letter;
        }
    }

    my @prime_digits = grep { is_prob_prime(fromdigits($_, $base)) } @digits;

    my @right;
    foreach my $p (@prime_digits) {
        push @right, right_truncatable_primes($p, $base, \@digits);
    }

    map { fromdigits($_, $base) } grep { is_left_truncatable($_, $base) } @right;
}

foreach my $base (3 .. 36) {
    say "Largest both-truncatable prime in base $base is: ", vecmax(both_truncatable_primes_in_base($base));
}

__END__
Largest both-truncatable prime in base 3 is: 23
Largest both-truncatable prime in base 4 is: 11
Largest both-truncatable prime in base 5 is: 67
Largest both-truncatable prime in base 6 is: 839
Largest both-truncatable prime in base 7 is: 37
Largest both-truncatable prime in base 8 is: 1867
Largest both-truncatable prime in base 9 is: 173
Largest both-truncatable prime in base 10 is: 739397
Largest both-truncatable prime in base 11 is: 79
Largest both-truncatable prime in base 12 is: 105691
Largest both-truncatable prime in base 13 is: 379
Largest both-truncatable prime in base 14 is: 37573
Largest both-truncatable prime in base 15 is: 647
Largest both-truncatable prime in base 16 is: 3389
Largest both-truncatable prime in base 17 is: 631
Largest both-truncatable prime in base 18 is: 202715129
Largest both-truncatable prime in base 19 is: 211
Largest both-truncatable prime in base 20 is: 155863
Largest both-truncatable prime in base 21 is: 1283
Largest both-truncatable prime in base 22 is: 787817
Largest both-truncatable prime in base 23 is: 439
Largest both-truncatable prime in base 24 is: 109893629
Largest both-truncatable prime in base 25 is: 577
Largest both-truncatable prime in base 26 is: 4195880189
Largest both-truncatable prime in base 27 is: 1811
Largest both-truncatable prime in base 28 is: 14474071
Largest both-truncatable prime in base 29 is: 379
Largest both-truncatable prime in base 30 is: 21335388527
Largest both-truncatable prime in base 31 is: 2203
Largest both-truncatable prime in base 32 is: 1043557
Largest both-truncatable prime in base 33 is: 2939
Largest both-truncatable prime in base 34 is: 42741029
Largest both-truncatable prime in base 35 is: 2767
Largest both-truncatable prime in base 36 is: 50764713107
