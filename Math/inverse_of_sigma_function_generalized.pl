#!/usr/bin/perl

# Computing the inverse of the sigma_k(n) function, for any k >= 1.
# Translation of invphi.gp ver. 2.1 by Max Alekseyev.

# See also:
#   https://home.gwu.edu/~maxal/gpscripts/

use utf8;
use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub dynamicPreimage ($N, $L) {

    my %r = (1 => [1]);

    foreach my $l (@$L) {
        my %t;

        foreach my $pair (@$l) {
            my ($x, $y) = @$pair;

            foreach my $d (divisors(divint($N, $x))) {
                if (exists $r{$d}) {
                    push @{$t{mulint($x, $d)}}, map { mulint($_, $y) } @{$r{$d}};
                }
            }
        }
        while (my ($k, $v) = each %t) {
            push @{$r{$k}}, @$v;
        }
    }

    return if not exists $r{$N};
    sort { $a <=> $b } @{$r{$N}};
}

sub cook_sigma ($N, $k) {
    my %L;

    foreach my $d (divisors($N)) {

        next if ($d == 1);

        foreach my $p (map { $_->[0] } factor_exp(subint($d, 1))) {

            my $q = addint(mulint($d, subint(powint($p, $k), 1)), 1);
            my $t = valuation($q, $p);

            next if ($t <= $k or ($t % $k) or $q != powint($p, $t));

            push @{$L{$p}}, [$d, powint($p, subint(divint($t, $k), 1))];
        }
    }

    [values %L];
}

sub inverse_sigma ($N, $k = 1) {
    dynamicPreimage($N, cook_sigma($N, $k));
}

say join ', ', inverse_sigma(120);         #=> [54, 56, 87, 95]
say join ', ', inverse_sigma(22100, 2);    #=> [120, 130, 141]
