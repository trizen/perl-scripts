#!/usr/bin/perl

# Sieve for linear forms primes of the form `a_1*m + b_1`, `a_2*m + b_2`, ..., `a_k*m + b_k`.
# Inspired by the PARI program by David A. Corneth from OEIS A372238.

# See also:
#   https://oeis.org/A088250
#   https://oeis.org/A318646
#   https://oeis.org/A372238/a372238.gp.txt
#   https://en.wikipedia.org/wiki/Dickson%27s_conjecture

use 5.036;
use ntheory     qw(:all);
use List::Util  qw(all);
use Time::HiRes qw(time);

sub isrem($m, $p, $terms) {

    foreach my $k (@$terms) {
        my $t = $k->[0] * $m + $k->[1];
        if ($t % $p == 0 and $t > $p) {
            return;
        }
    }

    return 1;
}

sub remaindersmodp($p, $terms) {
    grep { isrem($_, $p, $terms) } (0 .. $p - 1);
}

sub remainders_for_primes($primes, $terms) {

    my $res = [[0, 1]];

    foreach my $p (@$primes) {

        my @rems = remaindersmodp($p, $terms);

        if (!@rems) {
            @rems = (0);
        }

        my @nres;
        foreach my $r (@$res) {
            foreach my $rem (@rems) {
                push @nres, [chinese($r, [$rem, $p]), lcm($p, $r->[1])];
            }
        }

        $res = \@nres;
    }

    sort { $a <=> $b } map { $_->[0] } @$res;
}

sub deltas ($integers) {

    my @deltas;
    my $prev = 0;

    foreach my $n (@$integers) {
        push @deltas, $n - $prev;
        $prev = $n;
    }

    CORE::shift(@deltas);
    return \@deltas;
}

sub linear_form_primes($terms, $maxp = nth_prime(scalar(@$terms))) {

    my @primes = @{primes($maxp)};

    my @r = remainders_for_primes(\@primes, $terms);
    my @d = @{deltas(\@r)};
    my $s = vecprod(@primes);

    while (@d and $d[0] == 0) {
        shift @d;
    }

    push @d, $r[0] + $s - $r[-1];

    my $m      = $r[0];
    my $d_len  = scalar(@d);
    my $t0     = time;
    my $prev_m = $m;
    my $n      = scalar(@$terms);

    for (my $j = 0 ; ; ++$j) {

        my $ok = 1;
        foreach my $k (@$terms) {
            if (!is_prime($k->[0] * $m + $k->[1])) {
                $ok = 0;
                last;
            }
        }

        if ($ok) {
            return $m;
        }

        if ($j % 1e7 == 0 and $j > 0) {
            my $tdelta = time - $t0;
            say "Searching for a($n) with m = $m";
            say "Performance: ", (($m - $prev_m) / 1e9) / $tdelta, " * 10^9 terms per second";
            $t0     = time;
            $prev_m = $m;
        }

        $m += $d[$j % $d_len];
    }
}

foreach my $n (1 .. 10) {
    my @terms = map { [$_, 1] } (1 .. $n);
    my $m     = linear_form_primes(\@terms);
    say "a($n) = $m";
}

__END__
a(1) = 1
a(2) = 1
a(3) = 2
a(4) = 330
a(5) = 10830
a(6) = 25410
a(7) = 512820
a(8) = 512820
a(9) = 12960606120
a(10) = 434491727670
