#!/usr/bin/perl

# Sieve for Dickson primes: primes of the form `m*k + a`, for `k = 1..n` and fixed `a`.
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

sub isrem($m, $p, $terms, $alpha) {

    foreach my $k (@$terms) {
        if (($k * $m + $alpha) % $p == 0) {
            return;
        }
    }

    return 1;
}

sub remaindersmodp($p, $terms, $alpha) {
    grep { isrem($_, $p, $terms, $alpha) } (0 .. $p - 1);
}

sub remainders_for_primes($primes, $terms, $alpha) {

    my $res = [[0, 1]];

    foreach my $p (@$primes) {

        my @rems = remaindersmodp($p, $terms, $alpha);

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

    return \@deltas;
}

sub linear_form_primes($terms, $alpha = 1, $maxp = 3 * scalar(@$terms)) {

    my @primes = @{primes($maxp)};

    my @r = remainders_for_primes(\@primes, $terms, $alpha);
    my @d = @{deltas(\@r)};
    my $s = vecprod(@primes);

    while ($d[0] == 0) {
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
            if (!is_prime($k * $m + $alpha)) {
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

foreach my $n (4 .. 10) {
    my @terms = (1 .. $n);
    my $alpha = 1;
    my $m     = linear_form_primes(\@terms, $alpha);
    say "a($n) = $m";
}

__END__
a(4) = 330
a(5) = 10830
a(6) = 25410
a(7) = 512820
a(8) = 512820
a(9) = 12960606120
a(10) = 434491727670
