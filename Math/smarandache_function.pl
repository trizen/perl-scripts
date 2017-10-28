#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 September 2016
# Website: https://github.com/trizen

# A decently efficient algorithm for computing the results of the Kempner-Smarandache function.

# See also: https://projecteuler.net/problem=549
#           https://en.wikipedia.org/wiki/Kempner_function
#           http://mathworld.wolfram.com/SmarandacheFunction.html

# ∑S(i) for 2 ≤ i ≤ 10^2 == 2012
# ∑S(i) for 2 ≤ i ≤ 10^6 == 64938007616
# ∑S(i) for 2 ≤ i ≤ 10^8 == 476001479068717

use utf8;
use 5.010;
use strict;
use warnings;

use List::Util qw(max sum);
use ntheory qw(factor_exp factorialmod is_prime);

binmode(STDOUT, ':utf8');

my %cache;

sub smarandache {
    my ($n) = @_;

    return $n if is_prime($n);

    my @f = factor_exp($n);
    my $Ω = sum(map { $_->[1] } @f);

    (@f == $Ω)
      && return $f[-1][0];

    if (@f == 1) {

        my $ϕ = $f[0][0];

        ($Ω <= $ϕ)
          && return $ϕ * $Ω;

        exists($cache{$n})
          && return $cache{$n};

        my $m = $ϕ * $Ω;

        while (factorialmod($m - $ϕ, $n) == 0) {
            $m -= $ϕ;
        }

        return ($cache{$n} = $m);
    }

    max(map { $_->[1] == 1 ? $_->[0] : smarandache($_->[0]**$_->[1]) } @f);
}

#
## Tests
#

#<<<
my @tests = (
    [40, 5],
    [72, 6],
    [1234, 617],
    [5224832089, 164],
    [688 * 2**15, 43],
    [891, 11],
    [704, 11],
);
#>>>

foreach my $test (@tests) {
    my ($n, $r) = @{$test};

    my $s = smarandache($n);

    say "S($n) = $s";

    if ($s != $r) {
        warn "\tHowever, that is incorrect! (expected: $r)";
    }
}

print "\n";

my $sum   = 0;
my $limit = 10**2;

for my $n (2 .. $limit) {
    $sum += smarandache($n);
}
say "∑S(i) for 2 ≤ i ≤ $limit == $sum";

if ($limit == 100 and $sum != 2012) {
    warn "However, that is incorrect (expected: 2012)!";
}
