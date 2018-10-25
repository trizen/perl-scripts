#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Edit: 25 October 2018
# https://github.com/trizen

# A simple implementation of the continued fraction factorization method,
# combined with modular arithmetic (variation of the Brillhart-Morrison algorithm).

# See also:
#   https://en.wikipedia.org/wiki/Continued_fraction_factorization

# Some parts of code inspired by:
#    https://github.com/martani/Quadratic-Sieve

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Math::GMPz qw();
use List::Util qw(first);
use ntheory qw(is_prime factor_exp forprimes);

use Math::Prime::Util::GMP qw(
    is_square is_power vecprod
    sqrtint rootint gcd urandomb
  );

use constant {
    ONE => Math::GMPz::Rmpz_init_set_ui(1),
};

sub gaussian_elimination ($rows, $n) {

    my @A = @$rows;
    my $m = $#A;
    my @I = map { ONE << $_ } 0 .. $m;

    my $nrow = -1;
    my $mcol = $m < $n ? $m : $n;

    foreach my $col (0 .. $mcol) {
        my $npivot = -1;

        foreach my $row ($nrow + 1 .. $m) {
            if (Math::GMPz::Rmpz_tstbit($A[$row], $col)) {
                $npivot = $row;
                $nrow++;
                last;
            }
        }

        next if ($npivot == -1);

        if ($npivot != $nrow) {
            @A[$npivot, $nrow] = @A[$nrow, $npivot];
            @I[$npivot, $nrow] = @I[$nrow, $npivot];
        }

        foreach my $row ($nrow + 1 .. $m) {
            if (Math::GMPz::Rmpz_tstbit($A[$row], $col)) {
                $A[$row] ^= $A[$nrow];
                $I[$row] ^= $I[$nrow];
            }
        }
    }

    return (\@A, \@I);
}

sub exponents_signature ($factor_lookup, @factors) {
    my $sig = Math::GMPz::Rmpz_init_set_ui(0);

    foreach my $p (@factors) {
        if ($p->[1] & 1) {
            Math::GMPz::Rmpz_setbit($sig, $factor_lookup->{$p->[0]});
        }
    }

    return $sig;
}

sub is_smooth_over_prod ($n, $k) {

    my $g = Math::GMPz::Rmpz_init();
    my $t = Math::GMPz::Rmpz_init_set($n);

    Math::GMPz::Rmpz_gcd($g, $t, $k);

    while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
        Math::GMPz::Rmpz_remove($t, $t, $g);
        return 1 if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
        Math::GMPz::Rmpz_gcd($g, $t, $k);
    }

    return 0;
}

sub check_factor ($n, $g, $factors) {

    while ($n % $g == 0) {

        $n /= $g;
        push @$factors, $g;

        if (is_prime($n)) {
            push @$factors, $n;
            return 1;
        }
    }

    return $n;
}

sub cffm ($n) {

    # Check for primes and negative numbers
    return ()   if $n <= 1;
    return ($n) if is_prime($n);

    # Check for perfect powers
    if (my $k = is_power($n)) {
        my @factors = __SUB__->(Math::GMPz->new(rootint($n, $k)));
        return sort { $a <=> $b } ((@factors) x $k);
    }

    # Check for divisibility by 2
    if (Math::GMPz::Rmpz_even_p($n)) {

        my $v = Math::GMPz::Rmpz_scan1($n, 0);
        my $t = $n >> $v;

        my @factors = (2) x $v;

        if ($t > 1) {
            push @factors, __SUB__->($t);
        }

        return @factors;
    }

    my $x = Math::GMPz->new(sqrtint($n));
    my $y = $x;
    my $z = 1;

    my $w = $x + $x;
    my $r = $w;

    my ($e1, $e2) = (1, 0);
    my ($f1, $f2) = (0, 1);

    my (@A, @Q);

    my $B = 2 * int(exp(sqrt(log("$n") * log(log("$n"))) / 2));    # B-smooth limit

    my @factor_base;

#<<<
    forprimes {
        if (Math::GMPz::Rmpz_ui_kronecker($_, $n) == 1) {
            push @factor_base, $_;
        }
    } $B;
#>>>

    my $factor_prod = Math::GMPz->new(vecprod(@factor_base));

    my %factor_lookup;
    @factor_lookup{@factor_base} = (0 .. $#factor_base);

    my $L = scalar(@factor_base) + 1;    # maximum number of matrix-rows

    do {

        $y = $r * $z - $y;
        $z = ($n - $y * $y) / $z;
        $r = ($x + $y) / $z;

        my $u = ($x * $f2 + $e2) % $n;
        my $v = ($u * $u) % $n;
        my $c = ($v > $w ? $n - $v : $v);

#<<<
        if (is_square($c)) {
            my $g = Math::GMPz->new(gcd($u - Math::GMPz->new(sqrtint($c)), $n));

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g),
                    __SUB__->($n / $g)
                );
            }
        }
#>>>

        if (is_smooth_over_prod($c, $factor_prod)) {
            my @factors = factor_exp($c);

            if (@factors) {
                push @A, exponents_signature(\%factor_lookup, @factors);
                push @Q, [$u, $c];
            }
        }

        ($f1, $f2) = ($f2, ($r * $f2 + $f1) % $n);
        ($e1, $e2) = ($e2, ($r * $e2 + $e1) % $n);

    } while ($z > 1 and @A <= $L);

    if (@A < $L) {
        push @A, map { Math::GMPz::Rmpz_init_set_ui(0) } 1 .. ($L - @A + 1);
    }

    my ($A, $I) = gaussian_elimination(\@A, $L - 1);

    my $LR = ((first { $A->[-$_] } 1 .. @$A) // 0) - 1;

    my @factors;
    my $rem = $n;

  SOLUTIONS: foreach my $solution (@{$I}[@$I - $LR .. $#$I]) {

        my $solution_A = 1;
        my $solution_B = 1;
        my $solution_X = 1;
        my $solution_Y = 1;

        foreach my $i (0 .. $#Q) {

            Math::GMPz::Rmpz_tstbit($solution, $i) || next;

            ($solution_A *= $Q[$i][0]) %= $n;
            ($solution_B *= $Q[$i][0]);

            ($solution_X *= $Q[$i][1]) %= $n;
            ($solution_Y *= $Q[$i][1]);

            foreach my $pair (
                [$solution_A, $solution_X],
                [$solution_A, $solution_Y],
                [$solution_B, $solution_X],
                [$solution_B, $solution_Y],
            ) {
                my ($X, $Y) = @$pair;
                my $g = Math::GMPz->new(gcd($X - Math::GMPz->new(sqrtint($Y)), $rem));

                if ($g > 1 and $g < $rem) {
                    $rem = check_factor($rem, $g, \@factors);
                    last SOLUTIONS if $rem == 1;
                }
            }
        }
    }

    my @final_factors;

    foreach my $f (@factors) {
        if (is_prime($f)) {
            push @final_factors, $f;
        }
        else {
            push @final_factors, __SUB__->($f);
        }
    }

    if ($rem != 1) {
        if ($rem != $n) {
            push @final_factors, __SUB__->($rem);
        }
        else {
            push @final_factors, $rem;
        }
    }

    return sort { $a <=> $b } @final_factors;
}

my @composites = (
    @ARGV ? (map { Math::GMPz->new($_) } @ARGV) : do {
        map { Math::GMPz->new(urandomb($_)) + 2 } 2 .. 60;
      }
);

# Run some tests when no argument is provided
foreach my $n (@composites) {

    my @f = cffm($n);

    say "$n = ", join(' * ', map { is_prime($_) ? $_ : "$_ (composite)" } @f);
    die 'error' if Math::GMPz->new(vecprod(@f)) != $n;
}
