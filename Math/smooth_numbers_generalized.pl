#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 06 March 2019
# https://github.com/trizen

# Generalized algorithm for generating numbers that are smooth over a set A of primes, below a given limit.

use 5.020;
use warnings;

use experimental qw(signatures);

use Math::GMPz;
use ntheory qw(:all);

sub check_valuation ($n, $p) {

    if ($p == 2) {
        return valuation($n, $p) < 5;
    }

    if ($p == 3) {
        return valuation($n, $p) < 3;
    }

    if ($p == 7) {
        return valuation($n, $p) < 3;
    }

    ($n % $p) != 0;
}

sub smooth_numbers ($limit, $primes) {

    my @h = (1);
    foreach my $p (@$primes) {

        say "Prime: $p";

        foreach my $n (@h) {
            if ($n * $p <= $limit and check_valuation($n, $p)) {
                push @h, $n * $p;
            }
        }
    }

    return \@h;
}

#
# Example for finding numbers `m` such that:
#     sigma(m) * phi(m) = n^k
# for some `n` and `k`, with `n > 1` and `k > 1`.
#
# See also: https://oeis.org/A306724
#

sub isok ($n) {
    is_power(Math::GMPz->new(divisor_sum($n)) * euler_phi($n));
}

my @smooth_primes;

foreach my $p (@{primes(4801)}) {

    if ($p == 2) {
        push @smooth_primes, $p;
        next;
    }

    my @f1 = factor($p - 1);
    my @f2 = factor($p + 1);

    if ($f1[-1] <= 7 and $f2[-1] <= 7) {
        push @smooth_primes, $p;
    }
}

my $h = smooth_numbers(10**15, \@smooth_primes);

say "\nFound: ", scalar(@$h), " terms";

my %table;

foreach my $n (@$h) {

    my $p = isok($n);

    if ($p >= 8) {
        say "a($p) = $n -> ", join(' * ', map { "$_->[0]^$_->[1]" } factor_exp($n));
        push @{$table{$p}}, $n;
    }
}

say '';

foreach my $k (sort { $a <=> $b } keys %table) {
    say "a($k) <= ", vecmin(@{$table{$k}});
}

__END__

# See: https://oeis.org/A306724

a(8) <= 498892319051
a(9) <= 14467877252479
a(10) <= 421652049419104
a(11) <= 12227909433154016
a(12) <= 377536703748630244
a(13) <= 926952707565364023467
