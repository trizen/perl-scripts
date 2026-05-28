#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 28 May 2026
# https://github.com/trizen

# A fast algorithm for finding all the non-negative integer solutions to the equation:
#   polygonal(a, k) + polygonal(b, k) = n
# for any given positive integers `n` and `k` for which such a solution exists.

use 5.036;
use Math::GMPz   qw();
use ntheory 0.74 qw(:all);

# Find a solution to x^2 + y^2 = p, for prime numbers `p` congruent to 1 mod 4.
sub primitive_sum_of_two_squares ($p) {

    if ($p == 2) {
        return (1, 1);
    }

    my $s = Math::GMPz->new(sqrtmod(-1, $p) || return);
    my $q = $p;

    while ($s * $s > $p) {
        ($s, $q) = ($q % $s, $s);
    }

    return ($s, $q % $s);
}

# Multiply two representations (a,b) and (c,d),
# return all distinct sign/ordering variations.
sub combine_pairs($A, $B, $C, $D) {

    my $AC = $A * $C;
    my $AD = $A * $D;
    my $BD = $B * $D;
    my $BC = $B * $C;

#<<<
    return (
        [$AC - $BD, $AD + $BC],
        [$AC + $BD, $AD - $BC],
    );
#>>>
}

# Multiply two *sets* of representations
sub multiply_sets($A, $B) {
    my %seen;
    my @new;
    for my $p (@$A) {
        for my $q (@$B) {
            for my $r (combine_pairs(@$p, @$q)) {
                my ($x, $y) = @$r;

                $x = -$x if ($x < 0);
                $y = -$y if ($y < 0);

                if ($x > $y) {
                    ($x, $y) = ($y, $x);
                }

                my $key = "$x,$y";
                next if $seen{$key}++;
                push @new, [$x, $y];
            }
        }
    }
    return @new;
}

sub sum_of_two_squares_solutions($n) {

    $n < 0  and return;
    $n == 0 and return [0, 0];

    my @factors = factor_exp($n);

    # Start with representation of 1
    my @reps = ([0, 1]);    # (0^2 + 1^2 = 1)

    # Handle primes p ≡ 3 (mod 4) with even exponent: they contribute as a perfect square factor s^2.
    my $square_scale = Math::GMPz->new(1);

    foreach my $pp (@factors) {
        my ($p, $k) = @$pp;

        # Handle primes 3 mod 4
        if ($p % 4 == 3) {
            if ($k % 2 != 0) {
                return;    # no solutions
            }

            $square_scale *= powint($p, $k >> 1);
            next;
        }

        # Representation of p = x^2 + y^2
        my ($x, $y) = primitive_sum_of_two_squares($p);

        # Use binary exponentiation to get representations for p^k
        my @acc   = ([0, 1]);
        my @base  = ([$x, $y]);
        my $exp_k = $k;

        while ($exp_k > 0) {
            if ($exp_k & 1) {
                @acc = multiply_sets(\@acc, \@base);
            }
            @base = multiply_sets(\@base, \@base);
            $exp_k >>= 1;
        }
        @reps = multiply_sets(\@reps, \@acc);
    }

    if ($square_scale != 1) {
        @reps = map { [$_->[0] * $square_scale, $_->[1] * $square_scale] } @reps;
    }

    # Sort final reps
    @reps = sort { $a->[0] <=> $b->[0] } @reps;

    return @reps;
}

# Generalization for sum of two k-gonal numbers
sub sum_of_two_polygonal_numbers($n, $k) {

    die "k must be >= 3" if $k < 3;

    return        if $n < 0;
    return [0, 0] if $n == 0;

    # If k == 4, we can route straight to the underlying square solver
    return sum_of_two_squares_solutions($n) if $k == 4;

    my $k_minus_2 = Math::GMPz->new($k - 2);
    my $k_minus_4 = Math::GMPz->new($k - 4);

    # Calculate N = 8 * (k - 2) * n + 2 * (k - 4)^2
    my $N = Math::GMPz->new($n);
    $N *= 8;
    $N *= $k_minus_2;
    $N += 2 * ($k_minus_4 * $k_minus_4);

    my @sq_sols = sum_of_two_squares_solutions($N);
    my @results;
    my %seen;

    my $den = 2 * $k_minus_2;

    for my $sol (@sq_sols) {
        my ($X, $Y) = @$sol;

        # Consider all ± permutations (as squaring obscures the original sign)
        my @cand_X = ($X);
        push @cand_X, -$X if $X != 0;

        my @cand_Y = ($Y);
        push @cand_Y, -$Y if $Y != 0;

        my @pairs;
        for my $cx (@cand_X) {
            for my $cy (@cand_Y) {
                push @pairs, [$cx, $cy];
                push @pairs, [$cy, $cx] if $X != $Y;
            }
        }

        # Validate which configurations map back to valid integers for x and y
        for my $pair (@pairs) {
            my ($A, $B) = @$pair;

            my $num_x = $A + $k_minus_4;
            my $num_y = $B + $k_minus_4;

            # Must divide cleanly to result in an integer root
            if ($num_x % $den == 0 && $num_y % $den == 0) {
                my $x = divint($num_x, $den);
                my $y = divint($num_y, $den);

                # We require non-negative bases for polygonal indices
                if ($x >= 0 && $y >= 0) {
                    my ($min, $max) = ($x < $y) ? ($x, $y) : ($y, $x);
                    my $key = "$min,$max";

                    if (!$seen{$key}++) {
                        push @results, [$min, $max];
                    }
                }
            }
        }
    }

    sort { ($a->[0] <=> $b->[0]) || ($a->[1] <=> $b->[1]) } @results;
}

foreach my $n (1 .. 81) {
    my $k         = 3;
    my @solutions = sum_of_two_polygonal_numbers($n, $k);
    if (@solutions) {
        say "$n = " . join(' = ', map { join(' + ', map { "P($_, $k)" } @$_) } @solutions);
    }
}

__END__
1 = P(0, 3) + P(1, 3)
2 = P(1, 3) + P(1, 3)
3 = P(0, 3) + P(2, 3)
4 = P(1, 3) + P(2, 3)
6 = P(0, 3) + P(3, 3) = P(2, 3) + P(2, 3)
7 = P(1, 3) + P(3, 3)
9 = P(2, 3) + P(3, 3)
10 = P(0, 3) + P(4, 3)
11 = P(1, 3) + P(4, 3)
12 = P(3, 3) + P(3, 3)
13 = P(2, 3) + P(4, 3)
15 = P(0, 3) + P(5, 3)
16 = P(1, 3) + P(5, 3) = P(3, 3) + P(4, 3)
18 = P(2, 3) + P(5, 3)
20 = P(4, 3) + P(4, 3)
21 = P(0, 3) + P(6, 3) = P(3, 3) + P(5, 3)
22 = P(1, 3) + P(6, 3)
24 = P(2, 3) + P(6, 3)
25 = P(4, 3) + P(5, 3)
27 = P(3, 3) + P(6, 3)
28 = P(0, 3) + P(7, 3)
29 = P(1, 3) + P(7, 3)
30 = P(5, 3) + P(5, 3)
31 = P(2, 3) + P(7, 3) = P(4, 3) + P(6, 3)
34 = P(3, 3) + P(7, 3)
36 = P(0, 3) + P(8, 3) = P(5, 3) + P(6, 3)
37 = P(1, 3) + P(8, 3)
38 = P(4, 3) + P(7, 3)
39 = P(2, 3) + P(8, 3)
42 = P(3, 3) + P(8, 3) = P(6, 3) + P(6, 3)
43 = P(5, 3) + P(7, 3)
45 = P(0, 3) + P(9, 3)
46 = P(1, 3) + P(9, 3) = P(4, 3) + P(8, 3)
48 = P(2, 3) + P(9, 3)
49 = P(6, 3) + P(7, 3)
51 = P(3, 3) + P(9, 3) = P(5, 3) + P(8, 3)
55 = P(0, 3) + P(10, 3) = P(4, 3) + P(9, 3)
56 = P(1, 3) + P(10, 3) = P(7, 3) + P(7, 3)
57 = P(6, 3) + P(8, 3)
58 = P(2, 3) + P(10, 3)
60 = P(5, 3) + P(9, 3)
61 = P(3, 3) + P(10, 3)
64 = P(7, 3) + P(8, 3)
65 = P(4, 3) + P(10, 3)
66 = P(0, 3) + P(11, 3) = P(6, 3) + P(9, 3)
67 = P(1, 3) + P(11, 3)
69 = P(2, 3) + P(11, 3)
70 = P(5, 3) + P(10, 3)
72 = P(3, 3) + P(11, 3) = P(8, 3) + P(8, 3)
73 = P(7, 3) + P(9, 3)
76 = P(4, 3) + P(11, 3) = P(6, 3) + P(10, 3)
78 = P(0, 3) + P(12, 3)
79 = P(1, 3) + P(12, 3)
81 = P(2, 3) + P(12, 3) = P(5, 3) + P(11, 3) = P(8, 3) + P(9, 3)
