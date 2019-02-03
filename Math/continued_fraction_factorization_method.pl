#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 25 October 2018
# https://github.com/trizen

# Simple implementation of the continued fraction factorization method (CFRAC),
# combined with modular arithmetic (variation of the Brillhart-Morrison algorithm).

# See also:
#   https://en.wikipedia.org/wiki/Continued_fraction_factorization
#   https://trizenx.blogspot.com/2018/10/continued-fraction-factorization-method.html

# Some parts of code inspired by:
#    https://github.com/martani/Quadratic-Sieve

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use Math::GMPz qw();
use List::Util qw(first);
use ntheory qw(is_prime factor_exp forprimes next_prime);
use Math::Prime::Util::GMP qw(is_power vecprod sqrtint rootint gcd urandomb);

use constant {
              USE_B_SMOOTH_METHOD => 0,    # 1 to use primes in factor-base up to B=floor(exp(sqrt(log(n) * log(log(n))) / 2))
             };

sub gaussian_elimination ($rows, $n) {

    my @A   = @$rows;
    my $m   = $#A;
    my $ONE = Math::GMPz::Rmpz_init_set_ui(1);

    my @I = map { $ONE << $_ } 0 .. $m;

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

sub is_smooth_over_prod ($n, $k) {

    state $g = Math::GMPz::Rmpz_init_nobless();
    state $t = Math::GMPz::Rmpz_init_nobless();

    Math::GMPz::Rmpz_set($t, $n);
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

sub cffm ($n, $verbose = 0) {

    local $| = 1;

    # Check for primes and negative numbers
    return ()   if $n <= 1;
    return ($n) if is_prime($n);

    # Check for perfect powers
    if (my $k = is_power($n)) {
        my @factors = __SUB__->(Math::GMPz->new(rootint($n, $k)), $verbose);
        return sort { $a <=> $b } ((@factors) x $k);
    }

    # Check for divisibility by 2
    if (Math::GMPz::Rmpz_even_p($n)) {

        my $v = Math::GMPz::Rmpz_scan1($n, 0);
        my $t = $n >> $v;

        my @factors = (2) x $v;

        if ($t > 1) {
            push @factors, __SUB__->($t, $verbose);
        }

        return @factors;
    }

    my $x = Math::GMPz::Rmpz_init();
    my $y = Math::GMPz::Rmpz_init();
    my $z = Math::GMPz::Rmpz_init_set_ui(1);

    my $w = Math::GMPz::Rmpz_init();
    my $r = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_sqrt($x, $n);
    Math::GMPz::Rmpz_set($y, $x);

    Math::GMPz::Rmpz_add($w, $x, $x);
    Math::GMPz::Rmpz_set($r, $w);

    my $f2 = Math::GMPz::Rmpz_init_set($x);
    my $f1 = Math::GMPz::Rmpz_init_set_ui(1);

    my (@A, @Q);

    my $B  = int(exp(sqrt(log("$n") * log(log("$n"))) / 2));                      # B-smooth limit
    my $nf = int(exp(sqrt(log("$n") * log(log("$n"))))**(sqrt(2) / 4) / 1.25);    # number of primes in factor-base

    my @factor_base;

    if (USE_B_SMOOTH_METHOD) {
        forprimes {
            if ($_ <= 97 or Math::GMPz::Rmpz_kronecker_ui($n, $_) == 1) {
                push @factor_base, $_;
            }
        }
        $B;
    }
    else {
        for (my $p = 2 ; @factor_base < $nf ; $p = next_prime($p)) {
            if ($p <= 97 or Math::GMPz::Rmpz_kronecker_ui($n, $p) == 1) {
                push @factor_base, $p;
            }
        }
    }

    my %factor_index;
    @factor_index{@factor_base} = (0 .. $#factor_base);

    my sub exponents_signature (@factors) {
        my $sig = Math::GMPz::Rmpz_init_set_ui(0);

        foreach my $p (@factors) {
            if ($p->[1] & 1) {
                Math::GMPz::Rmpz_setbit($sig, $factor_index{$p->[0]});
            }
        }

        return $sig;
    }

    my $L  = scalar(@factor_base) + 1;                 # maximum number of matrix-rows
    my $FP = Math::GMPz->new(vecprod(@factor_base));

    if ($verbose) {
        printf("[*] Factoring %s (%s digits)...\n\n", "$n", length("$n"));
        say "*** Step 1/2: Finding smooth relations ***";
        printf("Target: %s relations, with B = %s\n", $L, $factor_base[-1]);
    }

    my $t = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    do {

        # y = r*z - y
        Math::GMPz::Rmpz_mul($t, $r, $z);
        Math::GMPz::Rmpz_sub($y, $t, $y);

        # z = (n - y*y) / z
        Math::GMPz::Rmpz_mul($t, $y, $y);
        Math::GMPz::Rmpz_sub($t, $n, $t);
        Math::GMPz::Rmpz_divexact($z, $t, $z);

        # r = (x + y) / z
        Math::GMPz::Rmpz_add($t, $x, $y);
        Math::GMPz::Rmpz_div($r, $t, $z);

        # f1 = (f1 + r*f2) % n
        Math::GMPz::Rmpz_addmul($f1, $f2, $r);
        Math::GMPz::Rmpz_mod($f1, $f1, $n);

        # swap f1 with f2
        ($f1, $f2) = ($f2, $f1);

        # v = (f1^2) % n
        Math::GMPz::Rmpz_powm_ui($v, $f1, 2, $n);

        # v = n-v if v > w
        if (Math::GMPz::Rmpz_cmp($v, $w) > 0) {
            Math::GMPz::Rmpz_sub($v, $n, $v);
        }

#<<<
        if (Math::GMPz::Rmpz_perfect_square_p($v)) {
            my $g = Math::GMPz->new(gcd($f1 - Math::GMPz->new(sqrtint($v)), $n));

            if ($g > 1 and $g < $n) {
                return sort { $a <=> $b } (
                    __SUB__->($g, $verbose),
                    __SUB__->($n / $g, $verbose)
                );
            }
        }
#>>>

        if (is_smooth_over_prod($v, $FP)) {
            my @factors = factor_exp($v);

            if (@factors) {
                push @A, exponents_signature(@factors);
                push @Q, [map { Math::GMPz::Rmpz_init_set($_) } ($f1, $v)];
            }

            if ($verbose) {
                printf("Progress: %d/%d relations.\r", scalar(@A), $L);
            }
        }

    } while (Math::GMPz::Rmpz_cmp_ui($z, 1) and @A < $L);

    if ($verbose) {
        say "\n\n*** Step 2/2: Linear Algebra ***";
        say "Performing Gaussian elimination...";
    }

    if (@A < $L) {
        push @A, map { Math::GMPz::Rmpz_init_set_ui(0) } 1 .. ($L - @A + 1);
    }

    my ($A, $I) = gaussian_elimination(\@A, $L - 1);

    my $LR = ((first { $A->[-$_] } 1 .. @$A) // 0) - 1;

    if ($verbose) {
        say "Found $LR linear dependencies...";
        say "Finding factors from congruences of squares...\n";
    }

    my @factors;
    my $rem = $n;

  SOLUTIONS: foreach my $solution (@{$I}[@$I - $LR .. $#$I]) {

        my $X = 1;
        my $Y = 1;

        foreach my $i (0 .. $#Q) {

            Math::GMPz::Rmpz_tstbit($solution, $i) || next;

            ($X *= $Q[$i][0]) %= $n;
            ($Y *= $Q[$i][1]);

            my $g = Math::GMPz->new(gcd($X - Math::GMPz->new(sqrtint($Y)), $rem));

            if ($g > 1 and $g < $rem) {
                if ($verbose) {
                    say "`-> found factor: $g";
                }
                $rem = check_factor($rem, $g, \@factors);
                last SOLUTIONS if $rem == 1;
            }
        }
    }

    say '' if $verbose;

    my @final_factors;

    foreach my $f (@factors) {
        if (is_prime($f)) {
            push @final_factors, $f;
        }
        else {
            push @final_factors, __SUB__->($f, $verbose);
        }
    }

    if ($rem != 1) {
        if ($rem != $n) {
            push @final_factors, __SUB__->($rem, $verbose);
        }
        else {
            push @final_factors, $rem;
        }
    }

    return sort { $a <=> $b } @final_factors;
}

my @composites = (
    @ARGV ? (map { Math::GMPz->new($_) } @ARGV) : do {
        map { Math::GMPz->new(urandomb($_)) + 2 } 2 .. 70;
    }
);

# Run some tests when no argument is provided
foreach my $n (@composites) {

    my @f = cffm($n, @ARGV ? 1 : 0);

    say "$n = ", join(' * ', map { is_prime($_) ? $_ : "$_ (composite)" } @f);
    die 'error' if Math::GMPz->new(vecprod(@f)) != $n;
}
