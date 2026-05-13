#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 May 2026
# https://github.com/trizen

# Generate all the numbers in a given range [A,B] that have exactly `n` divisors.

use 5.036;
use ntheory 0.74 qw(:all);

sub rootint_ceil($n, $k) {
    rootint($n, $k) + (is_power($n, $k) ? 0 : 1);
}

sub unique_permutations($array, $callback) {
    sub ($items, $current_perm) {

        if (!@$items) {
            $callback->($current_perm);
            return;
        }

        my %level_seen;
        for my $i (0 .. $#$items) {
            my $item = $items->[$i];

            # Skip iterations for duplicate elements in the same level
            next if $level_seen{$item}++;

            my @new_items = @$items;
            splice(@new_items, $i, 1);

            my @new_perm = (@$current_perm, $item);
            __SUB__->(\@new_items, \@new_perm);
        }
    }->($array, []);
}

sub prime_signature_numbers_in_range($A, $B, $prime_signature) {

    my @list;
    my $k = scalar(@$prime_signature);

    if ($k == 0) {
        push(@list, 1) if ($A <= 1 and 1 <= $B);
        return @list;
    }

    # The smallest possible number with k distinct prime factors
    $A = vecmax(pn_primorial($k), $A);

    my $generate = sub ($m, $lo, $k, $P, $sum_e) {

        my $e  = $P->[$k - 1];
        my $hi = rootint(divint($B, $m), $sum_e);

        if ($lo > $hi) {
            return;
        }

        # Base case
        if ($k == 1) {

            # Tighten the lower bound based on A
            my $lo_tight = vecmax($lo, rootint_ceil(cdivint($A, $m), $e));

            foreach my $p (@{primes($lo_tight, $hi)}) {
                push @list, mulint($m, powint($p, $e));
            }

            return;
        }

        for (my $p = $lo ; $p <= $hi ;) {
            my $t = mulint($m, powint($p, $e));
            my $r = next_prime($p);
            __SUB__->($t, $r, $k - 1, $P, $sum_e - $e);
            $p = $r;
        }
    };

    my $sum_e = vecsum(@$prime_signature);

    unique_permutations(
        $prime_signature,
        sub ($perm) {
            $generate->(1, 2, scalar(@$perm), $perm, $sum_e);
        }
    );

    return @list;
}

sub multiplicative_partitions($n) {

    my @results;

    sub ($target, $min_factor, $path) {

        for my $d (divisors($target)) {

            next if $d < $min_factor;
            my $quotient = divint($target, $d);

            if ($quotient == 1) {
                push @results, [sort { $a <=> $b } (@$path, $d)];
            }
            elsif ($quotient >= $d) {
                __SUB__->($quotient, $d, [@$path, $d]);
            }
        }
      }
      ->($n, 2, []);

    @results = sort { scalar(@$a) <=> scalar(@$b) } @results;

    return @results;
}

sub inverse_tau($A, $B, $n) {

    my @signatures = map {
        [map { $_ - 1 } @$_]
    } multiplicative_partitions($n);

    my @list;
    foreach my $sig (@signatures) {
        push @list, prime_signature_numbers_in_range($A, $B, $sig);
    }

    @list = sort { $a <=> $b } @list;

    return @list;
}

my @arr = inverse_tau(1e5, 1e5 + 500, 48);
say "@arr";    #=> 100050 100128 100152 100200 100254 100296 100380 100386 100485 100500
