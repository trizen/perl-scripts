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

sub prime_signature_numbers_in_range($A, $B, $prime_signature) {

    my @list;
    my $k = scalar(@$prime_signature);

    if ($k == 0) {
        push(@list, 1) if ($A <= 1 and 1 <= $B);
        return @list;
    }

    # The smallest possible number with k distinct prime factors
    $A = vecmax(pn_primorial($k), $A);

    my $sum_e = vecsum(@$prime_signature) || return;

    if ($sum_e > logint($B, 2)) {
        return;
    }

    my @sorted_sig = sort { $b <=> $a } @$prime_signature;

    sub ($m, $lo, $rem_sig, $rem_sum) {

        my $k  = scalar(@$rem_sig);
        my $hi = rootint(divint($B, $m), $rem_sum);

        if ($lo > $hi) {
            return;
        }

        my @seen;
        for my $i (0 .. $#$rem_sig) {
            my $e = $rem_sig->[$i];

            next if $seen[$e]++;

            my @new_sig = @$rem_sig;
            splice(@new_sig, $i, 1);

            if ($k == 1) {
                my $lo_tight = vecmax($lo, rootint_ceil(cdivint($A, $m), $e));

                forprimes {
                    push @list, mulint($m, powint($_, $e));
                } $lo_tight, $hi;
            }
            else {
                my $new_sum = $rem_sum - $e;
                for (my $p = $lo ; $p <= $hi ;) {
                    my $t = mulint($m, powint($p, $e));
                    my $r = next_prime($p);
                    __SUB__->($t, $r, \@new_sig, $new_sum);
                    $p = $r;
                }
            }
        }
    }->(1, 2, \@sorted_sig, $sum_e);

    return @list;
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

sub inverse_tau($A, $B, $n) {

    my @signatures = map {
        [map { $_ - 1 } @$_]
    } multiplicative_partitions($n, logint($B, 2));

    my @list;
    foreach my $sig (@signatures) {
        push @list, prime_signature_numbers_in_range($A, $B, $sig);
    }

    @list = sort { $a <=> $b } @list;

    return @list;
}

scalar(inverse_tau(1, 462, 16)) == 16 or die "error";
scalar(inverse_tau(1, powint(2, 9),  10)) == 13    or die "error";
scalar(inverse_tau(1, powint(2, 40), 5040)) == 103 or die "error";

my @arr = inverse_tau(1e5, 1e5 + 500, 48);
say "@arr";    #=> 100050 100128 100152 100200 100254 100296 100380 100386 100485 100500
