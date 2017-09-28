#!/usr/bin/perl

# Given a number `n`, the algorithm finds all the numbers such that for each number `k` in the list, φ(k) = n.

use utf8;
use 5.010;
use strict;
use warnings;

use ntheory qw(is_prime divisors valuation);

binmode(STDOUT, ':utf8');

# Based on Dana Jacobsen's code from Math::Prime::Util,
# which in turn is based on invphi.gp v1.3 by Max Alekseyev.

# See also:
#   https://projecteuler.net/problem=248
#   https://en.wikipedia.org/wiki/Euler%27s_totient_function
#   https://github.com/danaj/Math-Prime-Util/blob/master/examples/inverse_totient.pl

sub inverse_euler_phi {
    my ($n) = @_;

    my %r = (1 => [1]);

    foreach my $d (divisors($n)) {
        if (is_prime($d + 1)) {

            my %temp;
            foreach my $k (1 .. (valuation($n, $d + 1) + 1)) {

                my $u = $d * ($d + 1)**($k - 1);
                my $v = ($d + 1)**$k;

                foreach my $f (divisors($n / $u)) {
                    if (exists $r{$f}) {
                        push @{$temp{$f * $u}}, map { $v * $_ } @{$r{$f}};
                    }
                }
            }

            while (my ($i, $v) = each(%temp)) {
                push @{$r{$i}}, @$v;
            }
        }
    }

    return if not exists $r{$n};
    return sort { $a <=> $b } @{$r{$n}};
}

foreach my $n(1..70) {
    if (my @inv = inverse_euler_phi($n)) {
        say "φ−¹($n) = [", join(', ', @inv), "]";
    }
}
