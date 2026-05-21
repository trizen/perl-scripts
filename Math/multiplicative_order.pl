#!/usr/bin/env perl

use 5.036;
use strict;
use warnings;

use Math::Prime::Util      qw(factor_exp forprimes);
use Math::Prime::Util::GMP qw(:all);

# Multiplicative order mod prime p (p odd prime, gcd(a,p)=1)
sub ord_mod_prime {
    my ($a, $p) = @_;

    my $phi = subint($p, 1);
    my $ord = $phi;

    # Reduce ord by prime factors of phi
    for my $f (factor_exp($phi)) {
        my ($q, $e) = @$f;
        for (1 .. $e) {
            last if modint($ord, $q) ne '0';
            my $cand = divint($ord, $q);
            if (powmod($a, $cand, $p) eq '1') {
                $ord = $cand;
            }
            else {
                last;
            }
        }
    }

    return $ord;
}

# Multiplicative order mod p^e for odd prime p, using LTE
sub ord_mod_odd_prime_power {
    my ($a, $p, $e) = @_;

    my $t = ord_mod_prime($a, $p);

    # Compute s = v_p(a^t - 1), but only up to e is needed.
    my $mod = powint($p, $e);
    my $x   = powmod($a, $t, $mod);
    my $s   = ($x == 1) ? $e : valuation(subint($x, 1), $p);

    my $k = ($e > $s) ? ($e - $s) : 0;
    return mulint($t, powint($p, $k));
}

# Multiplicative order mod 2^e for odd a
# (special handling; LTE on odd prime powers is the main use-case)
sub ord_mod_2_power {
    my ($a, $e) = @_;

    return 1 if cmpint($a, 1) <= 0;
    return 1 if $e <= 1;

    # mod 4: 1 -> 1, 3 -> 2
    if ($e == 2) {
        return ((modint($a, 4) eq '1') ? 1 : 2);
    }

    # For e >= 3, the order is a power of 2, split by residue mod 4.
    if (modint($a, 4) eq '1') {

        # a ≡ 1 (mod 4): ord_{2^e}(a) = 2^max(0, e - v_2(a-1))
        my $s = valuation(subint($a, 1), 2);
        my $k = ($e > $s) ? ($e - $s) : 0;
        return powint(2, $k);
    }
    else {
        # a ≡ 3 (mod 4): a^2 ≡ 1 (mod 4), so ord(a) = 2 * ord(a^2)
        # ord_{2^e}(a) = 2^max(1, e - v_2(a+1))
        my $t = valuation(addint($a, 1), 2);
        my $k = ($e > $t) ? ($e - $t) : 1;
        return powint(2, $k);
    }
}

sub multiplicative_order_mod_m {
    my ($a, $m) = @_;

    my $ord = 1;

    for my $fe (factor_exp($m)) {
        my ($p, $e) = @$fe;
        my $local =
          ($p == 2)
          ? ord_mod_2_power($a, $e)
          : ord_mod_odd_prime_power($a, $p, $e);

        $ord = lcm($ord, $local);
    }

    return $ord;
}

#
## Testing only
#

use Time::HiRes qw(gettimeofday tv_interval);
use Test::More tests => 58;

is(multiplicative_order_mod_m(6,   1),   1);
is(multiplicative_order_mod_m(1,   48),  1);
is(multiplicative_order_mod_m(9,   8),   1);
is(multiplicative_order_mod_m(743, 856), 106);

my $deltas_gmp  = 0;
my $deltas_this = 0;
my $tests       = 50;

# Random tests
while ($tests > 1) {

    my $a = urandomm(powint(10, $tests));
    my $m = urandomm(powint(10, $tests));

    gcd($a, $m) eq '1' or next;

    my $v0 = multiplicative_order_mod_m($a, $m);
    my $v1 = znorder($a, $m);

    is($v0, $v1, "znorder($a, $m)");
    --$tests;
}

# Large prime power tests
foreach my $pair (
    ["314159265358979323", 2, 12345],
    ["314159265358979323", 3, 12345],
    ["314159265358979323", 4, 12345],
    ["314159265358979323", 5, 12345],
) {
    my ($a, $p, $e) = @$pair;

    my $m = powint($p, $e);
    say "Testing prime power: $p^$e";

    my $t0 = [gettimeofday];
    my $v0 = multiplicative_order_mod_m($a, $m);
    say "This method took: ", tv_interval($t0);

    my $t1 = [gettimeofday];
    my $v1 = znorder($a, $m);
    say "GMP::znorder() took: ", tv_interval($t1);

    is($v0, $v1);
}

my $a = addint(powint(10, 9), 7);
my $m = factorial(10000);

is(multiplicative_order_mod_m($a, $m), znorder($a, $m));
