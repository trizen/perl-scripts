#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 April 2026
# https://github.com/trizen

# Generate all the k-omega numbers in range [A,B] that have a given prime signature.

use 5.036;
use ntheory 0.74 qw(:all);

sub rootint_ceil($n, $k) {
    return rootint($n, $k) + (is_power($n, $k) ? 0 : 1);
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

    @list = sort { $a <=> $b } @list;

    return @list;
}

# Example
my $prime_signature = [3, 2, 2];
my $A               = 2000;
my $B               = 10000;

my @arr = prime_signature_numbers_in_range($A, $B, $prime_signature);
say "Generated: @arr";

my @bf = grep {
    join(' ', prime_signature($_)) eq join(' ', sort { $b <=> $a } @$prime_signature)
} vecmax(pn_primorial(scalar(@$prime_signature)), $A) .. $B;

"@arr" eq "@bf" or die "Mismatch detected!";
