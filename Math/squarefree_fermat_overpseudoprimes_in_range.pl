#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 28 August 2022
# Edit: 03 September 2022
# https://github.com/trizen

# Generate all the squarefree Fermat overpseudoprimes to given a base with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

use 5.020;
use warnings;

use ntheory qw(:all);
use experimental qw(signatures);
use Memoize qw(memoize);

memoize('inverse_znorder_primes');

sub divceil ($x,$y) {   # ceil(x/y)
    my $q = divint($x, $y);
    ($q*$y == $x) ? $q : ($q+1);
}

sub inverse_znorder_primes($base, $lambda) {
    my %seen;
    grep { znorder($base, $_) == $lambda } grep { !$seen{$_}++ } factor(subint(powint($base, $lambda), 1));
}

sub squarefree_fermat_overpseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    sub ($m, $lambda, $p, $k, $u = undef, $v = undef) {

        if ($k == 1) {

            if ($lambda <= 135) {
                foreach my $p (inverse_znorder_primes($base, $lambda)) {
                    next if $p < $u;
                    next if $p > $v;
                    if (($m*$p - 1)%$lambda == 0) {
                        $callback->($m*$p);
                    }
                }
                return;
            }

            if (prime_count_lower($v)-prime_count_lower($u) < divint($v-$u, $lambda)) {
                forprimes {
                    if (($m*$_ - 1)%$lambda == 0 and powmod($base, $lambda, $_) == 1 and znorder($base, $_) == $lambda) {
                        $callback->($m*$_);
                    }
                } $u, $v;
                return;
            }

            for(my $w = $lambda * divceil($u-1, $lambda); $w <= $v; $w += $lambda) {
                if (is_prime($w+1) and powmod($base, $lambda, $w+1) == 1) {
                    my $p = $w+1;
                    if (($m*$p - 1)%$lambda == 0 and znorder($base, $p) == $lambda) {
                        $callback->($m*$p);
                    }
                }
            }

            return;
        }

        my $s = rootint(divint($B, $m), $k);

        if ($lambda > 1 and $lambda <= 135) {
            for my $q (inverse_znorder_primes($base, $lambda)) {

                next if ($q < $p);
                next if ($q > $s);

                my $t = $m*$q;
                my $u = divceil($A, $t);
                my $v = divint($B, $t);

                if ($u <= $v) {
                    my $r = next_prime($q);
                    __SUB__->($t, $lambda, $r, $k-1, (($k==2 && $r>$u) ? $r : $u), $v);
                }
            }
            return;
        }

        if ($lambda > 1) {
            for(my $w = $lambda * divceil($p-1, $lambda); $w <= $s; $w += $lambda) {
                if (is_prime($w+1) and powmod($base, $lambda, $w+1) == 1) {
                    my $p = $w+1;

                    $lambda == znorder($base, $p) or next;
                    $base % $p == 0 and next;

                    my $t = $m*$p;
                    my $u = divceil($A, $t);
                    my $v = divint($B, $t);

                    if ($u <= $v) {
                        my $r = next_prime($p);
                        __SUB__->($t, $lambda, $r, $k-1, (($k==2 && $r>$u) ? $r : $u), $v);
                    }
                }
            }

            return;
        }

        for (my $r; $p <= $s; $p = $r) {

            $r = next_prime($p);
            $base % $p == 0 and next;

            my $L = znorder($base, $p);
            $L == $lambda or $lambda == 1 or next;

            gcd($L, $m) == 1 or next;

            my $t = $m*$p;
            my $u = divceil($A, $t);
            my $v = divint($B, $t);

            if ($u <= $v) {
                __SUB__->($t, $L, $r, $k - 1, (($k==2 && $r>$u) ? $r : $u), $v);
            }
        }
    }->(1, 1, 2, $k);
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
