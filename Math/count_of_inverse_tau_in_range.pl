#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 May 2026
# https://github.com/trizen

# Count the numbers in a given range [A,B] that have exactly `n` divisors.

use 5.036;
use ntheory 0.74 qw(:all);

prime_precalc(1e7);

sub count_prime_signature_numbers($n, $prime_signature) {

    my $k = scalar(@$prime_signature);

    if ($k == 0) {
        return 1 if (1 <= $n);
        return 0;
    }

    $n >= 1 || return 0;

    my $sum_e = vecsum(@$prime_signature) || return 0;

    if ($sum_e > logint($n, 2)) {
        return 0;
    }

    my $count      = 0;
    my @sorted_sig = sort { $b <=> $a } @$prime_signature;

    sub ($m, $lo, $rem_sig, $rem_sum, $j = 0) {

        my $k  = scalar(@$rem_sig);
        my $hi = rootint(divint($n, $m), $rem_sum);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {
            $count = addint($count, prime_count($hi) - $j);
            return;
        }

        my @seen;
        for my $i (0 .. $#$rem_sig) {

            my $e = $rem_sig->[$i];
            next if $seen[$e]++;

            my $local_j = $j;
            my @new_sig = @$rem_sig;
            splice(@new_sig, $i, 1);

            if ($k == 2) {
                my $e2 = $new_sig[0];
                forprimes {
                    my $t = mulint($m, powint($_, $e));
                    my $u = rootint(divint($n, $t), $e2);
                    $count = addint($count, prime_count($u) - ++$local_j);
                } $lo, $hi;
            }
            else {
                my $new_sum = $rem_sum - $e;
                for (my $p = $lo ; $p <= $hi ;) {
                    my $t = mulint($m, powint($p, $e));
                    my $r = next_prime($p);
                    __SUB__->($t, $r, \@new_sig, $new_sum, ++$local_j);
                    $p = $r;
                }
            }
        }
    }->(1, 2, \@sorted_sig, $sum_e);

    return $count;
}

sub count_prime_signature_numbers_in_range($A, $B, $signature) {
    my $term_1 = count_prime_signature_numbers($A - 1, $signature);
    my $term_2 = count_prime_signature_numbers($B,     $signature);
    subint($term_2, $term_1);
}

sub multiplicative_partitions($n, $max_sum_e) {

    my @results;
    my @divs = divisors($n);

    shift(@divs);    # remove divisor '1'

    my $end = $#divs;
    my @path;

    sub ($target, $min_idx, $curr_sum_e) {

        if ($target == 1) {
            push @results, [@path];
            return;
        }

        for my $i ($min_idx .. $end) {
            my $d = $divs[$i];
            my $e = $d - 1;

            last if $d > $target;
            last if ($curr_sum_e + $e > $max_sum_e);

            if ($target % $d == 0) {
                push @path, $d;
                __SUB__->(divint($target, $d), $i, $curr_sum_e + $e);
                pop @path;
            }
        }
    }->($n, 0, 0);

    return @results;
}

sub count_inverse_tau($A, $B, $n) {

    my @signatures = map {
        [map { $_ - 1 } @$_]
    } multiplicative_partitions($n, logint($B, 2));

    my @counts;
    foreach my $sig (@signatures) {
        push @counts, count_prime_signature_numbers_in_range($A, $B, $sig);
    }

    vecsum(@counts);
}

count_inverse_tau(1,      462,           16) == 16    or die "error";
count_inverse_tau(1,      powint(2, 9),  10) == 13    or die "error";
count_inverse_tau(1,      powint(2, 40), 5040) == 103 or die "error";
count_inverse_tau(1e5,    1e5 + 500,     48) == 10    or die "error";
count_inverse_tau(100050, 100500,        48) == 10    or die "error";

# Number of k <= 2^(n-1) such that tau(k) = n
# https://oeis.org/A393179
foreach my $n (1 .. 32) {
    say "a($n) = ", count_inverse_tau(1, powint(2, $n - 1), $n);
}
