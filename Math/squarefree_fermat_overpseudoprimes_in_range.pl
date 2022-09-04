#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 28 August 2022
# Edit: 04 September 2022
# https://github.com/trizen

# Generate all the squarefree Fermat overpseudoprimes to given a base with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;

use ntheory      qw(:all);
use experimental qw(signatures);
use Memoize      qw(memoize);

memoize('inverse_znorder_primes');

sub divceil ($x, $y) {    # ceil(x/y)
    my $q = divint($x, $y);
    ($q * $y == $x) ? $q : ($q + 1);
}

sub inverse_znorder_primes ($base, $lambda) {
    my %seen;
    grep { !$seen{$_}++ } factor(subint(powint($base, $lambda), 1));
}

sub iterate_over_primes ($x, $y, $base, $lambda, $callback) {

    if ($lambda > 1 and $lambda <= 135) {
        foreach my $p (inverse_znorder_primes($base, $lambda)) {

            next if $p < $x;
            next if $p > $y;

            #znorder($base, $p) == $lambda or next;

            $callback->($p);
        }
        return;
    }

    if ($lambda > 1) {
        for (my $w = $lambda * divceil($x - 1, $lambda) ; $w <= $y ; $w += $lambda) {
            if (is_prime($w + 1) and powmod($base, $lambda, $w + 1) == 1) {
                $callback->($w + 1);
            }
        }
        return;
    }

    for (my $p = next_prime($x - 1) ; $p <= $y ; $p = next_prime($p)) {
        $callback->($p);
    }
}

sub squarefree_fermat_overpseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    my $F;
    $F = sub ($m, $lambda, $x, $k, $u = undef, $v = undef) {

        if ($k == 1) {

            iterate_over_primes($u, $v, $base, $lambda, sub ($p) {
                if (powmod($base, $lambda, $p) == 1) {
                    if (($m * $p - 1) % $lambda == 0 and znorder($base, $p) == $lambda) {
                        $callback->($m * $p);
                    }
                }
            });

            return;
        }

        my $y = rootint(divint($B, $m), $k);

        $x > $y and return;

        iterate_over_primes($x, $y, $base, $lambda, sub ($p) {
            if ($base % $p != 0) {

                my $L = znorder($base, $p);
                if (($L == $lambda or $lambda == 1) and gcd($L, $m) == 1) {

                    my $t = $m * $p;
                    my $u = divceil($A, $t);
                    my $v = divint($B, $t);

                    if ($u <= $v) {
                        my $r = next_prime($p);
                        $F->($t, $L, $r, $k - 1, (($k == 2 && $r > $u) ? $r : $u), $v);
                    }
                }
            }
        });
    };

    $F->(1, 1, 2, $k);
    undef $F;
}

# Generate all the squarefree Fermat overpseudoprimes to base 2 with 3 prime factors in the range [13421773, 412346200100]

my $k    = 3;
my $base = 2;
my $from = 13421773;
my $upto = 412346200100;

my @arr; squarefree_fermat_overpseudoprimes_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
13421773, 464955857, 536870911, 1220114377, 1541955409, 2454285751, 3435973837, 5256967999, 5726579371, 7030714813, 8493511669, 8538455017, 8788016089, 10545166433, 13893138041, 17112890881, 18723407341, 19089110641, 21335883193, 23652189937, 37408911097, 43215089153, 47978858771, 50032571509, 50807757529, 54975581389, 59850086533, 65700513721, 68713275457, 78889735961, 85139035489, 90171022049, 99737787437, 105207688757, 125402926477, 149583518641, 161624505241, 168003672409, 175303004581, 206005507811, 219687786701, 252749217641, 262106396551, 265866960649, 276676965109, 280792563977, 294207272761, 306566231341, 355774589609, 381491063773
