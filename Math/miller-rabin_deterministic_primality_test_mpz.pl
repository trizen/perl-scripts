#!/usr/bin/perl

# Miller-Rabin deterministic primality test.

# Theorem (Miller, 1976):
#   If the Generalized Riemann hypothesis is true, then there is a constant C such that
#   primality of `n` is the same as every a <= C*(log(n))^2 being a Miller-Rabin witness for `n`.

# Bach (1984) showed that we can use C = 2.

# Assuming the GRH, this primality test runs in polynomial time.

# See also:
#   https://rosettacode.org/wiki/Miller%E2%80%93Rabin_primality_test#Perl

use 5.010;
use strict;
use warnings;

use ntheory qw(valuation powmod);

use Math::GMPz;
use Math::MPFR;

sub is_provable_prime {
    my ($n) = @_;

    return 1 if $n == 2;
    return 0 if $n < 2 or $n % 2 == 0;

    return 1 if $n == 5;
    return 1 if $n == 7;
    return 1 if $n == 11;
    return 1 if $n == 13;

    my $d = $n - 1;
    my $s = valuation($d, 2);

    $d >>= $s;

    my $bound = ref($n) eq 'Math::GMPz' ? do {
        my $r = Math::MPFR::Rmpfr_init2(64);
        Math::MPFR::Rmpfr_set_z($r, $n, 0);
        Math::MPFR::Rmpfr_log($r, $r, 0);
        2 * Math::MPFR::Rmpfr_get_d($r, 0)**2;
    } : 2 * log($n)**2;

  LOOP: for my $k (1 .. $bound) {

        my $x = powmod($k, $d, $n);

        if (ref($x) or $x >= (~0 >> 1)) {
            $x = Math::GMPz->new("$x");
        }

        next if $x == 1 or $x == $n - 1;

        for (1 .. $s - 1) {
            $x = ($x * $x) % $n;
            return 0  if $x == 1;
            next LOOP if $x == $n - 1;
        }
        return 0;
    }
    return 1;
}

# Primes
say is_provable_prime(Math::GMPz->new(2)**89 - 1)  ? 'prime' : 'error';
say is_provable_prime(Math::GMPz->new(2)**107 - 1) ? 'prime' : 'error';
say is_provable_prime(Math::GMPz->new(2)**127 - 1) ? 'prime' : 'error';
say is_provable_prime(Math::GMPz->new('115547929908077082437116944109458314609946651910092587495187962466088019331251')) ? 'prime' : 'error';

# Composites
say is_provable_prime(Math::GMPz->new('142899381901'))                                       ? 'error' : 'composite';
say is_provable_prime(Math::GMPz->new('92737632541325090700295531'))                         ? 'error' : 'composite';
say is_provable_prime(Math::GMPz->new('200000000135062271492802271468294969951'))            ? 'error' : 'composite';
say is_provable_prime(Math::GMPz->new('48793204382746801501446610630739608190006929723969')) ? 'error' : 'composite';
say is_provable_prime(Math::GMPz->new('25195908475657893494027183240048398571429282126204032027777137836043662020707595556264018525880784406918290641249515082189298559149176184502808489120072844992687392807287776735971418347270261896375014971824691165077613379859095700097330459748808428401797429100642458691817195118746121515172654632282216869987549182422433637259085141865462043576798423387184774447920739934236584823824281198163815010674810451660377306056201619676256133844143603833904414952634432190114657544454178424020924616515723350778707749817125772467962926386356373289912154831438167899885040445364023527381951378636564391212010397122822120720357')) ? 'error' : 'composite';
