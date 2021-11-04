#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 26 February 2019
# https://github.com/trizen

# Find several integer solutions for x to the congruence:
#   x^2 = a (mod n)

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use experimental qw(signatures);
use ntheory qw();
use Math::Prime::Util::GMP qw();

sub modular_square_root ($x, $y) {

    $x = Math::GMPz->new("$x");
    $y = Math::GMPz->new("$y");

    Math::GMPz::Rmpz_sgn($y) <= 0 and return;

    if (Math::Prime::Util::GMP::is_prob_prime($y)) {
        my $r = Math::GMPz->new(Math::Prime::Util::GMP::sqrtmod($x, $y) // return);
        return ($r, $y - $r);
    }

    my %factors;
    ++$factors{$_} for Math::Prime::Util::GMP::factor($y);

    my %congruences;

    my $t = Math::GMPz::Rmpz_init();
    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();
    my $w = Math::GMPz::Rmpz_init();
    my $m = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_mod($m, $x, $y);

    foreach my $p (keys %factors) {

        if ($p eq '2') {
            my $e = $factors{$p};

            if ($e == 1) {
                push @{$congruences{$p}}, [(Math::GMPz::Rmpz_odd_p($m) ? 1 : 0), 2];
                next;
            }

            if ($e == 2) {
                push @{$congruences{$p}}, [(Math::GMPz::Rmpz_congruent_ui_p($m, 1, 4) ? 1 : 0), 4];
                next;
            }

            Math::GMPz::Rmpz_congruent_ui_p($m, 1, 8) or return;
            Math::GMPz::Rmpz_ui_pow_ui($v, 2, $e - 1);

            foreach my $r (__SUB__->($m, $v)) {

                Math::GMPz::Rmpz_mul($t, $r, $r);
                Math::GMPz::Rmpz_sub($t, $t, $m);
                Math::GMPz::Rmpz_div_2exp($t, $t, $e - 1);
                Math::GMPz::Rmpz_mod_ui($t, $t, 2);

                Math::GMPz::Rmpz_mul_2exp($t, $t, $e - 2);
                Math::GMPz::Rmpz_add($t, $t, $r);

                push @{$congruences{$p}}, ["$t", "$v"];
            }
            next;
        }

        my $r = Math::GMPz->new(Math::Prime::Util::GMP::sqrtmod($x, $p) // return);

        foreach my $w (Math::GMPz->new("$r"), $p - $r) {

            Math::GMPz::Rmpz_set_str($t, "$p", 10);

            # v = p^k
            Math::GMPz::Rmpz_pow_ui($v, $t, $factors{"$p"});

            # t = p^(k-1)
            Math::GMPz::Rmpz_divexact($t, $v, $t);

            # u = (p^k - 2*(p^(k-1)) + 1) / 2
            Math::GMPz::Rmpz_mul_2exp($u, $t, 1);
            Math::GMPz::Rmpz_sub($u, $v, $u);
            Math::GMPz::Rmpz_add_ui($u, $u, 1);
            Math::GMPz::Rmpz_div_2exp($u, $u, 1);

            # sqrtmod(a, p^k) = (powmod(sqrtmod(a, p), p^(k-1), p^k) * powmod(a, u, p^k)) % p^k
            Math::GMPz::Rmpz_powm($w, $w, $t, $v);
            Math::GMPz::Rmpz_powm($u, $m, $u, $v);
            Math::GMPz::Rmpz_mul($w, $w, $u);
            Math::GMPz::Rmpz_mod($w, $w, $v);

            push @{$congruences{$p}}, ["$w", "$v"];
        }
    }

    my @roots;

#<<<
    ntheory::forsetproduct {
        push @roots, Math::Prime::Util::GMP::chinese(@_);
    } values %congruences;
#>>>

    @roots = map { Math::GMPz->new($_) } @roots;

    @roots = grep {
        Math::GMPz::Rmpz_powm_ui($u, $_, 2, $y);
        Math::GMPz::Rmpz_cmp($u, $m) == 0;
    } @roots;

    @roots = sort { $a <=> $b } @roots;

    return @roots;
}

say join ' ', modular_square_root(43,  97);         #=> 25 72
say join ' ', modular_square_root(472, 972);        #=> 448 524
say join ' ', modular_square_root(43,  41 * 97);    #=> 557 1042 2935 3420
say join ' ', modular_square_root(1104, 6630);      #=> 642 642 1152 1152 1968 1968 2478 2478 4152 4152 4662 4662 5478 5478 5988 5988

say '';

say join(' ', modular_square_root(993, 2048));    #=> 369 1679 655 1393
say join(' ', modular_square_root(441, 920));     #=> 761 481 209 849 531 251 899 619 301 21 669 389 71 711 439 159
say join(' ', modular_square_root(841, 905));     #=> 391 876 29 514
say join(' ', modular_square_root(289, 992));     #=> 417 513 975 79 913 17 479 575

# No solutions for some inputs (although solutions do exist)
say join(' ', modular_square_root(306,   810));
say join(' ', modular_square_root(2754,  6561));
say join(' ', modular_square_root(17640, 48465));
