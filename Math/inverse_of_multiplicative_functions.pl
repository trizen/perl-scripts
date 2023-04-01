#!/usr/bin/perl

# Computing the inverse of some multiplicative functions.
# Translation of invphi.gp ver. 2.1 by Max Alekseyev.

# See also:
#   https://home.gwu.edu/~maxal/gpscripts/

use utf8;
use 5.020;
use strict;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);

sub dynamicPreimage ($N, $L, %opt) {

    my %r = (1 => [1]);

    foreach my $l (@$L) {
        my %t;

        foreach my $pair (@$l) {
            my ($x, $y) = @$pair;

            foreach my $d (divisors(divint($N, $x))) {
                if (exists $r{$d}) {
                    my @list = @{$r{$d}};
                    if ($opt{unitary}) {
                        @list = grep { gcd($_, $y) == 1 } @list;
                    }
                    push @{$t{mulint($x, $d)}}, map { mulint($_, $y) } @list;
                }
            }
        }
        while (my ($k, $v) = each %t) {
            push @{$r{$k}}, @$v;
        }
    }

    return if !exists $r{$N};
    sort { $a <=> $b } @{$r{$N}};
}

sub dynamicLen ($N, $L) {

    my %r = (1 => 1);

    foreach my $l (@$L) {
        my %t;

        foreach my $pair (@$l) {
            my ($x, $y) = @$pair;

            foreach my $d (divisors(divint($N, $x))) {
                if (exists $r{$d}) {
                    $t{mulint($x, $d)} += $r{$d};
                }
            }
        }
        while (my ($k, $v) = each %t) {
            $r{$k} += $v;
        }
    }

    $r{$N} // 0;
}

sub dynamicMin ($N, $L) {

    my %r = (1 => 1);

    foreach my $l (@$L) {
        my %t;

        foreach my $pair (@$l) {
            my ($x, $y) = @$pair;

            foreach my $d (divisors(divint($N, $x))) {
                if (exists $r{$d}) {

                    my $k = mulint($x, $d);
                    my $v = $r{$d} * $y;

                    if (not defined($t{$k})) {
                        $t{$k} = $v;
                    }
                    else {
                        $t{$k} = $v if ($v < $t{$k});
                    }
                }
            }
        }
        while (my ($k, $v) = each %t) {
            if (not defined($r{$k})) {
                $r{$k} = $v;
            }
            else {
                $r{$k} = $v if ($v < $r{$k});
            }
        }
    }

    $r{$N};
}

sub dynamicMax ($N, $L) {

    my %r = (1 => 1);

    foreach my $l (@$L) {
        my %t;

        foreach my $pair (@$l) {
            my ($x, $y) = @$pair;

            foreach my $d (divisors(divint($N, $x))) {
                if (exists $r{$d}) {

                    my $k = mulint($x, $d);
                    my $v = $r{$d} * $y;

                    if (not defined($t{$k})) {
                        $t{$k} = $v;
                    }
                    else {
                        $t{$k} = $v if ($v > $t{$k});
                    }
                }
            }
        }
        while (my ($k, $v) = each %t) {
            if (not defined($r{$k})) {
                $r{$k} = $v;
            }
            else {
                $r{$k} = $v if ($v > $r{$k});
            }
        }
    }

    $r{$N};
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

sub cook_phi ($N) {
    my %L;

    foreach my $d (divisors($N)) {

        my $p = addint($d, 1);

        is_prime($p) || next;

        my $v = valuation($N, $p);

        push @{$L{$p}}, map { [mulint($d, powint($p, $_ - 1)), powint($p, $_)] } 1 .. $v + 1;
    }

    [values %L];
}

sub cook_psi ($N) {
    my %L;

    foreach my $d (divisors($N)) {

        my $p = subint($d, 1);

        is_prime($p) || next;

        my $v = valuation($N, $p);

        push @{$L{$p}}, map { [mulint($d, powint($p, $_ - 1)), powint($p, $_)] } 1 .. $v + 1;
    }

    [values %L];
}

sub cook_usigma ($N) {
    my @list;
    foreach my $d (divisors($N)) {
        if (is_prime_power(subint($d, 1))) {
            push @list, [[$d, subint($d, 1)]];
        }
    }
    return \@list;
}

sub cook_uphi ($N) {
    my @list;
    foreach my $d (divisors($N)) {
        if (is_prime_power(addint($d, 1))) {
            push @list, [[$d, addint($d, 1)]];
        }
    }
    return \@list;
}

# Inverse of sigma function

sub inverse_sigma ($N, $k = 1) {
    dynamicPreimage($N, cook_sigma($N, $k));
}

sub inverse_sigma_min ($N, $k = 1) {
    dynamicMin($N, cook_sigma($N, $k));
}

sub inverse_sigma_max ($N, $k = 1) {
    dynamicMax($N, cook_sigma($N, $k));
}

sub inverse_sigma_len ($N, $k = 1) {
    dynamicLen($N, cook_sigma($N, $k));
}

# Inverse of Euler phi function

sub inverse_phi ($N) {
    dynamicPreimage($N, cook_phi($N));
}

sub inverse_phi_min ($N) {
    dynamicMin($N, cook_phi($N));
}

sub inverse_phi_max ($N) {
    dynamicMax($N, cook_phi($N));
}

sub inverse_phi_len ($N) {
    dynamicLen($N, cook_phi($N));
}

# Inverse of Dedekind psi function

sub inverse_psi ($N) {
    dynamicPreimage($N, cook_psi($N));
}

sub inverse_psi_min ($N) {
    dynamicMin($N, cook_psi($N));
}

sub inverse_psi_max ($N) {
    dynamicMax($N, cook_psi($N));
}

sub inverse_psi_len ($N) {
    dynamicLen($N, cook_psi($N));
}

# Inverse of unitary sigma function

sub inverse_usigma ($N) {
    dynamicPreimage($N, cook_usigma($N), unitary => 1);
}

# Inverse of unitary phi function

sub inverse_uphi ($N) {
    dynamicPreimage($N, cook_uphi($N), unitary => 1);
}

## Usage example

say join ', ', inverse_sigma(120);    #=> [54, 56, 87, 95]
say join ', ', inverse_usigma(120);   #=> [60, 87, 92, 95, 99]
say join ', ', inverse_uphi(120);     #=> [121, 143, 144, 155, 164, 183, 220, 231, 240, 242, 286, 310, 366, 462]
say join ', ', inverse_phi(120);      #=> [143, 155, 175, 183, 225, 231, 244, 248, 286, 308, 310, 350, 366, 372, 396, 450, 462]
say join ', ', inverse_psi(120);      #=> [75, 76, 87, 95]
say join ', ', inverse_sigma(22100, 2);    #=> [120, 130, 141]

say '';

say inverse_sigma_min(factorial(10));      #=> 876960
say inverse_sigma_max(factorial(10));      #=> 3624941
say inverse_sigma_len(factorial(10));      #=> 1195

say '';

say inverse_phi_min(factorial(10));        #=> 3632617
say inverse_phi_max(factorial(10));        #=> 19969950
say inverse_phi_len(factorial(10));        #=> 3802

say '';

say inverse_psi_min(factorial(10));        #=> 1160250
say inverse_psi_max(factorial(10));        #=> 3624941
say inverse_psi_len(factorial(10));        #=> 1793

say '';
