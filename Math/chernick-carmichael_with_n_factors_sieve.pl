#!/usr/bin/perl

# Sieve for Chernick's "universal form" Carmichael number with n prime factors.
# Inspired by the PARI program by David A. Corneth from OEIS A372238.

# Finding A318646(10) takes ~4 minutes.

# See also:
#   https://oeis.org/A318646
#   https://oeis.org/A372238/a372238.gp.txt

use 5.036;
use ntheory     qw(:all);
use Time::HiRes qw (time);

sub isrem($m, $p, $n) {

    ( 6 * $m + 1) % $p == 0 and ( 6 * $m + 1) != $p and return;
    (12 * $m + 1) % $p == 0 and (12 * $m + 1) != $p and return;

    foreach my $k (1 .. $n - 2) {
        my $t = (9 * $m << $k) + 1;
        if ($t % $p == 0 and $t != $p) {
            return;
        }
    }

    return 1;
}

sub remaindersmodp($p, $n) {
    grep { isrem($_, $p, $n) } (0 .. $p - 1);
}

sub remainders_for_primes($n, $primes) {

    my $res = [[0, 1]];

    foreach my $p (@$primes) {

        my @rems = remaindersmodp($p, $n);

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

sub is($m, $n) {

    is_prime( 6 * $m + 1) || return;
    is_prime(12 * $m + 1) || return;
    is_prime(18 * $m + 1) || return;

    foreach my $k (2 .. $n - 2) {
        is_prime((9 * $m << $k) + 1) || return;
    }

    return 1;
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

sub chernick_carmichael_factors($m, $n) {
    (6 * $m + 1, 12 * $m + 1, (map { (9 * $m << $_) + 1 } 1 .. $n - 2));
}

sub chernick_carmichael_with_n_factors($n, $maxp = nth_prime($n)) {

    my @primes = @{primes($maxp)};

    my @r = remainders_for_primes($n, \@primes);
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

    my $two_power = vecmax(1 << ($n - 4), 1);

    for (my $j = 0 ; ; ++$j) {

        if ($m % $two_power == 0 and is($m, $n)) {
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

foreach my $n (3 .. 9) {
    my $m = chernick_carmichael_with_n_factors($n);
    say "[$n] m = $m";

    foreach my $k ($n .. $n + 100) {
        my $c = vecprod(chernick_carmichael_factors($m, $k));
        if (is_carmichael($c)) {
            say "[$k] $c";
        }
        else {
            last;
        }
    }

    is_carmichael(vecprod(chernick_carmichael_factors($m, $n))) || die "not a Carmichael number";
}

__END__
[3] m = 1
[3] 1729
[4] 63973
[4] m = 1
[4] 63973
[5] m = 380
[5] 26641259752490421121
[6] 1457836374916028334162241
[6] m = 380
[6] 1457836374916028334162241
[7] m = 780320
[7] 24541683183872873851606952966798288052977151461406721
[8] m = 950560
[8] 53487697914261966820654105730041031613370337776541835775672321
[9] 58571442634534443082821160508299574798027946748324125518533225605795841
[9] m = 950560
[9] 58571442634534443082821160508299574798027946748324125518533225605795841
[10] m = 3208386195840
[10] 24616075028246330441656912428380582403261346369700917629170235674289719437963233744091978433592331048416482649086961226304033068172880278517841921
