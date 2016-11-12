#!/usr/bin/perl

# A messy, but interesting approximation for the nth-prime.

# Formulas from:
#   http://stackoverflow.com/a/9487883/1063770

use 5.010;
use strict;
use warnings;

use ntheory qw(nth_prime);

my $sum1 = 0;
my $sum2 = 0;

for (my $n = 1e6 ; $n < 1e7 ; $n += 1e6) {
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

    say "P($n) -> ",join(" ", sprintf("%10s" x 3, $p, $p1, $p2), "\t", sprintf("%.5f", $p / $p1), sprintf("%.5f", $p / $p2));
}

say "P1 error: $sum1";
say "P2 error: $sum2";

__END__
        29        36        29   0.80556 1.00000
  15486041  15457742  15439431   1.00183 1.00302
  32453039  32433008  32405572   1.00062 1.00146
  49979893  49975183  49941439   1.00009 1.00077
  67868153  67884333  67846000   0.99976 1.00033
  86028343  86065798  86024104   0.99956 1.00005
 104395451 104463936 104419831   0.99934 0.99977
 122950039 123042040 122996293   0.99925 0.99962
 141651127 141774052 141727310   0.99913 0.99946
 160481437 160640508 160593326   0.99901 0.99930

P1 error: 9.80416402659991
P2 error: 10.0037856546587
