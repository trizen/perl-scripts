#!/usr/bin/perl

# Three sublinear algorithms for computing the sum of prime powers <= n,
# based on the sublinear algorithm for computing the sum of primes <= n.

# See also:
#   https://oeis.org/A074793

use 5.036;
use Math::GMPz;
use ntheory                qw(:all);
use Math::Prime::Util::GMP qw(faulhaber_sum);

sub sum_of_primes ($n, $k = 1) {    # Sum_{p prime <= n} p^k

    return sum_primes($n) if ($k == 1);    # optimization

    $n > ~0 and return undef;
    $n <= 1 and return 0;

    my $r = sqrtint($n);
    my @V = map { divint($n, $_) } 1 .. $r;
    push @V, CORE::reverse(1 .. $V[-1] - 1);

    my $t = Math::GMPz::Rmpz_init_set_ui(0);
    my $u = Math::GMPz::Rmpz_init();

    my %S;
    @S{@V} = map { Math::GMPz::Rmpz_init_set_str(faulhaber_sum($_, $k), 10) } @V;

    foreach my $p (2 .. $r) {
        if ($S{$p} > $S{$p - 1}) {
            my $cp = $S{$p - 1};
            my $p2 = $p * $p;
            Math::GMPz::Rmpz_ui_pow_ui($t, $p, $k);
            foreach my $v (@V) {
                last if ($v < $p2);
                Math::GMPz::Rmpz_sub($u, $S{divint($v, $p)}, $cp);
                Math::GMPz::Rmpz_submul($S{$v}, $u, $t);
            }
        }
    }

    $S{$n} - 1;
}

sub sum_of_prime_powers ($n) {

    # a(n) = Sum_{p prime <= n} p
    # b(n) = Sum_{p prime <= n^(1/2)} p^2
    # c(n) = Sum_{p prime <= n^(1/3)} f(p)

    # sum_of_prime_powers(n) = a(n) + b(n) + c(n)

    my $ps1 = sum_of_primes($n);
    my $ps2 = sum_of_primes(sqrtint($n), 2);

    # f(p) = (Sum_{k=1..floor(log_p(n))} p^k) - p^2 - p
    #      = (p^(1+floor(log_p(n))) - 1)/(p-1) - p^2 - p - 1

    my $ps3 = 0;
    foreach my $p (@{primes(rootint($n, 3))}) {
        $ps3 += divint(powint($p, logint($n, $p) + 1) - 1, $p - 1) - $p * $p - $p - 1;
    }

    return vecsum($ps1, $ps2, $ps3);
}

sub sum_of_prime_powers_2 ($n) {

    # a(n) = Sum_{p prime <= n} p
    # b(n) = Sum_{p prime <= n^(1/2)} f(p)

    # sum_of_prime_powers(n) = a(n) + b(n)

    my $ps1 = sum_of_primes($n);

    # f(p) = (Sum_{k=1..floor(log_p(n))} p^k) - p
    #      = (p^(1+floor(log_p(n))) - 1)/(p-1) - p - 1

    my $ps2 = 0;
    forprimes {
        $ps2 += divint(powint($_, logint($n, $_) + 1) - 1, $_ - 1) - $_ - 1;
    } sqrtint($n);

    return vecsum($ps1, $ps2);
}

sub sum_of_prime_powers_3 ($n) {

    # a(n) = Sum_{k=1..floor(log_2(n))} Sum_{p prime <= n^(1/k)} p^k.
    vecsum(map { sum_of_primes(rootint($n, $_), $_) } 1 .. logint($n, 2));
}

foreach my $n (0 .. 10) {
    say "a(10^$n) = ", sum_of_prime_powers(powint(10, $n));
}

foreach my $k (1 .. 100) {
    my $n = int(rand(1e3)) + 1;

    my $x = sum_of_prime_powers($n);
    my $y = sum_of_prime_powers_2($n);
    my $z = sum_of_prime_powers_3($n);

    $x == $y or die "error";
    $x == $z or die "error";
}

__END__
a(10^0) = 0
a(10^1) = 38
a(10^2) = 1375
a(10^3) = 82674
a(10^4) = 5850315
a(10^5) = 457028152
a(10^6) = 37610438089
a(10^7) = 3204814813355
a(10^8) = 279250347324393
a(10^9) = 24740607755154524
a(10^10) = 2220853189506845580
a(10^11) = 201467948093608962539
a(10^12) = 18435613572072500152927
