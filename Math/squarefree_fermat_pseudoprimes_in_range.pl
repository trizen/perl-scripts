#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 28 August 2022
# https://github.com/trizen

# Generate all the squarefree Fermat pseudoprimes to a given base with n prime factors in a given range [A,B]. (not in sorted order)

# See also:
#   https://en.wikipedia.org/wiki/Almost_prime
#   https://trizenx.blogspot.com/2020/08/pseudoprimes-construction-methods-and.html

# PARI/GP program (in range) (simple):
#   squarefree_fermat(A, B, k, base=2) = A=max(A, vecprod(primes(k))); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(lo > hi, return(list)); if(k==1, forprime(p=max(lo, ceil(A/m)), hi, if(base%p != 0, my(t=m*p); if((t-1)%l == 0 && (t-1)%znorder(Mod(base, p)) == 0, listput(list, t)))), forprime(p=lo, hi, if (base%p != 0, my(z=znorder(Mod(base, p))); if(gcd(m, z) == 1, list=concat(list, f(m*p, lcm(l,z), p+1, k-1)))))); list); vecsort(Vec(f(1, 1, 2, k)));

# PARI/GP program (in range) (faster):
#   squarefree_fermat(A, B, k, base=2) = A=max(A, vecprod(primes(k))); (f(m, l, lo, k) = my(list=List()); my(hi=sqrtnint(B\m, k)); if(lo > hi, return(list)); if(k==1, lo=max(lo, ceil(A/m)); my(t=lift(1/Mod(m,l))); while(t < lo, t += l); forstep(p=t, hi, l, if(isprime(p), my(n=m*p); if((n-1)%znorder(Mod(base, p)) == 0, listput(list, n)))), forprime(p=lo, hi, if (base%p != 0, my(z=znorder(Mod(base, p))); if(gcd(m, z) == 1, list=concat(list, f(m*p, lcm(l,z), p+1, k-1)))))); list); vecsort(Vec(f(1, 1, 2, k)));

use 5.036;
use warnings;
use ntheory qw(:all);

sub divceil ($x, $y) {    # ceil(x/y)
    (($x % $y == 0) ? 0 : 1) + divint($x, $y);
}

sub squarefree_fermat_pseudoprimes_in_range ($A, $B, $k, $base) {

    $A = vecmax($A, pn_primorial($k));

    my @list;

    sub ($m, $L, $lo, $k) {

        my $hi = rootint(divint($B, $m), $k);

        if ($lo > $hi) {
            return;
        }

        if ($k == 1) {

            $lo = vecmax($lo, divceil($A, $m));
            $lo > $hi && return;

            my $t = invmod($m, $L);
            $t > $hi && return;
            $t += $L * divceil($lo - $t, $L) if ($t < $lo);

            for (my $p = $t ; $p <= $hi ; $p += $L) {
                if (is_prime($p) and $base % $p != 0) {
                    if (($m * $p - 1) % znorder($base, $p) == 0) {
                        push(@list, $m * $p);
                    }
                }
            }

            return;
        }

        foreach my $p (@{primes($lo, $hi)}) {

            $base % $p == 0 and next;
            my $z = znorder($base, $p);
            gcd($m, $z) == 1 or next;

            __SUB__->($m * $p, lcm($L, $z), $p + 1, $k - 1);
        }
      }
      ->(1, 1, 2, $k);

    return sort { $a <=> $b } @list;
}

# Generate all the squarefree Fermat pseudoprimes to base 2 with 5 prime factors in the range [100, 10^8]

my $k    = 5;
my $base = 2;
my $from = 100;
my $upto = 1e8;

my @arr = squarefree_fermat_pseudoprimes_in_range($from, $upto, $k, $base);

say join(', ', sort { $a <=> $b } @arr);

# Run some tests

if (1) {    # true to run some tests
    foreach my $k (2 .. 6) {

        my $lo           = pn_primorial($k);
        my $hi           = mulint($lo, 1000);
        my @omega_primes = grep { is_square_free($_) } @{omega_primes($k, $lo, $hi)};

        foreach my $base (2 .. 100) {
            my @this = grep { is_pseudoprime($_, $base) } @omega_primes;
            my @that = squarefree_fermat_pseudoprimes_in_range($lo, $hi, $k, $base);
            join(' ', @this) eq join(' ', @that)
              or die "Error for k = $k and base = $base with hi = $hi\n(@this) != (@that)";
        }
    }
}

__END__
825265, 1050985, 1275681, 2113665, 2503501, 2615977, 2882265, 3370641, 3755521, 4670029, 4698001, 4895065, 5034601, 6242685, 6973057, 7428421, 8322945, 9223401, 9224391, 9890881, 10877581, 12067705, 12945745, 13757653, 13823601, 13992265, 16778881, 17698241, 18007345, 18162001, 18779761, 19092921, 22203181, 22269745, 23386441, 25266745, 25831585, 26553241, 27218269, 27336673, 27736345, 28175001, 28787185, 31146661, 32368609, 32428045, 32756581, 34111441, 34386121, 35428141, 36121345, 36168265, 36507801, 37167361, 37695505, 37938901, 38790753, 40280065, 40886241, 41298985, 41341321, 41424801, 41471521, 42689305, 43136821, 46282405, 47006785, 49084321, 49430305, 51396865, 52018341, 52452905, 53661945, 54177949, 54215161, 54651961, 55035001, 55329985, 58708761, 59586241, 60761701, 61679905, 63337393, 63560685, 64567405, 64685545, 67371265, 67994641, 68830021, 69331969, 71804161, 72135505, 72192021, 72348409, 73346365, 73988641, 74165065, 75151441, 76595761, 77442905, 78397705, 80787421, 83058481, 84028407, 84234745, 85875361, 86968981, 88407361, 88466521, 88689601, 89816545, 89915365, 92027001, 92343745, 92974921, 93614521, 93839201, 93869665, 96259681, 96386865, 96653985, 98124481, 98756281, 99551881
