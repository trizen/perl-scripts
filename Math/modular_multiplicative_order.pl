#!/usr/bin/perl

# Compute the multiplicative order `znorder(a,n)` modulo m.

# See also:
#   https://projecteuler.net/problem=952

use 5.036;
use ntheory qw(:all);

# Multiplicative order mod p^e for odd prime p, using LTE
sub ord_mod_odd_prime_power ($a, $p, $e) {

    my $t = znorder($a, $p);

    # Find s = v_p(a^t - 1) up to e.
    # We increment the exponent rather than doing one massive powmod,
    # keeping the modulus extremely small (usually p^2 or p^3).
    my $s     = 1;
    my $p_pow = mulint($p, $p);

    while ($s < $e && powmod($a, $t, $p_pow) == 1) {
        $s++;
        $p_pow = mulint($p_pow, $p);
    }

    my $k = ($e > $s) ? ($e - $s) : 0;
    return [$t, $p, $k];
}

# Multiplicative order mod 2^e for odd a
# (special handling; LTE on odd prime powers is the main use-case)
sub ord_mod_2_power($a, $e) {

    return [1, 2, 0] if cmpint($a, 1) <= 0;
    return [1, 2, 0] if $e <= 1;

    # mod 4: 1 -> 1, 3 -> 2
    if ($e == 2) {
        return ((modint($a, 4) eq '1') ? [1, 2, 0] : [1, 2, 1]);
    }

    # For e >= 3, the order is a power of 2, split by residue mod 4.
    if (modint($a, 4) == 1) {

        # a ≡ 1 (mod 4): ord_{2^e}(a) = 2^max(0, e - v_2(a-1))
        my $s = valuation(subint($a, 1), 2);
        my $k = ($e > $s) ? ($e - $s) : 0;
        return [1, 2, $k];
    }
    else {
        # a ≡ 3 (mod 4): a^2 ≡ 1 (mod 4), so ord(a) = 2 * ord(a^2)
        # ord_{2^e}(a) = 2^max(1, e - v_2(a+1))
        my $t = valuation(addint($a, 1), 2);
        my $k = ($e > $t) ? ($e - $t) : 1;
        return [1, 2, $k];
    }
}

sub multiplicative_order_mod_m($a, $m, $mod) {

    my %table;

    for my $fe (factor_exp($m)) {
        my ($p, $e) = @$fe;

        my $t =
          ($p == 2)
          ? ord_mod_2_power($a, $e)
          : ord_mod_odd_prime_power($a, $p, $e);

        $table{$t->[1]} = vecmax($table{$t->[1]} // 0, $t->[2]);

        foreach my $pp (factor_exp($t->[0])) {
            my ($p2, $e2) = @$pp;
            $table{$p2} = vecmax($table{$p2} // 0, $e2);
        }
    }

    my $ord = 1;
    foreach my $p (keys %table) {
        $ord = mulmod($ord, powmod($p, $table{$p}, $mod), $mod);
    }

    return $ord;
}

my $a   = powint(10, 7) + 7;
my $n   = factorial(100);
my $mod = powint(10, 9) + 7;

say modint(znorder($a, $n), $mod);
say multiplicative_order_mod_m($a, $n, $mod);
