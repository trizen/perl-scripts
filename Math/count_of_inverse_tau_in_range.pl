#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 May 2026
# https://github.com/trizen

# Count the numbers in a given range [A,B] that have exactly `n` divisors.

use 5.036;
use ntheory 0.74 qw(:all);

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

sub count_prime_signature_numbers($n, $prime_signature) {

    my $k = scalar(@$prime_signature);

    if ($k == 0) {
        return 1 if (1 <= $n);
        return 0;
    }

    $n >= 1 || return 0;

    my $count = 0;

    my $generate = sub ($m, $lo, $k, $P, $sum_e, $j = 0) {

        my $e  = $P->[$k - 1];
        my $hi = rootint(divint($n, $m), $sum_e);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {
            $count += prime_count($hi) - $j;
            return;
        }

        if ($k == 2) {
            my $e2 = $P->[0];
            foreach my $p (@{primes($lo, $hi)}) {
                my $t = mulint($m, powint($p, $e));
                my $u = rootint(divint($n, $t), $e2);
                $count += prime_count($u) - ++$j;
            }
            return;
        }

        for (my $p = $lo ; $p <= $hi ;) {
            my $t = mulint($m, powint($p, $e));
            my $r = next_prime($p);
            __SUB__->($t, $r, $k - 1, $P, $sum_e - $e, ++$j);
            $p = $r;
        }
    };

    my $sum_e = vecsum(@$prime_signature) || return 0;

    if ($sum_e > logint($n, 2)) {
        return 0;
    }

    unique_permutations(
        $prime_signature,
        sub ($perm) {
            $generate->(1, 2, scalar(@$perm), $perm, $sum_e);
        }
    );

    return $count;
}

sub count_prime_signature_numbers_in_range($A, $B, $signature) {
    my $term_1 = count_prime_signature_numbers($A - 1, $signature);
    my $term_2 = count_prime_signature_numbers($B,     $signature);
    $term_2 - $term_1;
}

sub multiplicative_partitions($n, $max_value = $n) {

    my @results;
    my @divs = divisors($n);

    shift(@divs);    # remove divisor '1'

    my $end = $#divs;
    sub ($target, $min_idx, $path) {

        if ($target == 1) {
            push @results, $path;
            return;
        }

        for my $i ($min_idx .. $end) {
            my $d = $divs[$i];

            # Prune branch if the divisor exceeds the remaining target
            last if $d > $target;
            last if $d > $max_value;

            if ($target % $d == 0) {
                __SUB__->(divint($target, $d), $i, [@$path, $d]);
            }
        }
    }->($n, 0, []);

    return @results;
}

sub count_inverse_tau($A, $B, $n) {

    my @signatures = map {
        [map { $_ - 1 } @$_]
    } multiplicative_partitions($n, logint($B, 2) + 1);

    my @counts;
    foreach my $sig (@signatures) {
        push @counts, count_prime_signature_numbers_in_range($A, $B, $sig);
    }

    vecsum(@counts);
}

count_inverse_tau(1, 462, 16) == 16 or die "error";
count_inverse_tau(1,   powint(2, 9),  10) == 13    or die "error";
count_inverse_tau(1,   powint(2, 40), 5040) == 103 or die "error";
count_inverse_tau(1e5, 1e5 + 500, 48) == 10 or die "error";
count_inverse_tau(100050, 100500, 48) == 10 or die "error";

# Number of k <= 2^(n-1) such that tau(k) = n
# https://oeis.org/A393179
foreach my $n (1 .. 32) {
    say "a($n) = ", count_inverse_tau(1, powint(2, $n - 1), $n);
}
