#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 19 July 2020
# https://github.com/trizen

# Count the number of B-smooth numbers <= n.

# Inspired by Dana Jacobsen's "smooth_count(n,k)" algorithm from Math::Prime::Util::PP.

# See also:
#   https://en.wikipedia.org/wiki/Smooth_number

use 5.020;
use ntheory qw(:all);
use experimental qw(signatures);

use Math::GMPz;

sub smooth_count ($n, $k) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    if ($k < 2 or Math::GMPz::Rmpz_sgn($n) <= 0) {
        return 0;
    }

    if (Math::GMPz::Rmpz_cmp_ui($n, $k) <= 0) {
        return $n;
    }

    my $count = sub ($n, $k) {

        my $sum = Math::GMPz::Rmpz_sizeinbase($n, 2);

        if ($k == 2) {
            return $sum;
        }

        my $t = Math::GMPz::Rmpz_init();

        for (my $p = 3 ; $p <= $k ; $p = next_prime($p)) {

            Math::GMPz::Rmpz_tdiv_q_ui($t, $n, $p);

            if (Math::GMPz::Rmpz_cmp_ui($t, $p) <= 0) {
                $sum += Math::GMPz::Rmpz_get_ui($t);
            }
            else {
                $sum += __SUB__->($t, $p);
            }
        }

        $sum;
    }->($n, prev_prime($k + 1));

    return $count;
}

foreach my $p (@{primes(50)}) {
    say "Ψ(10^n, $p) for n <= 10: [", join(', ', map { smooth_count(powint(10, $_), $p) } 0 .. 10), "]";
}

__END__
Ψ(10^n,  2) for n <= 10: [1, 4, 7, 10, 14, 17, 20, 24, 27, 30, 34]
Ψ(10^n,  3) for n <= 10: [1, 7, 20, 40, 67, 101, 142, 190, 244, 306, 376]
Ψ(10^n,  5) for n <= 10: [1, 9, 34, 86, 175, 313, 507, 768, 1105, 1530, 2053]
Ψ(10^n,  7) for n <= 10: [1, 10, 46, 141, 338, 694, 1273, 2155, 3427, 5194, 7575]
Ψ(10^n, 11) for n <= 10: [1, 10, 55, 192, 522, 1197, 2432, 4520, 7838, 12867, 20193]
Ψ(10^n, 13) for n <= 10: [1, 10, 62, 242, 733, 1848, 4106, 8289, 15519, 27365, 45914]
Ψ(10^n, 17) for n <= 10: [1, 10, 67, 287, 945, 2579, 6179, 13389, 26809, 50351, 89679]
Ψ(10^n, 19) for n <= 10: [1, 10, 72, 331, 1169, 3419, 8751, 20198, 42950, 85411, 160626]
Ψ(10^n, 23) for n <= 10: [1, 10, 76, 369, 1385, 4298, 11654, 28434, 63768, 133440, 263529]
Ψ(10^n, 29) for n <= 10: [1, 10, 79, 402, 1581, 5158, 14697, 37627, 88415, 193571, 399341]
Ψ(10^n, 31) for n <= 10: [1, 10, 82, 434, 1778, 6070, 18083, 48366, 118599, 270648, 581272]
Ψ(10^n, 37) for n <= 10: [1, 10, 84, 461, 1958, 6952, 21535, 59867, 152482, 361173, 804369]
Ψ(10^n, 41) for n <= 10: [1, 10, 86, 485, 2129, 7833, 25133, 72345, 190767, 467495, 1076462]
Ψ(10^n, 43) for n <= 10: [1, 10, 88, 508, 2300, 8740, 28955, 86086, 234423, 592949, 1408465]
Ψ(10^n, 47) for n <= 10: [1, 10, 90, 529, 2463, 9639, 32876, 100688, 282397, 735425, 1797897]
