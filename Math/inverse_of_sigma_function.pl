#!/usr/bin/perl

# Given a positive integer `n`, this algorithm finds all the numbers k
# such that sigma(k) = n, where `sigma(k)` is the sum of divisors of `k`.

# Based on "invphi.gp" code by Max Alekseyev.

# See also:
#   https://home.gwu.edu/~maxal/gpscripts/

use utf8;
use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);
use List::Util qw(uniq);
#use Math::AnyNum qw(:overload);

binmode(STDOUT, ':utf8');

sub inverse_sigma ($n, $m = 3) {

    return (1) if ($n == 1);

    my @R;
    foreach my $d (grep { $_ >= $m } divisors($n)) {
        foreach my $p (map { $_->[0] } factor_exp($d - 1)) {
            my $P = $d * ($p - 1) + 1;
            my $k = valuation($P, $p) - 1;
            next if (($k < 1) || ($P != $p**($k + 1)));
            push @R, map { $_ * $p**$k } grep { $_ % $p != 0; } __SUB__->($n/$d, $d);
        }
    }

    sort { $a <=> $b } uniq(@R);
}

foreach my $n (1 .. 70) {
    (my @inv = inverse_sigma($n)) || next;
    say "σ−¹($n) = [", join(', ', @inv), ']';
}

__END__
σ−¹(1) = [1]
σ−¹(3) = [2]
σ−¹(4) = [3]
σ−¹(6) = [5]
σ−¹(7) = [4]
σ−¹(8) = [7]
σ−¹(12) = [6, 11]
σ−¹(13) = [9]
σ−¹(14) = [13]
σ−¹(15) = [8]
σ−¹(18) = [10, 17]
σ−¹(20) = [19]
σ−¹(24) = [14, 15, 23]
σ−¹(28) = [12]
σ−¹(30) = [29]
σ−¹(31) = [16, 25]
σ−¹(32) = [21, 31]
σ−¹(36) = [22]
σ−¹(38) = [37]
σ−¹(39) = [18]
σ−¹(40) = [27]
σ−¹(42) = [26, 20, 41]
σ−¹(44) = [43]
σ−¹(48) = [33, 35, 47]
