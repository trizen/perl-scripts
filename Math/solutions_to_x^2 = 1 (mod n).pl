#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 03 October 2017
# https://github.com/trizen

# Find all the positive solutions to the quadratic congruence: x^2 = 1 (mod n), where `n` is known.

# See also:
#   https://projecteuler.net/problem=451
#   https://en.wikipedia.org/wiki/Quadratic_residue

use 5.010;
use strict;
use warnings;

use Test::More;

use Set::Product::XS qw(product);
use ntheory qw(factor_exp chinese);

plan tests => 8;

sub solve_quadratic_congruence {
    my ($n) = @_;

    my %table;
    foreach my $f (factor_exp($n)) {
        my $pp = $f->[0]**$f->[1];

        if ($pp == 2) {
            push(@{$table{$pp}}, [1, $pp]);
        }
        elsif ($pp == 4) {
            push(@{$table{$pp}}, [1, $pp], [3, $pp]);
        }
        elsif ($pp % 2 == 0) {    # 2^k, where k >= 3
            push(@{$table{$pp}},
                [$pp / 2 - 1, $pp], [$pp - 1, $pp],
                [$pp / 2 + 1, $pp], [$pp + 1, $pp]);
        }
        else {                    # odd prime power
            push(@{$table{$pp}}, [1, $pp], [$pp - 1, $pp]);
        }
    }

    my @solutions;

    product {
        push @solutions, chinese(@_);
    } values %table;

    return sort { $a <=> $b } @solutions;
}

is(join(' ', solve_quadratic_congruence(15)),   '1 4 11 14');
is(join(' ', solve_quadratic_congruence(77)),   '1 34 43 76');
is(join(' ', solve_quadratic_congruence(100)),  '1 49 51 99');
is(join(' ', solve_quadratic_congruence(175)),  '1 76 99 174');
is(join(' ', solve_quadratic_congruence(266)),  '1 113 153 265');
is(join(' ', solve_quadratic_congruence(299)),  '1 116 183 298');
is(join(' ', solve_quadratic_congruence(48)),   '1 7 17 23 25 31 41 47');
is(join(' ', solve_quadratic_congruence(1800)), '1 199 251 449 451 649 701 899 901 1099 1151 1349 1351 1549 1601 1799');

say "Solutions to x^2 = 1 (mod 5040): {", join(', ', solve_quadratic_congruence(5040)), '}';

__END__
Solutions to x^2 = 1 (mod 5040): {1, 71, 449, 559, 631, 881, 1009, 1079, 1441, 1511, 1639, 1889, 1961, 2071, 2449, 2519, 2521, 2591, 2969, 3079, 3151, 3401, 3529, 3599, 3961, 4031, 4159, 4409, 4481, 4591, 4969, 5039}
