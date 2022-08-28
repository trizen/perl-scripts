#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 28 August 2022
# https://github.com/trizen

# Generate all the squarefree Fermat pseudoprimes to given a base with n prime factors in a given range [a,b]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

sub divceil ($x,$y) {   # ceil(x/y)
    my $q = divint($x, $y);
    (mulint($q, $y) == $x) ? $q : ($q+1);
}

sub fermat_pseudoprimes_in_range ($A, $B, $k, $base, $callback) {

    $A = vecmax($A, pn_primorial($k));

    sub ($m, $lambda, $p, $k, $u = undef, $v = undef) {

        if ($k == 1) {

            forprimes {
                my $t = mulint($m, $_);
                if (modint($t-1, $lambda) == 0 and modint($t-1, znorder($base, $_)) == 0) {
                    $callback->($t);
                }
            } $u, $v;

            return;
        }

        my $s = rootint(divint($B, $m), $k);

        for(my $r; $p <= $s; $p = $r) {

            $r = next_prime($p);
            my $t = mulint($m, $p);
            my $z = znorder($base, $p) // next;
            my $L = lcm($lambda, $z);

            ($p >= 3 and gcd($L, $t) == 1) or next;

            my $u = divceil($A, $t);
            my $v = divint($B, $t);

            if ($u <= $v) {
                __SUB__->($t, $L, $r, $k - 1, (($k==2 && $r>$u) ? $r : $u), $v);
            }
        }
    }->(1, 1, 2, $k);
}

# Generate all the squarefree Fermat pseudoprimes to base 2 with 5 prime factors in the range [100, 10^8]

my $k    = 5;
my $base = 2;
my $from = 100;
my $upto = 1e8;

my @arr; fermat_pseudoprimes_in_range($from, $upto, $k, $base, sub ($n) { push @arr, $n });

say join(', ', sort { $a <=> $b } @arr);

__END__
825265, 1050985, 1275681, 2113665, 2503501, 2615977, 2882265, 3370641, 3755521, 4670029, 4698001, 4895065, 5034601, 6242685, 6973057, 7428421, 8322945, 9223401, 9224391, 9890881, 10877581, 12067705, 12945745, 13757653, 13823601, 13992265, 16778881, 17698241, 18007345, 18162001, 18779761, 19092921, 22203181, 22269745, 23386441, 25266745, 25831585, 26553241, 27218269, 27336673, 27736345, 28175001, 28787185, 31146661, 32368609, 32428045, 32756581, 34111441, 34386121, 35428141, 36121345, 36168265, 36507801, 37167361, 37695505, 37938901, 38790753, 40280065, 40886241, 41298985, 41341321, 41424801, 41471521, 42689305, 43136821, 46282405, 47006785, 49084321, 49430305, 51396865, 52018341, 52452905, 53661945, 54177949, 54215161, 54651961, 55035001, 55329985, 58708761, 59586241, 60761701, 61679905, 63337393, 63560685, 64567405, 64685545, 67371265, 67994641, 68830021, 69331969, 71804161, 72135505, 72192021, 72348409, 73346365, 73988641, 74165065, 75151441, 76595761, 77442905, 78397705, 80787421, 83058481, 84028407, 84234745, 85875361, 86968981, 88407361, 88466521, 88689601, 89816545, 89915365, 92027001, 92343745, 92974921, 93614521, 93839201, 93869665, 96259681, 96386865, 96653985, 98124481, 98756281, 99551881
