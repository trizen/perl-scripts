#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 March 2020
# https://github.com/trizen

# Count the number of B-smooth numbers below a given limit, where each number has at least k distinct prime factors.

# Problem inspired by:
#   https://projecteuler.net/problem=268

# See also:
#   https://en.wikipedia.org/wiki/Smooth_number

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub smooth_numbers ($initial, $limit, $primes) {

    my @h = ($initial);

    foreach my $p (@$primes) {
        foreach my $n (@h) {
            if ($n * $p <= $limit) {
                push @h, $n * $p;
            }
        }
    }

    return \@h;
}

my $PRIME_MAX = 100;    # the prime factors must all be <= this value
my $LEAST_K   = 4;      # each number must have at least this many distinct prime factors

sub count_smooth_numbers ($limit) {

    my $count  = 0;
    my @primes = @{primes($PRIME_MAX)};

    forcomb {

        my $c = [@primes[@_]];
        my $v = vecprod(@$c);

        if ($v <= $limit) {

            my $h = smooth_numbers($v, $limit, $c);

            foreach my $n (@$h) {
                my $new_h = smooth_numbers(1, divint($limit, $n), [grep { $_ < $c->[0] } @primes]);
                $count += scalar @$new_h;
            }
        }

    } scalar(@primes), $LEAST_K;

    return $count;
}

say "\n# Count of $PRIME_MAX-smooth numbers with at least $LEAST_K distinct prime factors:\n";

foreach my $n (1 .. 16) {
    my $count = count_smooth_numbers(powint(10, $n));
    say "C(10^$n) = $count";
}

__END__

# Count of 100-smooth numbers with at least 4 distinct prime factors:

C(10^1)  = 0
C(10^2)  = 0
C(10^3)  = 23
C(10^4)  = 811
C(10^5)  = 8963
C(10^6)  = 53808
C(10^7)  = 235362
C(10^8)  = 866945
C(10^9)  = 2855050
C(10^10) = 8668733
C(10^11) = 24692618
C(10^12) = 66682074
C(10^13) = 171957884
C(10^14) = 425693882
C(10^15) = 1015820003
C(10^16) = 2344465914
