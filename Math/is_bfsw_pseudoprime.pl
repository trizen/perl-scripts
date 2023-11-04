#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 31 October 2023
# https://github.com/trizen

# A new primality test, using only the Lucas V sequence.

# This test is a simplification of the strengthen BPSW test:
# https://arxiv.org/abs/2006.14425

use 5.036;
use Math::GMPz;

use constant {
              USE_METHOD_A_STAR => 0,    # true to use the A* method in finding (P,Q)
             };

sub check_lucasV ($P, $Q, $m) {

    state $t = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_add_ui($t, $m, 1);

    my $s = Math::GMPz::Rmpz_scan1($t, 0);
    Math::GMPz::Rmpz_div_2exp($t, $t, $s + 1);

    my $V1 = Math::GMPz::Rmpz_init_set_ui(2);
    my $V2 = Math::GMPz::Rmpz_init_set_ui($P);

    my $Q1 = Math::GMPz::Rmpz_init_set_ui(1);
    my $Q2 = Math::GMPz::Rmpz_init_set_ui(1);

    foreach my $bit (split(//, Math::GMPz::Rmpz_get_str($t, 2))) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
        Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

        if ($bit) {
            Math::GMPz::Rmpz_mul_si($Q2, $Q1, $Q);
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);
            Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $m);
            Math::GMPz::Rmpz_submul_ui($V1, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
            Math::GMPz::Rmpz_mod($V1, $V1, $m);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
            Math::GMPz::Rmpz_submul_ui($V2, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
            Math::GMPz::Rmpz_mod($V2, $V2, $m);
        }
    }

    Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
    Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

    Math::GMPz::Rmpz_mul_si($Q2, $Q1, $Q);
    Math::GMPz::Rmpz_mul($V1, $V1, $V2);
    Math::GMPz::Rmpz_submul_ui($V1, $Q1, $P);
    Math::GMPz::Rmpz_mul($Q2, $Q2, $Q1);

    for (1 .. $s) {
        Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
        Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
        Math::GMPz::Rmpz_powm_ui($Q2, $Q2, 2, $m);
    }

    Math::GMPz::Rmpz_mod($V1, $V1, $m);

    Math::GMPz::Rmpz_set_si($t, 2 * $Q);
    Math::GMPz::Rmpz_congruent_p($V1, $t, $m) || return 0;

    Math::GMPz::Rmpz_set_si($t, $Q * $Q);
    Math::GMPz::Rmpz_congruent_p($Q2, $t, $m) || return 0;

    return 1;
}

sub findQ ($n) {
    for (my $k = 2 ; ; ++$k) {
        my $D = (-1)**$k * (2 * $k + 1);

        my $K = Math::GMPz::Rmpz_si_kronecker($D, $n);

        if ($K == -1) {
            return ((1 - $D) / 4);
        }
        elsif ($K == 0 and abs($D) < $n) {
            return undef;
        }
        elsif ($k == 20 and Math::GMPz::Rmpz_perfect_square_p($n)) {
            return undef;
        }
    }
}

sub findP ($n, $Q) {
    for (my $P = 2 ; ; ++$P) {
        my $D = $P * $P - 4 * $Q;

        my $K = Math::GMPz::Rmpz_si_kronecker($D, $n);

        if ($K == -1) {
            return $P;
        }
        elsif ($K == 0 and abs($D) < $n) {
            return undef;
        }
        elsif ($P == 20 and Math::GMPz::Rmpz_perfect_square_p($n)) {
            return undef;
        }
    }
}

sub is_bfsw_psp ($n) {

    $n = Math::GMPz::Rmpz_init_set_str($n, 10) if ref($n) ne 'Math::GMPz';

    return 0 if Math::GMPz::Rmpz_cmp_ui($n, 1) <= 0;
    return 1 if Math::GMPz::Rmpz_cmp_ui($n, 2) == 0;
    return 0 if Math::GMPz::Rmpz_even_p($n);

    my ($P, $Q);

    if (USE_METHOD_A_STAR) {
        $P = 1;
        $Q = findQ($n) // return 0;

        if ($Q == -1) {
            $P = 5;
            $Q = 5;
        }
    }
    else {
        $Q = -2;
        $P = findP($n, $Q) // return 0;
    }

    check_lucasV($P, $Q, $n);
}

my @strong_lucas_psp = (
                        5459,   5777,   10877,  16109,  18971,  22499,  24569,  25199,  40309,  58519,  75077,  97439,
                        100127, 113573, 115639, 130139, 155819, 158399, 161027, 162133, 176399, 176471, 189419, 192509,
                        197801, 224369, 230691, 231703, 243629, 253259, 268349, 288919, 313499, 324899
                       );
my @extra_strong_lucas_psp = (
                              989,    3239,   5777,   10877,  27971,  29681,  30739,  31631,  39059,  72389,  73919,  75077,
                              100127, 113573, 125249, 137549, 137801, 153931, 155819, 161027, 162133, 189419, 218321, 231703,
                              249331, 370229, 429479, 430127, 459191, 473891, 480689, 600059, 621781, 632249, 635627
                             );

foreach my $n (913, 150267335403, 430558874533, 14760229232131, 936916995253453, @strong_lucas_psp, @extra_strong_lucas_psp) {
    if (is_bfsw_psp($n)) {
        say "Counter-example: $n";
    }
}

use ntheory qw(is_prime);

my $from  = 1;
my $to    = 1e5;
my $count = 0;

foreach my $n ($from .. $to) {
    if (is_bfsw_psp($n)) {
        if (not is_prime($n)) {
            say "Counter-example: $n";
        }
        ++$count;
    }
    elsif (is_prime($n)) {
        say "Missed a prime: $n";
    }
}

say "There are $count primes between $from and $to.";

is_bfsw_psp(3 * Math::GMPz->new("2")**5134 - 1) or die "error";
is_bfsw_psp(Math::GMPz->new(10)**2000 + 4561)   or die "error";

__END__
Inspired by the paper "Strengthening the Baillie-PSW primality test", I propose a simplified test based on Lucas V-pseudoprimes, that requires computing only the Lucas V sequence, making it faster than the full BPSW test, while being about as strong.

The first observation was that none of the 5 vpsp terms < 10^15 satisfy:

Q^(n+1) == Q^2 (mod n)

This gives us a simple test:

V_{n+1}(P,Q) == 2*Q (mod n)
Q^(n+1) == Q^2 (mod n)

where (P,Q) are selected using Method A*.
