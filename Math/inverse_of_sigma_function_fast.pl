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

use integer;
use ntheory qw(:all);
use List::Util qw(uniq);
use experimental qw(signatures);

binmode(STDOUT, ':utf8');

sub inverse_sigma {
    my ($n) = @_;

    my %cache;
    my %mpz_cache;
    my %factor_cache;
    my %divisor_cache;

    my $results = sub ($n, $m) {

        return [1] if ($n == 1);

        my $key = "$n $m";
        if (exists $cache{$key}) {
            return $cache{$key};
        }

        my (@R, @D);
        $divisor_cache{$n} //= [divisors($n)];

        foreach my $d (@{$divisor_cache{$n}}) {
            if ($d >= $m) {

                push @D, $d;

                $factor_cache{$d} //= do {
                    my %factors;
                    @factors{factor($D[-1] - 1)} = ();
                    [keys %factors];
                };
            }
        }

        foreach my $d (@D) {
            foreach my $p (@{$factor_cache{$d}}) {

                my $r = $d * ($p - 1) + 1;
                my $k = valuation($r, $p) - 1;
                next if ($k < 1);

                my $s = powint($p, $k + 1);
                next if ($r != $s);
                my $z = powint($p, $k);

                my $u   = $n / $d;
                my $arr = __SUB__->($u, $d);

                foreach my $v (@$arr) {
                    if ($v % $p != 0) {
                        push @R, $v * $z;
                    }
                }
            }
        }

        $cache{$key} = \@R;
    }->($n, 3);

    uniq(@$results);
}

my %tests = (
     6 => 6187272, 10 => 196602,  11 => 8105688, 16 => 2031554,
    25 => 1355816, 31 => 8880128, 80 => 11532,   97 => 5488,
);

while (my ($n, $k) = each %tests) {
    my @inverse = inverse_sigma($k);
    say "σ−¹($k) = [@inverse]";
    if (gcd(@inverse) != $n) {
        die "Error for k = $k";
    }
}

__END__
σ−¹(6187272) = [2855646 2651676]
σ−¹(196602) = [105650 81920]
σ−¹(8105688) = [4953454 4947723]
σ−¹(2031554) = [845200 999424]
σ−¹(8880128) = [6389751 7527079]
σ−¹(5488) = [3783 2716]
σ−¹(11532) = [4880 4400]
σ−¹(1355816) = [457500 390000 811875 624700]
