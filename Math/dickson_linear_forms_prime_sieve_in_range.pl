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
use Test::More tests => 17;

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
    my $M   = 1;

    foreach my $p (@$primes) {

        my @rems = remaindersmodp($p, $terms);

        if (scalar(@rems) == $p) {
            next;    # skip trivial primes
        }

        if (!@rems) {
            @rems = (0);
        }

        my @nres;
        foreach my $r (@$res) {
            foreach my $rem (@rems) {
                push @nres, [chinese($r, [$rem, $p]), lcm($p, $r->[1])];
            }
        }

        $M *= $p;
        $res = \@nres;
    }

    return ($M, [sort { $a <=> $b } map { $_->[0] } @$res]);
}

sub deltas ($integers) {

    my @deltas;
    my $prev = 0;

    foreach my $n (@$integers) {
        push @deltas, $n - $prev;
        $prev = $n;
    }

    shift(@deltas);
    return \@deltas;
}

sub linear_form_primes_in_range($A, $B, $terms) {

    return [] if ($A > $B);

    my $terms_len  = scalar(@$terms);
    my $range_size = int(exp(LambertW(log($B - $A + 1))));

    my $max_p  = nth_prime(vecmin($terms_len, $range_size));
    my @primes = @{primes($max_p)};

    my ($M, $r) = remainders_for_primes(\@primes, $terms);
    my @d = @{deltas($r)};

    while (@d and $d[0] == 0) {
        shift @d;
    }

    push @d, $r->[0] + $M - $r->[-1];

    my $m      = $r->[0];
    my $d_len  = scalar(@d);
    my $t0     = time;
    my $prev_m = $m;
    my $d_sum  = vecsum(@d);

    $m += $d_sum * divint($A, $d_sum);

    my $j = 0;

    while ($m < $A) {
        $m += $d[$j++ % $d_len];
    }

    my @arr;

    while (1) {
        my $ok = 1;
        foreach my $k (@$terms) {
            if (!is_prime($k->[0] * $m + $k->[1])) {
                $ok = 0;
                last;
            }
        }

        if ($ok) {
            push @arr, $m;
        }

        if ($j % 1e7 == 0 and $j > 0) {
            my $tdelta = time - $t0;
            say "Searching with m = $m";
            say "Performance: ", (($m - $prev_m) / 1e9) / $tdelta, " * 10^9 terms per second";
            $t0     = time;
            $prev_m = $m;
        }

        $m += $d[$j++ % $d_len];
        last if ($m > $B);
    }

    return \@arr;
}

is_deeply(linear_form_primes_in_range(1, 41, [[1, 41]]),                                           [2, 6, 12, 18, 20, 26, 30, 32, 38]);
is_deeply(linear_form_primes_in_range(1, 50, [[1, 1]]),                                            [1, 2, 4, 6, 10, 12, 16, 18, 22, 28, 30, 36, 40, 42, 46]);
is_deeply(linear_form_primes_in_range(1, 100, [[1, 1], [2, 1]]),                                   [1, 2, 6, 18, 30, 36, 78, 96]);
is_deeply(linear_form_primes_in_range(1, 1000, [[1, 1], [2, 1], [3, 1]]),                          [2, 6, 36, 210, 270, 306, 330, 336, 600, 726]);
is_deeply(linear_form_primes_in_range(1, 10000, [[1, 1], [2, 1], [3, 1], [4, 1]]),                 [330, 1530, 3060, 4260, 4950, 6840]);
is_deeply(linear_form_primes_in_range(1, 12000, [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1]]),         [10830]);
is_deeply(linear_form_primes_in_range(9538620, 9993270, [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1]]), [9538620, 9780870, 9783060, 9993270]);
is_deeply(linear_form_primes_in_range(9538620 + 1, 9993270, [[1, 1], [2, 1], [3, 1], [4, 1], [5, 1]]), [9780870, 9783060, 9993270]);

is_deeply(linear_form_primes_in_range(1, 1000, [[1, -1], [2, -1], [3, -1]]),           [4, 6, 24, 30, 84, 90, 174, 234, 240, 294, 420, 660, 954]);
is_deeply(linear_form_primes_in_range(1, 10000, [[1, -1], [2, -1], [3, -1], [4, -1]]), [6, 90, 1410, 1890]);
is_deeply(linear_form_primes_in_range(1, 500, [[2, -1], [4, -1], [6, -1]]),            [2, 3, 12, 15, 42, 45, 87, 117, 120, 147, 210, 330, 477]);
is_deeply(linear_form_primes_in_range(1, 500, [[2, 1], [4, 3], [8, 7]]),               [2, 5, 20, 44, 89, 179, 254, 359]);
is_deeply(linear_form_primes_in_range(1, 500, [[2, -1], [4, -1], [8, -1]]),            [3, 6, 21, 45, 90, 180, 255, 360]);
is_deeply(linear_form_primes_in_range(1, 500, [[2, -1], [4, -1], [8, -1], [16, -1]]),  [3, 45, 90, 180, 255]);
is_deeply(linear_form_primes_in_range(1, 500, [[17, 1], [23, 5]]),                     [18, 24, 66, 126, 186, 216, 378, 384, 426]);

is_deeply(linear_form_primes_in_range(1, 500, [[17, 4], [15, -8], [19, 2]]),
          [5, 9, 11, 65, 75, 105, 125, 159, 191, 221, 231, 291, 341, 369, 419, 461, 471, 479]);
is_deeply(linear_form_primes_in_range(1, 500, [[17, 4], [15, +8], [19, 2]]), [5, 11, 45, 65, 105, 159, 161, 189, 221, 275, 291, 299, 431, 479]);

say "\n=> The least Chernick's \"universal form\" Carmichael number with n prime factors";

foreach my $n (3 .. 8) {

    my $terms = [map { [$_, 1] } (6, 12, (map { 9 * (1 << $_) } 1 .. $n - 2))];

    my $A = 1;
    my $B = 2 * $A;

    while (1) {
        my @arr = @{linear_form_primes_in_range($A, $B, $terms)};

        @arr = grep { valuation($_, 2) >= $n - 4 } @arr;

        if (@arr) {
            say "a($n) = $arr[0]";
            last;
        }

        $A = $B + 1;
        $B = 2 * $A;
    }
}

say "\n=> Smallest number k such that r*k + 1 is prime for all r = 1 to n\n";

foreach my $n (1 .. 8) {

    my $terms = [map { [$_, 1] } 1 .. $n];

    my $A = 1;
    my $B = 2 * $A;

    while (1) {
        my @arr = @{linear_form_primes_in_range($A, $B, $terms)};

        if (@arr) {
            say "a($n) = $arr[0]";
            last;
        }

        $A = $B + 1;
        $B = 2 * $A;
    }
}

__END__
=> The least Chernick's "universal form" Carmichael number with n prime factors
a(3) = 1
a(4) = 1
a(5) = 380
a(6) = 380
a(7) = 780320
a(8) = 950560

=> Smallest number k such that r*k + 1 is prime for all r = 1 to n

a(1) = 1
a(2) = 1
a(3) = 2
a(4) = 330
a(5) = 10830
a(6) = 25410
a(7) = 512820
a(8) = 512820
