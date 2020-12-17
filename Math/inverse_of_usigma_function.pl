#!/usr/bin/perl

# Given a positive integer `n`, this algorithm finds all the numbers k
# such that usigma(k) = n, where `usigma(k)` is the sum of the unitary divisors of `k`.

# usigma(n) is multiplicative with usigma(p^k) = p^k + 1.

# See also:
#   https://oeis.org/A034448 -- usigma(n)
#   https://home.gwu.edu/~maxal/gpscripts/

use utf8;
use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use List::Util qw(uniq);
use experimental qw(signatures);

sub inverse_usigma ($n) {

    my %r = (1 => [1]);

    foreach my $d (divisors($n)) {

        my $D = subint($d, 1);
        is_prime_power($D) || next;

        my %temp;
        foreach my $k (1 .. valuation($n, $D) + 1) {

            my $v = powint($D, $k);
            my $u = addint($v, 1);

            modint($n, $u) == 0 or next;

            foreach my $f (divisors(divint($n, $u))) {
                if (exists $r{$f}) {
                    push @{$temp{mulint($f, $u)}}, map { mulint($v, $_) }
                      grep { gcd($v, $_) == 1 } @{$r{$f}};
                }
            }
        }

        while (my ($i, $v) = each(%temp)) {
            push @{$r{$i}}, @$v;
        }
    }

    return if not exists $r{$n};
    return sort { $a <=> $b } uniq(@{$r{$n}});
}

my $n = 186960;

say "Solutions for usigma(x) = $n: ", join(' ', inverse_usigma($n));

__END__
Solutions for usigma(x) = 186960: 90798 108558 109046 113886 116835 120620 123518 123554 130844 131868 136419 138651 145484 148004 153495 155795 163503 163583 165771 166463 173907 174899 176823 179147 182003 185579 186089 186959
