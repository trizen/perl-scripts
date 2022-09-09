#!/usr/bin/perl

# Simple implementation of the prime-summation function:
#   Sum_{p prime <= n} p^k, for any fixed k >= 0.

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::GMPz;
use ntheory qw(divint sqrtint);
use Math::Prime::Util::GMP qw(faulhaber_sum);

sub sum_of_primes ($n, $k = 1) {

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

say sum_of_primes(1e8);         #=> 279209790387276
say sum_of_primes(1e8, 2);      #=> 18433608754948081174274
