#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 09 September 2018
# https://github.com/trizen

# A new integer factorization method, using the Fibonacci numbers.

# It uses the smallest divisor `d` of `p - legendre(p, 5)`, for which `Fibonacci(d) = 0 (mod p)`.

# By selecting a small bound B, we compute `k = lcm(1..B)`, hoping that `k` is a
# multiple of `d`, then `gcd(Fibonacci(k) (mod n), n)` in a non-trivial factor of `n`.

# This method is similar in flavor to Pollard's p-1 and Williams's p+1 methods.

use 5.020;
use warnings;

use experimental qw(signatures);

use Math::AnyNum qw(:overload gcd ilog2 is_prime);
use Math::Prime::Util::GMP qw(consecutive_integer_lcm random_prime lucas_sequence);

sub fibonacci_factorization ($n, $B = 10000) {

    my $k = consecutive_integer_lcm($B);            # lcm(1..B)
    my $F = (lucas_sequence($n, 1, -1, $k))[0];     # Fibonacci(k) (mod n)

    return gcd($F, $n);
}

say fibonacci_factorization(257221 * 470783,              700);     #=> 470783           (p+1 is  700-smooth)
say fibonacci_factorization(333732865481 * 1632480277613, 3000);    #=> 333732865481     (p-1 is 3000-smooth)

# Example of a larger number that can be factorized fast with this method
say fibonacci_factorization(203544696384073367670016326770637347800169508950125910682353, 19);    #=> 5741461760879844361

foreach my $k (1 .. 50) {

    my $n = Math::AnyNum->new(random_prime(1 << $k)) * random_prime(1 << $k);
    my $p = fibonacci_factorization($n, 2 * ilog2($n)**2);

    if (is_prime($p)) {
        say "$n = $p * ", $n / $p;
    }
}
