#!?usr/bin/perl

# An messy, but interesting approximation for the nth-prime.

# Formulas from:
#   http://stackoverflow.com/a/9487883/1063770

use 5.010;
use strict;
use warnings;

use ntheory qw(nth_prime);

my $sum1 = 0;
my $sum2 = 0;
my $sum3 = 0;
for (my $n = 3 ; $n <= 1e6 ; $n += 1000) {
    my $p = nth_prime($n);

    # more than good approximation (experimental)
    my $p1 = int(
         1 / 2 * (
             3 - (8 + log(2.3)) * $n - $n**2 + 1 / 2 * (
                            -1 + abs(
                                -(1 / 2) + $n + sqrt(
                                    log(log($n) / log(2)) *
                                      (-log(log(2)) + log(log($n)) + (8 * log(3) * log(($n * log(8 * $n)) / log($n))) / log(2))
                                  ) / (2 * log(log(($n * log(8 * $n)) / log($n)) / log(2)))
                              ) + abs(log($n) / log(3) + log(log(($n * log(8 * $n)) / log($n)) / log(2)) / log(2))
               ) * (
                 2 * abs(log(($n * log(8 * $n)) / log($n)) / log(3) + log(log(($n * log(8 * $n)) / log($n)) / log(2)) / log(2))
                   + abs(
                         1 / log(log($n) / log(2)) * (
                                 log(log(3)) - log(log($n)) + 2 * $n * log(log($n) / log(2)) + sqrt(
                                     ((8 * log(3) * log($n)) / log(2) - log(log(2)) + log(log(($n * log(8 * $n)) / log($n)))) *
                                       log(log(($n * log(8 * $n)) / log($n)) / log(2))
                                 )
                         )
                        )
                   )
                 )
                );

    # good approximation
    my $p2 = int(
                 1 / 2 * (
                     8 - 8.7 * $n - $n**2 + 1 / 2 * (
                         2 * abs(log($n) / log(3) + log(log($n) / log(2)) / log(2)) + abs(
                             (
                              log(log(3)) -
                                log(log($n)) +
                                2 * $n * log(log($n) / log(2)) +
                                sqrt(((8 * log(3) * log($n)) / log(2) - log(log(2)) + log(log($n))) * log(log($n) / log(2)))
                             ) / log(log($n) / log(2))
                         )
                       ) * (
                           -1 + abs(log($n) / log(3) + log(log($n) / log(2)) / log(2)) + abs(
                               -(1 / 2) +
                                 $n +
                                 sqrt(((8 * log(3) * log($n)) / log(2) - log(log(2)) + log(log($n))) * log(log($n) / log(2))) /
                                 (2 * log(log($n) / log(2)))
                           )
                       )
                 )
                );

    $sum1 += $p / $p1;
    $sum2 += $p / $p2;

    say join(" ", sprintf("%10s" x 3, $p, $p1, $p2), "\t", sprintf("%.5f", $p / $p1), sprintf("%.5f", $p / $p2));
}

say "P1 error: $sum1";
say "P2 error: $sum2";
