#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 26 May 2017
# Edit: 04 November 2023
# https://github.com/trizen

# Computation of the nth-harmonic number, using the digamma(x) function.

# See also:
#   https://en.wikipedia.org/wiki/Harmonic_number

use 5.010;
use strict;
use warnings;

use Math::GMPz             qw();
use Math::GMPq             qw();
use Math::MPFR             qw();
use Math::AnyNum           qw();
use Math::Prime::Util::GMP qw();

sub harmonic {
    my ($n) = @_;

    $n == 0 and return Math::AnyNum->zero;
    $n == 1 and return Math::AnyNum->one;

    state $tau   = 6.28318530717958647692528676655900576839433879875;
    state $gamma = 0.57721566490153286060651209008240243104215933594;

    #my $log2_Hn = (-$n + $n * log($n) + (log($tau) + log($n)) / 2 + log(log($n) + $gamma)) / log(2);
    my $log2_Hn = $n / log(2) + sqrt($n);

    my $prec  = int($log2_Hn + 3);
    my $round = Math::MPFR::MPFR_RNDN();

    my $r = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_set_ui($r, $n + 1, $round);
    Math::MPFR::Rmpfr_digamma($r, $r, $round);

    my $t = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_const_euler($t, $round);
    Math::MPFR::Rmpfr_add($r, $r, $t, $round);

    my $num = Math::GMPz::Rmpz_init();
    my $den = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_set_str($den, Math::Prime::Util::GMP::consecutive_integer_lcm($n), 10);
    Math::MPFR::Rmpfr_mul_z($r, $r, $den, $round);
    Math::MPFR::Rmpfr_round($r, $r);
    Math::MPFR::Rmpfr_get_z($num, $r, $round);

    my $q = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_num($q, $num);
    Math::GMPq::Rmpq_set_den($q, $den);
    Math::GMPq::Rmpq_canonicalize($q);
    Math::AnyNum->new($q);
}

foreach my $i (0 .. 30) {
    printf "%20s / %-20s\n", harmonic($i)->nude;
    harmonic($i) == Math::AnyNum::harmonic($i) or die "error";
}

foreach my $i (2863, 7000) {
    harmonic($i) == Math::AnyNum::harmonic($i) or die "error";
}

__END__
# Extra testing
foreach my $k (1 .. 20) {
    my $i = int(rand($k * 1e3));
    say "Testing: $i";
    harmonic($i) == Math::AnyNum::harmonic($i) or die "error";
}
